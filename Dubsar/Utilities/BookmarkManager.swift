/*
Dubsar Dictionary Project
Copyright (C) 2010-15 Jimmy Dee

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

    lazy var aesKey = AESKey(identifier: bookmarkKeyIdentifier)

    class var bookmarkKeyIdentifier: String {
        get {
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? "com.dubsar-dictionary.Dubsar"
            return "\(bundleIdentifier).bookmarks"
        }
    }

    func addBookmark(bookmark: Bookmark!) -> Bool {
        if !isUrlBookmarked(bookmark.url) {
            return toggleBookmark(bookmark)
        }
        return true
    }

    func removeBookmark(bookmark: Bookmark!) -> Bool {
        if isUrlBookmarked(bookmark.url) {
            return toggleBookmark(bookmark)
        }
        return true
    }

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
             * key is used for at most one pair of read operations for added security.
             */
            aesKey.rekey()
            let encryptedUrls = aesKey.encrypt(urlString.dataUsingEncoding(NSUTF8StringEncoding))
            let encryptedLabels = aesKey.encrypt(labelString.dataUsingEncoding(NSUTF8StringEncoding))

            let base64Urls = NSString.base64StringFromData(encryptedUrls) as NSString
            let base64Labels = NSString.base64StringFromData(encryptedLabels) as NSString

            DMTRACE("Saving \(base64Urls.length) URL bytes, \(base64Labels.length) label bytes")
            DMTRACE("Base64 URLS: \(base64Urls)")
            DMTRACE("Base64 Labels: \(base64Labels)")

            NSUserDefaults.standardUserDefaults().setValue(base64Urls, forKey: bookmarksKey)
            NSUserDefaults.standardUserDefaults().setValue(base64Labels, forKey: labelsKey)
        }
        else {
            aesKey.deleteKey()
            NSUserDefaults.standardUserDefaults().setValue(urlString, forKey: bookmarksKey)
            NSUserDefaults.standardUserDefaults().setValue(labelString, forKey: labelsKey)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func loadBookmarks() {
        bookmarks = []

        var urls: [AnyObject]
        var labels: [AnyObject]

        NSUserDefaults.standardUserDefaults().synchronize()
        var raw = NSUserDefaults.standardUserDefaults().valueForKey(bookmarksKey) as? NSString

        if raw == nil {
            saveBookmarks()
            return
        }

        DMTRACE("Loaded \(raw!.length) bytes from \(bookmarksKey)")

        var string: NSString!
        var secureBookmarksSetting = AppConfiguration.secureBookmarksSetting

        /*
         * The raw value may or may not be encrypted. We try following the setting first. If that fails, try the
         * other option, in case the setting recently changed while we were in the bg.
         *
         * Either way, at the end, saveBookmarks is called, and the stored value is updated according to the current value of
         * AppConfiguration.secureBookmarksSetting. If encrypted, a new key is generated, and the keychain is also updated.
         */

        if secureBookmarksSetting {
            if raw!.hasPrefix("d") {
                // assume this is unencrypted. if it fails, it will try again below.
                secureBookmarksSetting = false
                string = raw
                DMTRACE("Raw data starts with d. Trying to parse.")
            }
            else {
                DMTRACE("Decrypting base64 URLS: \(raw!)")

                let cipherText = NSData.base64DataFromString(raw as! String)
                let data = aesKey.decrypt(cipherText)
                if data == nil {
                    // the setting might have changed. if this is successfully parsed as plain text, it will
                    // be encrypted and written back.
                    secureBookmarksSetting = false
                    string = raw
                    DMTRACE("Decryption failed. Trying to parse raw.") // will fail because it doesn't start with 'd'
                }
                else {
                    DMTRACE("Successfully decrypted \(raw!.length) bytes to \(data.length) bytes")
                    if data.length > 0 && !data.startsWithLittleD {
                        DMWARN("Cannot parse \(data.length) bytes as URL list. Does not start with 'd'")
                        saveBookmarks()
                        return
                    }

                    string = NSString(data: data, encoding: NSUTF8StringEncoding)
                }
            }
        }
        else {
            DMTRACE("Encryption disabled. Parsing raw data.")
            string = raw
        }

        if string.length == 0 {
            DMTRACE("Bookmarks are empty.")
            saveBookmarks()
            return
        }

        DMTRACE("URL string on load (\(string.length)): \"\(string)\"")
        urls = string.componentsSeparatedByString(" ")

        // Check to see if they're all dubsar:/// URLS.
        if !validateUrls(urls as! [String]) {
            var valid = false
            if !secureBookmarksSetting {
                /*
                 * The setting might have changed. This might be encrypted.
                 */
                let cipherText = NSData.base64DataFromString(raw as! String)
                let data = aesKey.decrypt(cipherText)

                if data != nil {
                    string = NSString(data: data, encoding: NSUTF8StringEncoding)
                    urls = string.componentsSeparatedByString(" ")

                    valid = validateUrls(urls as! [String])
                    secureBookmarksSetting = valid
                }
            }

            if !valid {
                DMWARN("Failed to validate \(bookmarksKey) as a list of dubsar:/// URLS (validation failed). Discarding bookmarks.")
                saveBookmarks()
                return
            }
        }

        /*
         * Now urls is set. Do the same for labels.
         */

        raw = NSUserDefaults.standardUserDefaults().valueForKey(labelsKey) as? NSString

        if raw == nil {
            saveBookmarks()
            return
        }

        // Assume that we straightened this out above and don't need all the second guessing here.
        if secureBookmarksSetting {
            let cipherText = NSData.base64DataFromString(raw as! String)
            let data = aesKey.decrypt(cipherText)
            string = NSString(data: data, encoding: NSUTF8StringEncoding)
        }
        else {
            string = raw
        }

        DMTRACE("Label string on load (\(string.length)): \"\(string)\"")

        labels = string.componentsSeparatedByString("\u{1f}")

        for (index, url) in (urls as! [String]).enumerate() {
            if index >= labels.count {
                DMDEBUG("No more labels. Returning with \(bookmarks.count) bookmarks")
                saveBookmarks()
                return
            }

            let label = labels[index] as! String
            if label.isEmpty || url.isEmpty {
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
            let nsurl = NSURL(string: url)!
            if nsurl.scheme.isEmpty || nsurl.scheme != "dubsar" {
                return false
            }
        }

        return true
    }
}
