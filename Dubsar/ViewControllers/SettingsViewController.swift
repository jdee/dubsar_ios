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

    let sections = [
        [ [ "title" : "About", "view" : "About" ],
        [ "title" : "FAQ", "view" : "FAQ" ] ],

        [ [ "title" : "Current version", "value" : NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey))],
        [ "title" : "Font Family", "view" : "Font", "value" : AppConfiguration.fontFamilyKey ] ]
    ]

    override func adjustLayout() {
        settingsTableView.reloadData()
        settingsTableView.backgroundColor = AppConfiguration.alternateBackgroundColor
        settingsTableView.tintColor = AppConfiguration.foregroundColor

        super.adjustLayout()
    }

    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return sections.count
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let section = indexPath.indexAtPosition(0)
        let row = indexPath.indexAtPosition(1)

        let settings = sections[section] as [Dictionary<String, String>]
        let setting = settings[row] as Dictionary<String, String>
        let view = setting["view"]
        let value = setting["value"]

        var cell: UITableViewCell?
        if view {
            if value {
                cell = tableView.dequeueReusableCellWithIdentifier(SettingNavigationValueTableViewCell.identifier) as? UITableViewCell
                if !cell {
                    cell = SettingNavigationValueTableViewCell()
                }

                if value == AppConfiguration.fontFamilyKey {
                    cell!.detailTextLabel.text = AppConfiguration.fontSetting
                }
            }
            else {
                cell = tableView.dequeueReusableCellWithIdentifier(SettingNavigationTableViewCell.identifier) as? UITableViewCell
                if !cell {
                    cell = SettingNavigationTableViewCell()
                }
            }
        }
        else if value {
            cell = tableView.dequeueReusableCellWithIdentifier(SettingLabelTableViewCell.identifier) as? UITableViewCell
            if !cell {
                cell = SettingLabelTableViewCell()
            }
            cell!.detailTextLabel.text = value
        }

        cell!.textLabel.text = setting["title"]

        return cell
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let settings = sections[section] as [Dictionary<String, String>]
        return settings.count
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let section = indexPath.indexAtPosition(0)
        let row = indexPath.indexAtPosition(1)
        let settings = sections[section] as [Dictionary<String, String>]
        let setting = settings[row] as Dictionary<String, String>
        let view = setting["view"]
        if view {
            pushViewControllerWithIdentifier(view, model: nil)
        }
    }
}
