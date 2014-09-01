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

        let encryptedUrls = aesKey.encrypt(urlString)
        let encryptedLabels = aesKey.encrypt(labelString)

        NSUserDefaults.standardUserDefaults().setValue(encryptedUrls, forKey: bookmarksKey)
        NSUserDefaults.standardUserDefaults().setValue(encryptedLabels, forKey: labelsKey)

        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func loadBookmarks() {

        /*
        NSUserDefaults.standardUserDefaults().removeObjectForKey(bookmarksKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(labelsKey)
        // */
        
        bookmarks = []

        var urls: [AnyObject]
        var labels: [AnyObject]

        NSUserDefaults.standardUserDefaults().synchronize()
        var encrypted = NSUserDefaults.standardUserDefaults().valueForKey(bookmarksKey) as? NSData

        if encrypted == nil {
            return
        }

        var string = aesKey.decrypt(encrypted) as NSString

        DMTRACE("URL string on load (\(string.length)): \"\(string)\"")
        urls = string.componentsSeparatedByString(" ")

        encrypted = NSUserDefaults.standardUserDefaults().valueForKey(labelsKey) as? NSData

        if encrypted == nil {
            return
        }

        string = aesKey.decrypt(encrypted) as NSString

        DMTRACE("Label string on load (\(string.length)): \"\(string)\"")

        labels = string.componentsSeparatedByString("\u{1f}")

        for (index, url) in enumerate(urls as [String]) {
            if index >= labels.count {
                DMDEBUG("No more labels. Returning with \(bookmarks.count) bookmarks")
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
    }
}
