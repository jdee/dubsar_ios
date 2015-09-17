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

class SettingNavigationTableViewCell: UITableViewCell {

    class var identifier: String {
        get {
            return "setting-navigation"
    }
    }

    private var spinner: UIActivityIndicatorView

    init(style cellType: UITableViewCellStyle = .Default, identifier ident: String = SettingNavigationTableViewCell.identifier) {
        spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
        super.init(style: cellType, reuseIdentifier: ident)
        accessoryType = .DisclosureIndicator

        spinner.hidesWhenStopped = true
        spinner.frame = CGRectMake(2, 2, 40, 40)
        spinner.autoresizingMask = .FlexibleRightMargin
        contentView.addSubview(spinner)
    }

    required init?(coder aDecoder: NSCoder) {
        spinner = UIActivityIndicatorView()
        super.init(coder: aDecoder)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        #if DEBUG
            let sAnimated = animated ? "true" : "false"
            DMTRACE("animated = \(sAnimated)")
        #endif

        var newColor: UIColor
        if (selected) {
            spinner.startAnimating()
            textLabel!.hidden = true
            accessoryType = .None
            newColor = AppConfiguration.highlightColor
        }
        else {
            spinner.stopAnimating()
            textLabel!.hidden = false
            accessoryType = .DisclosureIndicator
            newColor = UIColor.clearColor()
        }

        if (animated) {
            UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveLinear, animations: {
                [weak self] in

                if let my = self {
                    my.contentView.backgroundColor = newColor
                }
                }, completion: nil)
        }
        else {
            contentView.backgroundColor = newColor
        }
    }

}
