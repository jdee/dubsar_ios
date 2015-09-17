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

class SettingBarButtonItem: UIBarButtonItem {

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(target: AnyObject!, action: Selector!, animating: Bool = false) {
        let dimension: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 32 : 44

        let button = GearButton(frame: CGRectMake(0, 0, dimension, dimension))
        button.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        button.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        button.backgroundColor = UIColor.clearColor()
        button.target = target
        button.action = action
        button.numTeeth = 10
        // button.rotation = CGFloat(M_PI/8)
        button.innerRingRatio = 0.18
        button.outerToothRatio = 0.375
        button.innerToothRatio = 0.3

        if animating {
            button.startAnimating()
        }

        /*
        button.layer.borderWidth = 1
        button.layer.borderColor = AppConfiguration.foregroundColor.CGColor
        // */

        self.init(customView: button)
        self.target = target
        self.action = action

        button.barButtonItem = self
    }

    func startAnimating() {
        gearButton.startAnimating()
    }

    func stopAnimating() {
        gearButton.stopAnimating()
    }

    private var gearButton: GearButton {
        get {
            return customView as! GearButton
        }
    }

}
