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

class SettingsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, DownloadProgressDelegate, UIAlertViewDelegate {

    class var identifier: String {
        get {
            return "Settings"
        }
    }

    @IBOutlet var settingsTableView: UITableView!

    private var downloadProgressView: UIProgressView?
    private var unzipProgressView: UIProgressView?
    private var downloadLabel: UILabel?
    private var unzipLabel: UILabel?

    let sections = [
        [ [ "title" : "About", "view" : "About", "setting_type" : "nav" ],
            [ "title" : "FAQ", "view" : "FAQ", "setting_type" : "nav" ] ],

        [ [ "title" : "Current version", "value" : NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)), "setting_type" : "label" ],
            [ "title" : "Theme", "view" : "Theme", "value" : AppConfiguration.themeKey, "setting_type" : "navValue" ],
            [ "title" : "Offline", "value" : AppConfiguration.offlineKey, "setting_type" : "switchValue" ] ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        AppDelegate.instance.databaseManager.delegate = self
    }

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
            if (!AppDelegate.instance.databaseManager.downloadInProgress) {
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
            else {
                var dldCell = tableView.dequeueReusableCellWithIdentifier(DownloadProgressTableViewCell.identifier) as? DownloadProgressTableViewCell
                if !dldCell {
                    dldCell = DownloadProgressTableViewCell()
                }

                dldCell!.rebuild()
                cell = dldCell
                downloadProgressView = dldCell!.downloadProgress
                unzipProgressView = dldCell!.unzipProgress
                downloadLabel = dldCell!.downloadLabel
                unzipLabel = dldCell!.unzipLabel

                dldCell!.cancelButton.addTarget(self, action: "cancelDownload:", forControlEvents: .TouchUpInside)
            }
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

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let section = indexPath.indexAtPosition(0)
        let row = indexPath.indexAtPosition(1)

        let settings = sections[section] as [[String: String]]
        let setting = settings[row] as [String: String]
        let type = setting["setting_type"]

        if type == "switchValue" && AppDelegate.instance.databaseManager.downloadInProgress {
            let dummyCell = DownloadProgressTableViewCell()
            dummyCell.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height)
            dummyCell.rebuild()
            return dummyCell.bounds.size.height
        }

        let fudge: CGFloat = 16
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody, italic: false)
        let height = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: font]).height + fudge

        return max(height, 44.0)
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

    @IBAction func cancelDownload(sender: UIButton!) {
        let alert = UIAlertView(title: "Confirm", message: "Stop download in progress?", delegate: self, cancelButtonTitle: "Continue", otherButtonTitles: "Stop")
        alert.show()
    }

    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            return
        }

        AppDelegate.instance.databaseManager.cancelDownload()
        settingsTableView.reloadData()
    }

    func progressUpdated(databaseManager: DatabaseManager!) {
        if databaseManager.downloadSize > 0 && databaseManager.downloadedSoFar < databaseManager.downloadSize && downloadProgressView {
            downloadProgressView!.progress = Float(databaseManager.downloadedSoFar) / Float(databaseManager.downloadSize)
            downloadLabel!.text = "Download: \(formatSize(databaseManager.downloadSize - databaseManager.downloadedSoFar)) ÷ \(formatRate(databaseManager.instantaneousDownloadRate)) = \(formatTime(databaseManager.estimatedDownloadTimeRemaining))"
        }

        if databaseManager.unzippedSize > 0 && unzipProgressView {
            unzipProgressView!.progress = Float(databaseManager.unzippedSoFar) / Float(databaseManager.unzippedSize)
            unzipLabel!.text = "Unzip: \(formatTime(databaseManager.estimatedUnzipTimeRemaining))"
        }
    }

    func downloadComplete(databaseManager: DatabaseManager!) {
        settingsTableView.reloadData()
    }

    func unzipStarted(databaseManager: DatabaseManager!) {

        // NSLog("Unzip started. %ld bytes downloaded in %f s", databaseManager.downloadSize, databaseManager.elapsedDownloadTime)

        if databaseManager.downloadSize > 0 && downloadProgressView {
            let averageRate = Double(databaseManager.downloadSize) / databaseManager.elapsedDownloadTime
            downloadProgressView!.progress = 1.0
            downloadLabel!.text = "Download: \(formatSize(databaseManager.downloadSize)) ÷ \(formatRate(averageRate)) = \(formatTime(databaseManager.elapsedDownloadTime))"
        }
    }

    private func formatSize(sizeBytes: Int) -> String {
        let kB: Double = 1024
        let MB = 1024 * kB
        let doubleBytes = Double(sizeBytes)

        if doubleBytes >= MB {
            return String(format: "%.1f MB", doubleBytes / MB)
        }
        else if doubleBytes >= kB {
            return String(format: "%.1f kB", doubleBytes / kB)
        }
        return String(format: "%d B", sizeBytes)
    }

    private func formatRate(rateBytesPerSecond: Double) -> String {
        let kbps: Double = 128 // 8 bits per byte
        let Mbps = 1024 * kbps

        // format as bits per second
        if (rateBytesPerSecond >= Mbps) {
            return String(format: "%.1f Mbps", rateBytesPerSecond / Mbps)
        }
        else if (rateBytesPerSecond >= kbps) {
            return String(format: "%.1f kbps", rateBytesPerSecond / kbps)
        }

        return String(format: "%.1f bps", rateBytesPerSecond * 8)

    }

    private func formatTime(intervalSeconds: NSTimeInterval) -> String {
        let minute: NSTimeInterval = 60
        let hour = 60 * minute

        if (intervalSeconds >= hour) {
            let hours: Int = Int(intervalSeconds / hour) // floor
            let secondsRemainder: Int = Int(intervalSeconds % hour)
            let minutes: Int = secondsRemainder / Int(minute)
            let seconds: Int = secondsRemainder % Int(minute)
            return String(format: "%d h %02d m %02d s", hours, minutes, seconds)
        }
        else if (intervalSeconds >= minute) {
            let minutes = Int(intervalSeconds / minute)
            let seconds = Int(intervalSeconds % minute)
            return String(format: "%d m %02d s", minutes, seconds)
        }

        return String(format: "%d s", Int(intervalSeconds))
    }

}
