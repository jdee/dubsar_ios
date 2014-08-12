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

class BookmarkListView: UIView {

    class var margin : CGFloat {
        get {
            return 4
    }
    }

    var bookmarkViews = [BookmarkView]()

    init(frame: CGRect) {
        super.init(frame: frame)

        layer.shadowOffset = CGSizeMake(0, 3)
        layer.shadowOpacity = 1
        clipsToBounds = false
    }

    override func layoutSubviews() {
        for bookmarkView in bookmarkViews {
            bookmarkView.removeFromSuperview()
        }
        bookmarkViews = []

        backgroundColor = AppConfiguration.alternateBackgroundColor

        let bookmarks = AppDelegate.instance.bookmarkManager.bookmarks
        let margin = BookmarkListView.margin

        var y = margin
        DMTRACE("Laying out bookmark list view with \(bookmarks.count) bookmarks, starting at \(y) (frame.origin.y = \(frame.origin.y))")

        for bookmark in bookmarks {
            let bookmarkView = BookmarkView(frame: CGRectMake(margin, y, self.bounds.size.width - 2 * margin, self.bounds.size.height), bookmark: bookmark)
            bookmarkView.listView = self
            addSubview(bookmarkView)
            bookmarkViews.append(bookmarkView)

            y += bookmarkView.bounds.size.height + margin
            DMDEBUG("y is now \(y)")
        }

        frame.size.height = y

        super.layoutSubviews()
    }

    func bookmarkSelected(bookmark: Bookmark!) {
        AppDelegate.instance.application(UIApplication.sharedApplication(), openURL: bookmark.url, sourceApplication: nil, annotation: nil)
    }
}
