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

class HomeBarButtonItem: UIBarButtonItem {

    override init() {
        super.init()
    }

    init(target: AnyObject!, action: Selector!) {
        let dimension: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 32 : 44

        let button = HomeButton(frame: CGRectMake(0, 0, dimension, dimension))
        button.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        button.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        button.backgroundColor = UIColor.clearColor()

        super.init(customView: button)
        self.target = target
        self.action = action

        button.target = target
        button.action = action
        button.barButtonItem = self
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
