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

class FavoriteBarButtonItem: UIBarButtonItem {

    private var favoriteButton: FavoriteButton!

    init() {
        super.init()
    }

    init(target: AnyObject!, action: Selector!) {
        let dimension: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 32 : 44

        favoriteButton = FavoriteButton(frame: CGRectMake(0, 0, dimension, dimension))
        favoriteButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        favoriteButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        favoriteButton.backgroundColor = UIColor.clearColor()
        favoriteButton.target = target
        favoriteButton.action = action

        super.init(customView: favoriteButton)
        self.target = target
        self.action = action

        // how does this get set to nil?
        favoriteButton = customView as FavoriteButton

        favoriteButton.barButtonItem = self
    }

    func toggleButton() {
        favoriteButton.selected = !favoriteButton.selected
    }
}
