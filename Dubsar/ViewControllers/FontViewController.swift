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

class FontViewController: BaseViewController {

    @IBOutlet var knobHolder: UIView!

    var knobControl: IOSKnobControl!

    let titles = [ "Arial", "Avenir", "Baskerville", "Cochin", "Courier", "Didot", "Euphemia", "Georgia", "Gill", "Helvetica", "Menlo", "Palatino", "Times", "Trebuchet", "Verdana" ]
    let names = [ "Arial", "Avenir Next", "Baskerville", "Cochin", "Courier New", "Didot", "Euphemia UCAS", "Georgia", "Gill Sans", "Helvetica Neue", "Menlo", "Palatino", "Times New Roman", "Trebuchet MS", "Verdana" ]
    let psNames = [ "ArialMT", "AvenirNext-Regular", "Baskerville", "Cochin", "CourierNewPSMT", "Didot", "EuphemiaUCAS", "Georgia", "GillSans", "HelveticaNeue", "Menlo-Regular", "Palatino-Roman", "TimesNewRomanPSMT", "TrebuchetMS", "Verdana" ]

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(titles.count == names.count)
        assert(titles.count == psNames.count)
        assert(titles.count == 15)

        view.backgroundColor = AppConfiguration.backgroundColor

        knobControl = IOSKnobControl(frame: knobHolder.bounds)
        knobControl.mode = .LinearReturn
        knobControl.gesture = .OneFingerRotation
        knobControl.positions = UInt(titles.count)
        knobControl.titles = titles
        knobControl.setFillColor(AppConfiguration.alternateBackgroundColor, forState: .Normal)
        knobControl.setFillColor(AppConfiguration.alternateHighlightColor, forState: .Highlighted)
        knobControl.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)

        knobControl.positionIndex = selectedFontIndex()
        let fontSetting = AppConfiguration.fontSetting

        fontChanged(knobControl) // initialize the font

        knobControl.addTarget(self, action: "fontChanged:", forControlEvents: .ValueChanged)

        adjustLayout()

        knobHolder.addSubview(knobControl)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    override func adjustLayout() {
        knobControl.setNeedsLayout()
        super.adjustLayout()
    }

    func fontChanged(sender: IOSKnobControl!) {
        if knobControl.positionIndex < 0 || knobControl.positionIndex >= names.count {
            NSLog("knob control position index %d. names.count = %d", knobControl.positionIndex, names.count)
        }

        let newFont = names[knobControl.positionIndex] as String
        AppConfiguration.setFontSetting(newFont)
        let selected = selectedFontIndex()

        if selected >= 0 {
            knobControl.fontName = psNames[selected]
            knobControl.setNeedsLayout()
        }
    }

    private func selectedFontIndex() -> Int {
        let fontSetting = AppConfiguration.fontSetting
        var selected = -1
        for (index, title) in enumerate(names) {
            if title == fontSetting {
                selected = index
                break
            }
        }
        return selected
    }

}
