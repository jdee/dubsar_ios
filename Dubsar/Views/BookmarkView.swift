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

class BookmarkView: UIView {

    weak var listView: BookmarkListView?

    class var padding: CGFloat {
        get {
            return 4
    }
    }

    var bookmark: Bookmark

    let button: UIButton
    let closeButton: CloseButton

    init(frame: CGRect, bookmark: Bookmark!) {
        self.bookmark = bookmark
        button = UIButton(frame: CGRectMake(0, 0, frame.size.width-frame.size.height, frame.size.height))
        button.autoresizingMask = .FlexibleHeight | .FlexibleWidth

        closeButton = CloseButton(frame: CGRectMake(frame.size.width-frame.size.height, 0, frame.size.height, frame.size.height))
        closeButton.autoresizingMask = .FlexibleLeftMargin

        super.init(frame: frame)
        addSubview(button)
        addSubview(closeButton)

        opaque = false
        backgroundColor = UIColor.clearColor()
        autoresizingMask = .FlexibleWidth

        button.addTarget(self, action: "selected:", forControlEvents: .TouchUpInside)
        closeButton.addTarget(self, action: "deleted:", forControlEvents: .TouchUpInside)

        rebuild()
    }

    required init(coder aDecoder: NSCoder) {
        bookmark = Bookmark()
        button = UIButton()
        closeButton = CloseButton()
        super.init(coder: aDecoder)
    }

    func rebuild() {
        button.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        button.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        closeButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        closeButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)

        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        button.titleLabel!.font = font
        closeButton.titleLabel!.font = font

        let text = bookmark.label

        let textSize = (text as NSString).sizeWithAttributes([NSFontAttributeName: font])

        button.setTitle(text, forState: .Normal)

        frame.size.height = textSize.height + 2 * BookmarkView.padding
        button.frame = CGRectMake(0, 0, bounds.size.width-bounds.size.height, bounds.size.height)
        closeButton.frame = CGRectMake(bounds.size.width-bounds.size.height, 0, bounds.size.height, bounds.size.height)
    }

    @IBAction
    func selected(sender: UIButton!) {
        listView?.bookmarkSelected(bookmark)
    }

    @IBAction
    func deleted(sender: CloseButton!) {
        AppDelegate.instance.bookmarkManager.toggleBookmark(bookmark)
        listView?.setNeedsLayout()
    }
}
