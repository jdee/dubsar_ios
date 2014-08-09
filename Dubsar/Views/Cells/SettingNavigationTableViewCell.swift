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

class SettingNavigationTableViewCell: UITableViewCell {

    class var identifier: String {
        get {
            return "setting-navigation"
        }
    }

    private var spinner: UIActivityIndicatorView

    init(style cellType: UITableViewCellStyle = .Default, reuseIdentifier ident: String = SettingNavigationTableViewCell.identifier) {
        spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
        super.init(style: cellType, reuseIdentifier: ident)
        accessoryType = .DisclosureIndicator

        spinner.hidesWhenStopped = true
        spinner.frame = CGRectMake(2, 2, 40, 40)
        contentView.addSubview(spinner)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if (selected) {
            spinner.startAnimating()
            textLabel.hidden = true
            accessoryType = .None
            contentView.backgroundColor = AppConfiguration.highlightColor
        }
        else {
            spinner.stopAnimating()
            textLabel.hidden = false
            accessoryType = .DisclosureIndicator
            contentView.backgroundColor = UIColor.clearColor()
        }
    }

}
