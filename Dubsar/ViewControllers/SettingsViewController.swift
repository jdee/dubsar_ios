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

class SettingsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    class var identifier: String {
        get {
            return "Settings"
        }
    }

    @IBOutlet var settingsTableView: UITableView!

    let settings = [
        [ "title" : "Current version", "value" : NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey))],
        [ "title" : "About", "view" : "About" ],
        [ "title" : "FAQ", "view" : "FAQ" ]
    ]

    override func adjustLayout() {
        settingsTableView.reloadData()
        settingsTableView.backgroundColor = AppConfiguration.alternateBackgroundColor
        settingsTableView.tintColor = AppConfiguration.foregroundColor

        super.adjustLayout()
    }

    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let row = indexPath.indexAtPosition(1)
        let setting = settings[row] as Dictionary<String, String>
        let view = setting["view"]
        let value = setting["value"]

        let identifier = view ? "settings" : "settings-label"

        var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
        if !cell {
            cell = UITableViewCell(style: view ? .Default : .Value1, reuseIdentifier: identifier)
        }

        cell!.textLabel.text = setting["title"]
        cell!.backgroundColor = AppConfiguration.backgroundColor
        cell!.textLabel.textColor = AppConfiguration.foregroundColor
        cell!.textLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody, italic: false)

        if view {
            cell!.accessoryType = .DisclosureIndicator
        }
        else if value {
            cell!.selectionStyle = .None
            cell!.detailTextLabel.text = setting["value"]
            cell!.detailTextLabel.textColor = AppConfiguration.foregroundColor
            cell!.detailTextLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleSubheadline, italic: false)
        }

        return cell
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let row = indexPath.indexAtPosition(1)
        let setting = settings[row] as Dictionary<String, String>
        let view = setting["view"]
        if view {
            pushViewControllerWithIdentifier(view, model: nil)
        }
    }
}
