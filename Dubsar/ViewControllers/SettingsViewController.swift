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
        [ [ "title" : "About", "view" : "About", "setting_type" : "nav" ],
            [ "title" : "FAQ", "view" : "FAQ", "setting_type" : "nav" ] ],

        [ [ "title" : "Current version", "value" : NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)), "setting_type" : "label" ],
            [ "title" : "Theme", "view" : "Theme", "value" : AppConfiguration.themeKey, "setting_type" : "navValue" ],
            [ "title" : "Offline", "value" : AppConfiguration.offlineKey, "setting_type" : "switchValue" ] ]
    ]

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

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

        let settings = sections[section] as [[String: String]]
        let setting = settings[row] as [String: String]
        let view = setting["view"]
        let value = setting["value"]
        let type = setting["setting_type"]

        var cell: UITableViewCell?
        if type == "navValue" {
            cell = tableView.dequeueReusableCellWithIdentifier(SettingNavigationValueTableViewCell.identifier) as? UITableViewCell
            if !cell {
                cell = SettingNavigationValueTableViewCell()
            }

            if value == AppConfiguration.themeKey {
                cell!.detailTextLabel.text = AppConfiguration.themeName
            }
        }
        else if type == "nav" {
            cell = tableView.dequeueReusableCellWithIdentifier(SettingNavigationTableViewCell.identifier) as? UITableViewCell
            if !cell {
                cell = SettingNavigationTableViewCell()
            }
        }
        else if type == "label" {
            cell = tableView.dequeueReusableCellWithIdentifier(SettingLabelTableViewCell.identifier) as? UITableViewCell
            if !cell {
                cell = SettingLabelTableViewCell()
            }
            cell!.detailTextLabel.text = value
        }
        else {
            var switchCell = tableView.dequeueReusableCellWithIdentifier(SettingSwitchValueTableViewCell.identifier) as? SettingSwitchValueTableViewCell
            if !switchCell {
                switchCell = SettingSwitchValueTableViewCell()
            }

            let offlineSwitch = switchCell!.valueSwitch
            offlineSwitch.on = AppConfiguration.offlineSetting

            offlineSwitch.tintColor = AppConfiguration.alternateBackgroundColor
            offlineSwitch.onTintColor = AppConfiguration.highlightedForegroundColor

            offlineSwitch.removeTarget(self, action: "offlineSettingChanged:", forControlEvents: .ValueChanged) // necessary?
            offlineSwitch.addTarget(self, action: "offlineSettingChanged:", forControlEvents: .ValueChanged)

            cell = switchCell
        }

        cell!.textLabel.text = setting["title"]
        cell!.textLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody, italic: false)
        cell!.backgroundColor = AppConfiguration.backgroundColor
        cell!.textLabel.textColor = AppConfiguration.foregroundColor
        if type == "label" || type == "navValue" {
            cell!.detailTextLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleSubheadline, italic: false)
            cell!.detailTextLabel.textColor = AppConfiguration.foregroundColor
        }

        return cell
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let settings = sections[section] as [[String: String]]
        return settings.count
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let section = indexPath.indexAtPosition(0)
        let row = indexPath.indexAtPosition(1)
        let settings = sections[section] as [[String: String]]
        let setting = settings[row] as [String: String]
        let type = setting["setting_type"]
        let view = setting["view"]

        if type == "nav" || type == "navValue" {
            pushViewControllerWithIdentifier(view, model: nil)
        }
    }

    func offlineSettingChanged(sender: UISwitch!) {
        AppConfiguration.offlineSetting = sender.on
        AppDelegate.checkOfflineSetting()
    }

}
