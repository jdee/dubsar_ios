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
            if !bookmark.model.complete {
                bookmark.model.load()
            }
            newBookmarks.append(bookmark)
            DMDEBUG("Added new bookmark \(bookmark.url)")
        }

        bookmarks = newBookmarks

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
    }

}
