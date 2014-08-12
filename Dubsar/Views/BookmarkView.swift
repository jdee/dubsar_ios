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

class BookmarkView: UIView {

    weak var listView: BookmarkListView?

    class var padding: CGFloat {
        get {
            return 4
    }
    }

    var bookmark: Bookmark

    let button: UIButton

    init(frame: CGRect, bookmark: Bookmark!) {
        self.bookmark = bookmark
        button = UIButton(frame: frame)
        button.autoresizingMask = .FlexibleHeight | .FlexibleWidth

        super.init(frame: frame)
        addSubview(button)

        opaque = false
        backgroundColor = UIColor.clearColor()

        button.addTarget(self, action: "selected:", forControlEvents: .TouchUpInside)

        rebuild()
    }

    func rebuild() {
        button.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        button.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)

        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        button.titleLabel.font = font

        var text: String
        if !bookmark.model.complete {
            text = String(format: "%@", bookmark.url)
        }
        else {
            let word = bookmark.model as DubsarModelsWord
            text = word.nameAndPos
        }

        let textSize = (text as NSString).sizeWithAttributes([NSFontAttributeName: font])

        button.setTitle(text, forState: .Normal)

        frame.size.height = textSize.height + 2 * BookmarkView.padding
        button.frame = bounds
    }

    @IBAction
    func selected(sender: UIButton!) {
        listView?.bookmarkSelected(bookmark)
    }
}
