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

class ThemeViewController: BaseViewController {

    class var identifier: String {
        get {
            return "Theme"
        }
    }

    @IBOutlet var knobHolder: UIView!
    @IBOutlet var highlightLabel: UILabel!

    var knobControl: IOSKnobControl!

    let titles = [ "Scribe", "Tigris", "Augury" ]

    // these are all the iOS 7 fonts that fit the Bold and Italic pattern used in AppConfiguration, with their PS equivs. Should be a dictionary.
    let fonts = [ "Arial", "Avenir Next", "Baskerville", "Cochin", "Courier New", "Didot", "Euphemia UCAS", "Georgia", "Gill Sans", "Helvetica Neue", "Menlo", "Palatino", "Times New Roman", "Trebuchet MS", "Verdana" ]
    let psNames = [ "ArialMT", "AvenirNext-Regular", "Baskerville", "Cochin", "CourierNewPSMT", "Didot", "EuphemiaUCAS", "Georgia", "GillSans", "HelveticaNeue", "Menlo-Regular", "Palatino-Roman", "TimesNewRomanPSMT", "TrebuchetMS", "Verdana" ]

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(fonts.count == psNames.count)

        knobControl = IOSKnobControl(frame: knobHolder.bounds)
        knobControl.mode = .LinearReturn
        knobControl.gesture = .OneFingerRotation
        knobControl.positions = UInt(titles.count)
        knobControl.titles = titles

        knobControl.positionIndex = AppConfiguration.themeSetting

        knobControl.addTarget(self, action: "themeChanged:", forControlEvents: .ValueChanged)

        themeChanged(knobControl) // initialize the theme

        adjustLayout()

        knobHolder.addSubview(knobControl)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    override func adjustLayout() {
        knobControl.setFillColor(AppConfiguration.alternateBackgroundColor, forState: .Normal)
        knobControl.setFillColor(AppConfiguration.alternateHighlightColor, forState: .Highlighted)
        knobControl.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        knobControl.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        knobControl.setNeedsLayout()

        highlightLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline, italic: false)
        highlightLabel.backgroundColor = AppConfiguration.highlightColor
        highlightLabel.textColor = AppConfiguration.foregroundColor

        super.adjustLayout()
    }

    func themeChanged(sender: IOSKnobControl!) {
        if knobControl.positionIndex < 0 || knobControl.positionIndex >= titles.count {
            NSLog("knob control position index %d. names.count = %d", knobControl.positionIndex, titles.count)
        }

        AppConfiguration.themeSetting = sender.positionIndex
        let selected = selectedFontIndex()

        if selected >= 0 {
            knobControl.fontName = psNames[selected]
            knobControl.setNeedsLayout()
        }

        adjustLayout()
   }

    private func selectedFontIndex() -> Int {
        let fontSetting = AppConfiguration.fontSetting
        var selected = -1
        for (index, title) in enumerate(fonts) {
            if title == fontSetting {
                selected = index
                break
            }
        }
        return selected
    }

}
