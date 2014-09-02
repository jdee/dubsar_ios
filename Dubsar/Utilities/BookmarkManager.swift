/*
Dubsar Dictionary Project
Copyright (C) 2010-14 Jimmy Dee

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

import UIKit

class BookmarkManager: NSObject {

    var bookmarks = [Bookmark]()
    let aesKey = AESKey(identifier: "\(NSBundle.mainBundle().bundleIdentifier).bookmarks")

    func toggleBookmark(bookmark: Bookmark!) -> Bool {
        // do we have this bookmark?

        var newBookmarks = [Bookmark]()
        var isFavorite = true
        for b in bookmarks {
            if b == bookmark { // not identity. should call isEqual:
                isFavorite = false
                DMDEBUG("Deleting bookmark \(b.url): \(b.label)")
            }
            else {
                newBookmarks.append(b)
            }
        }

        if isFavorite {
            newBookmarks.append(bookmark)
            DMDEBUG("Added new bookmark \(bookmark.url): \(bookmark.label)")
        }

        bookmarks = newBookmarks

        saveBookmarks()

        return isFavorite
    }

    func isUrlBookmarked(url: NSURL!) -> Bool {
        for b in bookmarks {
            if b.url == url {
                return true
            }
        }
        return false
    }

    let bookmarksKey = "DubsarBookmarks"
    let labelsKey = "DubsarLabels"
    func saveBookmarks() {
        /*
         * Serialize as a space-delimited list of URL strings. Spaces are not legal in URLS, and anyway
         * Dubsar doesn't use them.
         */
        var urlString = ""
        var labelString = ""

        for bookmark in bookmarks {
            if !urlString.isEmpty {
                urlString = "\(urlString) "
            }
            if !labelString.isEmpty {
                labelString = "\(labelString)\u{1f}" // good old US character
            }
            urlString = "\(urlString)\(bookmark.url)"
            labelString = "\(labelString)\(bookmark.label)"
        }

        DMTRACE("URL string: \"\(urlString)\"")
        DMTRACE("label string: \"\(labelString)\"")

        if AppConfiguration.secureBookmarksSetting {
            /*
             * Rekey every time we write. This is also called for consistency in loadBookmarks(). Hence, each value of this
             * key is used for at most one read operation for added security.
             */
            aesKey.rekey()
            let encryptedUrls = aesKey.encrypt(urlString.dataUsingEncoding(NSUTF8StringEncoding))
            let encryptedLabels = aesKey.encrypt(labelString.dataUsingEncoding(NSUTF8StringEncoding))

            NSUserDefaults.standardUserDefaults().setValue(encryptedUrls, forKey: bookmarksKey)
            NSUserDefaults.standardUserDefaults().setValue(encryptedLabels, forKey: labelsKey)
        }
        else {
            /*
             * No real harm in leaving the key, but may as well clean up.
             */
            aesKey.deleteKey()
            NSUserDefaults.standardUserDefaults().setValue(urlString.dataUsingEncoding(NSUTF8StringEncoding), forKey: bookmarksKey)
            NSUserDefaults.standardUserDefaults().setValue(labelString.dataUsingEncoding(NSUTF8StringEncoding), forKey: labelsKey)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func loadBookmarks() {
        bookmarks = []

        var urls: [AnyObject]
        var labels: [AnyObject]

        NSUserDefaults.standardUserDefaults().synchronize()
        var raw = NSUserDefaults.standardUserDefaults().valueForKey(bookmarksKey) as? NSData

        if raw == nil {
            saveBookmarks()
            return
        }

        DMTRACE("Loaded \(raw!.length) bytes from \(bookmarksKey)")

        var data: NSData!
        var secureBookmarksSetting = AppConfiguration.secureBookmarksSetting

        /*
         * The raw value may or may not be encrypted. We try following the setting first. If that fails, try the
         * other option, in case the setting recently changed while we were in the bg.
         *
         * Somehow, during testing, I ended up with something that decrypted (successfully) to junk and made the NSString
         * initializer crash about 35 lines down. I'm not quite sure what happened, so I'm adding some sanity checks.
         * The startsWithLittleD hack is because in Swift I have no clue how to
         * check the numeric value of the first byte of an NSData. A list of dubsar:/// URLS has to start with 'd'. Generally
         * the next 60-70 lines of code take a cue from the secureBookmarksSetting and attempt to decrypt the raw data if
         * appropriate, but regardless of the first attempt, if the data cannot be validated as a list of URLS, the other
         * option will be tried. That is, first encrypted, then unencrypted; or first unencrypted, then encrypted. If a URL
         * list can be determined, the label list is parsed after that, but in whatever way (encrypted or not) the URL list
         * was, without going through the same trial and error.
         *
         * Either way, at the end, saveBookmarks is called, and the stored value is updated according to the current value of
         * AppConfiguration.secureBookmarksSetting. If encrypted, a new key is generated, and the keychain is also updated.
         */

        if secureBookmarksSetting {
            if raw!.startsWithLittleD {
                // assume this is unencrypted. if it fails, it will try again below.
                secureBookmarksSetting = false
                data = raw
                DMTRACE("Raw data starts with d. Trying to parse.")
            }
            else {
                data = aesKey.decrypt(raw)
                if data == nil {
                    // the setting might have changed. if this is successfully parsed as plain text, it will
                    // be encrypted and written back.
                    secureBookmarksSetting = false
                    data = raw
                    DMTRACE("Decryption failed. Trying to parse raw.") // will fail because it doesn't start with 'd'
                }
                else {
                    DMTRACE("Successfully decrypted \(raw!.length) bytes to \(data.length) bytes")
                }
            }
        }
        else {
            DMTRACE("Encryption disabled. Parsing raw data.")
            data = raw
        }

        if !data.startsWithLittleD {
            // can't parse. fail.
            DMWARN("Failed to validate \(bookmarksKey) as a list of dubsar:/// URLS. Discarding bookmarks.")
            saveBookmarks()
            return
        }

        var string = NSString(data: data, encoding: NSUTF8StringEncoding)

        DMTRACE("URL string on load (\(string.length)): \"\(string)\"")
        urls = string.componentsSeparatedByString(" ")

        // Check to see if they're all dubsar:/// URLS.
        if !validateUrls(urls as [String]) {
            var valid = false
            if !secureBookmarksSetting {
                /*
                 * The setting might have changed. This might be encrypted.
                 */
                data = aesKey.decrypt(raw)

                if data.startsWithLittleD {
                    string = NSString(data: data, encoding: NSUTF8StringEncoding)
                    urls = string.componentsSeparatedByString(" ")

                    valid = validateUrls(urls as [String])
                    secureBookmarksSetting = valid
                }
            }

            if !valid {
                DMWARN("Failed to validate \(bookmarksKey) as a list of dubsar:/// URLS. Discarding bookmarks.")
                saveBookmarks()
                return
            }
        }

        /*
         * Now urls is set. Do the same for labels.
         */

        raw = NSUserDefaults.standardUserDefaults().valueForKey(labelsKey) as? NSData

        if raw == nil {
            saveBookmarks()
            return
        }

        // Assume that we straightened this out above and don't need all the second guessing here.
        if secureBookmarksSetting {
            data = aesKey.decrypt(raw)
        }
        else {
            data = raw
        }
        string = NSString(data: data, encoding: NSUTF8StringEncoding)

        DMTRACE("Label string on load (\(string.length)): \"\(string)\"")

        labels = string.componentsSeparatedByString("\u{1f}")

        for (index, url) in enumerate(urls as [String]) {
            if index >= labels.count {
                DMDEBUG("No more labels. Returning with \(bookmarks.count) bookmarks")
                saveBookmarks()
                return
            }

            let label = labels[index] as NSString
            if (label as String).isEmpty || url.isEmpty {
                continue
            }

            let bookmark = Bookmark(url: NSURL(string: url))
            bookmark.label = label

            DMTRACE("Found bookmark \(bookmark.url): \"\(bookmark.label)\" (\((bookmark.label as NSString).length))")

            bookmarks.append(bookmark)
        }
        DMTRACE("Found \(bookmarks.count) bookmarks")

        saveBookmarks()
    }

    private func validateUrls(urls: [String]) -> Bool {
        for url in urls {
            let nsurl = NSURL(string: url)
            if nsurl.scheme == nil || nsurl.scheme! != "dubsar" {
                return false
            }
        }

        return true
    }
}
