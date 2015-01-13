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

class BookmarkListView: UIView {

    class var margin : CGFloat {
        get {
            return 4
    }
    }

    override var frame: CGRect {
        didSet {
            layer.shadowPath = UIBezierPath(rect: bounds).CGPath
        }
    }

    let scroller: UIScrollView
    let backgroundView: UIView
    let label: UILabel
    var bookmarkViews = [BookmarkView]()

    override init(frame: CGRect) {
        let margin = BookmarkListView.margin

        scroller = UIScrollView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        scroller.autoresizingMask = .FlexibleHeight | .FlexibleWidth

        backgroundView = UIView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        backgroundView.autoresizingMask = .FlexibleWidth

        label = UILabel(frame: CGRectMake(margin, margin, frame.size.width - 2 * margin, frame.size.height))
        label.autoresizingMask = .FlexibleWidth
        label.numberOfLines = 1
        label.textAlignment = .Center

        super.init(frame: frame)

        layer.shadowOffset = CGSizeMake(0, 3)
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 3
        layer.shadowPath = UIBezierPath(rect: bounds).CGPath
        clipsToBounds = false

        scroller.bounces = false
        scroller.showsHorizontalScrollIndicator = false
        scroller.showsVerticalScrollIndicator = true
        addSubview(scroller)

        scroller.addSubview(backgroundView)
        backgroundView.addSubview(label)
    }

    required init(coder aDecoder: NSCoder) {
        scroller = UIScrollView()
        backgroundView = UIView()
        label = UILabel()
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        for bookmarkView in bookmarkViews {
            bookmarkView.removeFromSuperview()
        }
        bookmarkViews = []

        backgroundView.backgroundColor = AppConfiguration.alternateBackgroundColor

        let bookmarks = AppDelegate.instance.bookmarkManager.bookmarks

        if bookmarks.isEmpty {
            label.text = "No bookmarks"
        }
        else {
            label.text = "Bookmarks"
        }

        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let textSize = (label.text as NSString?)!.sizeWithAttributes([NSFontAttributeName: font])
        let margin = BookmarkListView.margin

        label.font = font
        label.frame = CGRectMake(margin, margin, bounds.size.width - 2 * margin, textSize.height)
        label.backgroundColor = AppConfiguration.highlightColor
        label.textColor = AppConfiguration.foregroundColor

        DMTRACE("Bookmarks label size \(label.bounds.size.width) x \(label.bounds.size.height) (\(font.pointSize) pt). origin: (\(label.frame.origin.x), \(label.frame.origin.y))")

        var y = margin + label.frame.origin.y + label.bounds.size.height

        DMTRACE("Laying out bookmark list view with \(bookmarks.count) bookmarks, starting at \(y) (frame.origin.y = \(frame.origin.y))")

        for bookmark in bookmarks {
            let bookmarkView = BookmarkView(frame: CGRectMake(margin, y, self.bounds.size.width - 2 * margin, self.bounds.size.height), bookmark: bookmark)
            bookmarkView.listView = self
            backgroundView.addSubview(bookmarkView)
            bookmarkViews.append(bookmarkView)

            y += bookmarkView.bounds.size.height + margin
            DMTRACE("y is now \(y)")
        }

        backgroundView.frame = CGRectMake(0, 0, bounds.size.width, y)

        // add room for the shadow, since we have to set clipsToBounds to true
        y += layer.shadowOffset.height + layer.shadowRadius

        scroller.contentSize = CGSizeMake(frame.size.width, y)

        if frame.size.height > y {
            frame.size.height = y
        }

        super.layoutSubviews()
    }

    func bookmarkSelected(bookmark: Bookmark!) {
        AppDelegate.instance.application(UIApplication.sharedApplication(), openURL: bookmark.url, sourceApplication: nil, annotation: nil)
    }
}
