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

import DubsarModels
import UIKit

class AutocompleterView: UIView {
    var autocompleter : DubsarModelsAutocompleter! {
    didSet {
        setNeedsLayout()
    }
    }

    class var margin : CGFloat {
        get {
            return 4
        }
    }

    var buttons : [UIButton] = []

    weak var viewController : MainViewController?

    init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .FlexibleHeight | .FlexibleWidth | .FlexibleBottomMargin
        backgroundColor = UIColor.lightGrayColor()
    }

    override func layoutSubviews() {
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons = []

        if autocompleter {
            assert(autocompleter.complete)

            // NSLog("Laying out AutocompleterView with %d results", autocompleter.results.count)
            let margin = AutocompleterView.margin
            var y : CGFloat = margin
            let results = autocompleter.results as [AnyObject]
            for result in results as [NSString] {
                let font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
                let textSize = result.sizeWithAttributes([NSFontAttributeName: font])
                let button = UIButton(frame: CGRectMake(margin, y, bounds.size.width - 2*margin, textSize.height + 2*margin))
                button.setTitle(result, forState: .Normal)
                button.setTitleColor(UIColor.blackColor(), forState: .Highlighted)
                button.titleLabel.font = font
                button.addTarget(self, action: "resultSelected:", forControlEvents: .TouchUpInside)
                addSubview(button)
                buttons += button

                y += textSize.height + 3*margin
            }

            frame.size.height = y
        }

        super.layoutSubviews()
    }

    @IBAction
    func resultSelected(sender: UIButton!) {
        let result = sender.titleForState(.Normal)
        // NSLog("Button pressed for result %@", result)
        viewController?.autocompleterView(self, selectedResult: result)
    }
}
