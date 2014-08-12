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

    func toggleBookmark(bookmark: Bookmark!) -> Bool {
        // do we have this bookmark?

        var newBookmarks = [Bookmark]()
        var isFavorite = true
        for b in bookmarks {
            if b == bookmark { // not identity. should call isEqual:
                isFavorite = false
                DMDEBUG("Deleting bookmark \(b.url)")
            }
            else {
                newBookmarks.append(b)
            }
        }

        if isFavorite {
            bookmark.manager = self
            if !bookmark.model.complete {
                bookmark.model.load()
            }
            newBookmarks.append(bookmark)
            DMDEBUG("Added new bookmark \(bookmark.url)")
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

    func bookmarkLoaded(bookmark: Bookmark!) {
        let word = bookmark.model as DubsarModelsWord
        DMDEBUG("Word for URL \(bookmark.url) is \(word.nameAndPos)")

        let viewController = AppDelegate.instance.navigationController.topViewController as BaseViewController
        viewController.adjustLayout()
    }

    let userDefaultKey = "DubsarBookmarks"
    func saveBookmarks() {
        /*
         * Serialize as a space-delimited list of URL strings. Spaces are not legal in URLS, and anyway
         * Dubsar doesn't use them.
         */
        var string = ""

        for bookmark in bookmarks {
            if !string.isEmpty {
                string = "\(string) "
            }
            string = "\(string)\(bookmark.url)"
        }

        NSUserDefaults.standardUserDefaults().setValue(string, forKey: userDefaultKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func loadBookmarks() {
        bookmarks = []

        NSUserDefaults.standardUserDefaults().synchronize()
        let string = NSUserDefaults.standardUserDefaults().valueForKey(userDefaultKey) as? NSString

        if !string {
            return
        }

        let components = string!.componentsSeparatedByString(" ") as [AnyObject]
        for component in components as [String] {
            let url = NSURL(string: component)
            let bookmark = Bookmark(url: url)
            bookmark.manager = self
            bookmark.model.load()

            bookmarks.append(bookmark)
        }

    }
}
