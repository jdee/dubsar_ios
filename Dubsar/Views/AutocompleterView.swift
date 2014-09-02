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

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .FlexibleHeight | .FlexibleWidth | .FlexibleBottomMargin

        self.layer.shadowOffset = CGSizeMake(0, 3)
        self.layer.shadowOpacity = 1.0
        self.clipsToBounds = false
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons = []

        backgroundColor = AppConfiguration.alternateBackgroundColor

        let optionalAC: DubsarModelsAutocompleter? = autocompleter
        var optionalResults: NSArray?
        if optionalAC != nil {
            optionalResults = autocompleter.results

            let margin = AutocompleterView.margin
            var y : CGFloat = margin

            if optionalResults != nil {
                DMTRACE("Laying out AutocompleterView with \(autocompleter.results.count) results")
                let results = autocompleter.results as [AnyObject]

                if results.count == 0 {
                    let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
                    let text = "No suggestions"
                    let textSize = text.sizeWithAttributes([NSFontAttributeName: font])
                    let button = UIButton(frame: CGRectMake(margin, y, bounds.size.width - 2*margin, textSize.height + 2*margin))
                    button.setTitle(text, forState: .Normal)
                    button.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
                    button.backgroundColor = AppConfiguration.highlightColor
                    button.titleLabel!.font = font
                    button.enabled = false
                    addSubview(button)
                    buttons.append(button)

                    y += textSize.height + 3*margin
                }

                for result in results as [NSString] {
                    let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
                    let textSize = result.sizeWithAttributes([NSFontAttributeName: font])
                    let button = UIButton(frame: CGRectMake(margin, y, bounds.size.width - 2*margin, textSize.height + 2*margin))
                    button.setTitle(result, forState: .Normal)
                    button.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
                    button.titleLabel!.font = font
                    button.addTarget(self, action: "resultSelected:", forControlEvents: .TouchUpInside)
                    addSubview(button)
                    buttons.append(button)

                    y += textSize.height + 3*margin
                }
            }
            else {
                DMDEBUG("Autocompleter has nil results")
            }

            frame.size.height = y
        }

        super.layoutSubviews()
    }

    @IBAction
    func resultSelected(sender: UIButton!) {
        let result = sender.titleForState(.Normal)
        // DMLOG("Button pressed for result %@", result)
        viewController?.autocompleterView(self, selectedResult: result)
    }
}
