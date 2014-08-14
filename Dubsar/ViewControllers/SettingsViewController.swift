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

operator infix ||= {}

@infix @assignment func ||=(inout left: Bool, right: Bool) -> Bool {
    left = left || right
    return left
}

import UIKit

class SettingsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, DatabaseManagerDelegate, UIAlertViewDelegate {

    class var identifier: String {
        get {
            return "Settings"
        }
    }

    @IBOutlet var settingsTableView: UITableView!

    private var downloadCell: DownloadProgressTableViewCell?
    private var lastDownloadHeight: CGFloat = 0
    private var unzipping = false
    private var downloadViewShowing = false

    let defaultSections: [[[String: AnyObject]]] = [
        [ [ "title" : "About", "view" : "About", "setting_type" : "nav" ],
            [ "title" : "FAQ", "view" : "FAQ", "setting_type" : "nav" ] ],

        [ [ "title" : "Current version", "value" : NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)), "setting_type" : "label" ],
            [ "title" : "Theme", "view" : "Theme", "value" : AppConfiguration.themeKey, "setting_type" : "navValue" ],
            [ "title" : "Offline", "value" : AppConfiguration.offlineKey, "setting_type" : "switchValue", "setting_action" : "offlineSwitchChanged:" ],
            [ "title" : "Autoupdate", "value" : AppConfiguration.autoUpdateKey, "setting_type" : "switch_value", "setting_action" : "autoUpdateChanged:" ],
            [ "title" : "Autocorrection", "value" : AppConfiguration.autoCorrectKey, "setting_type" : "switch_value", "setting_action" : "autoCorrectChanged:" ]]
        ]

    let devSections: [[[String: AnyObject]]] = [

        // dev settings (not in settings bundle)
        [ [ "title" : "Production", "value" : AppConfiguration.productionKey, "setting_type" : "switchValue", "setting_action" : "productionSwitchChanged:" ] ]
    ]

    var sections: [[[String: AnyObject]]] {
    get {
        #if DEBUG
            return defaultSections + devSections
        #else
            return defaultSections
        #endif
    }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        let appDelegate = AppDelegate.instance
        appDelegate.databaseManager.delegate = appDelegate

        NSUserDefaults.standardUserDefaults().synchronize()
    }

    override func adjustLayout() {
        AppDelegate.instance.databaseManager.delegate = self

        if !downloadViewShowing {
            downloadViewShowing = AppDelegate.instance.databaseManager.downloadInProgress
        }

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

        let settings = sections[section] as [[String: AnyObject]]
        let setting = settings[row] as [String: String]
        let view = setting["view"]
        let value = setting["value"]
        let type = setting["setting_type"]
        let action = setting["setting_action"]

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
                cell = SettingNavigationTableViewCell(style: .Default, reuseIdentifier: SettingNavigationTableViewCell.identifier)
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
            downloadViewShowing ||= AppDelegate.instance.databaseManager.errorMessage != nil
            if !downloadViewShowing || AppConfiguration.offlineKey != value {
                var switchCell = tableView.dequeueReusableCellWithIdentifier(SettingSwitchValueTableViewCell.identifier) as? SettingSwitchValueTableViewCell
                if !switchCell {
                    switchCell = SettingSwitchValueTableViewCell()
                }

                let optionSwitch = switchCell!.valueSwitch
                optionSwitch.on = value == AppConfiguration.offlineKey ? AppConfiguration.offlineSetting :
                    value == AppConfiguration.autoUpdateKey ? AppConfiguration.autoUpdateSetting :
                    value == AppConfiguration.autoCorrectKey ? AppConfiguration.autoCorrectSetting :
                    AppConfiguration.productionSetting

                optionSwitch.tintColor = AppConfiguration.alternateBackgroundColor
                optionSwitch.onTintColor = AppConfiguration.highlightedForegroundColor

                optionSwitch.removeTarget(self, action: Selector(action!), forControlEvents: .ValueChanged) // necessary?
                optionSwitch.addTarget(self, action: Selector(action!), forControlEvents: .ValueChanged)
                
                cell = switchCell
            }
            else {
                downloadCell = tableView.dequeueReusableCellWithIdentifier(DownloadProgressTableViewCell.identifier) as? DownloadProgressTableViewCell
                if !downloadCell {
                    downloadCell = DownloadProgressTableViewCell()
                }

                updateProgressViews(downloadCell!.downloadProgress, unzipProgressView: downloadCell!.unzipProgress, downloadLabel: downloadCell!.downloadLabel, unzipLabel: downloadCell!.unzipLabel)

                downloadCell!.rebuild()
                cell = downloadCell

                if AppDelegate.instance.databaseManager.downloadInProgress {
                    downloadCell!.cancelButton.removeTarget(self, action: "closeDownloadProgress:", forControlEvents: .TouchUpInside)
                    downloadCell!.cancelButton.addTarget(self, action: "cancelDownload:", forControlEvents: .TouchUpInside)
                }
                else {
                    downloadCell!.cancelButton.removeTarget(self, action: "cancelDownload:", forControlEvents: .TouchUpInside)
                    downloadCell!.cancelButton.addTarget(self, action: "closeDownloadProgress:", forControlEvents: .TouchUpInside)
                    downloadCell!.retryButton.addTarget(self, action: "retryDownload:", forControlEvents: .TouchUpInside)
                }
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

        let settings = sections[section] as [[String: AnyObject]]
        let setting = settings[row] as [String: String]
        let type = setting["setting_type"]

        downloadViewShowing ||= AppDelegate.instance.databaseManager.errorMessage != nil
        if type == "switchValue" && downloadViewShowing && setting["value"] == AppConfiguration.offlineKey {
            let dummyCell = DownloadProgressTableViewCell()

            updateProgressViews(dummyCell.downloadProgress, unzipProgressView: dummyCell.unzipProgress, downloadLabel: dummyCell.downloadLabel, unzipLabel: dummyCell.unzipLabel)
            dummyCell.frame = CGRectMake(0, 0, view.bounds.width, view.bounds.height)
            dummyCell.rebuild()
            lastDownloadHeight = dummyCell.bounds.size.height
            return lastDownloadHeight
        }

        let fudge: CGFloat = 16
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody, italic: false)
        let height = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: font]).height + fudge

        return max(height, 44.0)
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let settings = sections[section] as [[String: AnyObject]]
        return settings.count
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let section = indexPath.indexAtPosition(0)
        let row = indexPath.indexAtPosition(1)
        let settings = sections[section] as [[String: AnyObject]]
        let setting = settings[row] as [String: String]
        let type = setting["setting_type"]
        let view = setting["view"]

        if type == "nav" || type == "navValue" {
            pushViewControllerWithIdentifier(view, router: nil)
        }
    }

    func autoUpdateChanged(sender: UISwitch!) {
        AppConfiguration.autoUpdateSetting = sender.on
    }

    func autoCorrectChanged(sender: UISwitch!) {
        AppConfiguration.autoCorrectSetting = sender.on
    }

    func offlineSwitchChanged(sender: UISwitch!) {
        AppConfiguration.offlineSetting = sender.on
        AppDelegate.instance.checkOfflineSetting()
        settingsTableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 3, inSection: 1)], withRowAnimation: .Automatic)
    }

    func productionSwitchChanged(sender: UISwitch!) {
        AppConfiguration.productionSetting = sender.on
        AppDelegate.instance.databaseManager.rootURL = AppConfiguration.rootURL
    }

    @IBAction func cancelDownload(sender: UIButton!) {
        let alert = UIAlertView(title: "Confirm", message: "Stop download in progress?", delegate: self, cancelButtonTitle: "Continue", otherButtonTitles: "Stop")
        alert.show()
    }

    @IBAction func closeDownloadProgress(sender: UIButton!) {
        let databaseManager = AppDelegate.instance.databaseManager
        if databaseManager.errorMessage {
            /*
             * The download progress view will continue showing indefinitely once the database manager encounters an error or is canceled.
             * A Retry button will be available. Once it is manually closed, we do two things:
             */

            // 1. clear the error to make sure the download view doesn't come back now that it's been dismissed
            databaseManager.clearError()

            // 2. Set the offline setting to false/NO/off. Otherwise, if you look at the settings, it looks like you're in Offline mode,
            // and if you guess that you're not, you have to cycle the switch, off first then on again, to retry the download. We could
            // reset it as soon as the download fails. But the switch is not showing, and it's convenient if you haven't cleared this
            // state that the app will prompt you to retry the download the next time you resume from the background.
            AppConfiguration.offlineSetting = databaseManager.fileExists // may have rolled back to an old DB in case of DL failure.
        }

        downloadViewShowing = false
        unzipping = false
        reloadOfflineRow()
    }

    @IBAction func retryDownload(sender: UIButton!) {
        AppDelegate.instance.databaseManager.download()
        reloadOfflineRow()
        setupToolbar()
    }

    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            return
        }

        AppDelegate.instance.databaseManager.cancelDownload()
        reloadOfflineRow()
        setupToolbar()
    }

    func updateProgressViews(downloadProgressView: UIProgressView, unzipProgressView: UIProgressView, downloadLabel: UILabel, unzipLabel: UILabel) {
        let databaseManager = AppDelegate.instance.databaseManager

        if databaseManager.errorMessage {
            if unzipping {
                unzipLabel.text = "Unzip: \(databaseManager.errorMessage)"
            }
            else {
                downloadLabel.text = "Download: \(databaseManager.errorMessage)"
            }
        }
        else if databaseManager.downloadSize > 0 && databaseManager.downloadedSoFar == 0 {
            downloadLabel.text = "Download: \(formatSize(databaseManager.downloadSize)) starting..."
            downloadProgressView.progress = 0
            unzipLabel.text = "Unzip"
            unzipProgressView.progress = 0
        }
        else if databaseManager.downloadSize > 0 && databaseManager.instantaneousDownloadRate == 0 {
            downloadProgressView.progress = Float(databaseManager.downloadedSoFar) / Float(databaseManager.downloadSize)
            downloadLabel.text = "Download: \(formatSize(databaseManager.downloadSize - databaseManager.downloadedSoFar)) ÷ \(formatRate(databaseManager.instantaneousDownloadRate)) = ∞"
        }
        else if databaseManager.downloadSize > 0 && databaseManager.downloadedSoFar < databaseManager.downloadSize {
            downloadProgressView.progress = Float(databaseManager.downloadedSoFar) / Float(databaseManager.downloadSize)
            downloadLabel.text = "Download: \(formatSize(databaseManager.downloadSize - databaseManager.downloadedSoFar)) ÷ \(formatRate(databaseManager.instantaneousDownloadRate)) = \(formatTime(databaseManager.estimatedDownloadTimeRemaining))"
        }
        else if databaseManager.downloadSize > 0 {
            let averageRate = Double(databaseManager.downloadSize) / databaseManager.elapsedDownloadTime
            downloadProgressView.progress = 1.0
            downloadLabel.text = "Download: \(formatSize(databaseManager.downloadSize)) ÷ \(formatTime(databaseManager.elapsedDownloadTime)) = \(formatRate(averageRate))"
        }

        if databaseManager.errorMessage {
            return
        }

        if databaseManager.unzippedSize > 0 && databaseManager.unzippedSoFar < databaseManager.unzippedSize {
            unzipProgressView.progress = Float(databaseManager.unzippedSoFar) / Float(databaseManager.unzippedSize)
            unzipLabel.text = "Unzip: \(formatTime(databaseManager.estimatedUnzipTimeRemaining))"
        }
        else if databaseManager.unzippedSize > 0 {
            unzipProgressView.progress = 1.0
            unzipLabel.text = "Unzipped"
        }
        else {
        }
    }

    func reloadOfflineRow() {
        // 2: offline switch
        let rows = [NSIndexPath(forRow: 2, inSection: 1)]
        settingsTableView.reloadRowsAtIndexPaths(rows, withRowAnimation: .Automatic)
    }

    func progressUpdated(databaseManager: DatabaseManager!) {
        if !downloadCell {
            return
        }

        updateProgressViews(downloadCell!.downloadProgress, unzipProgressView: downloadCell!.unzipProgress, downloadLabel: downloadCell!.downloadLabel, unzipLabel: downloadCell!.unzipLabel)
        downloadCell!.rebuild()
        let height = downloadCell!.bounds.size.height
        if height != lastDownloadHeight {
            reloadOfflineRow()
        }
    }

    func databaseManager(databaseManager: DatabaseManager!, encounteredError errorMessage: String!) {
        DMERROR("error downloading Database: \(errorMessage)")
        AppConfiguration.offlineSetting = databaseManager.fileExists // may have rolled back to an old DB in case of DL failure.
        reloadOfflineRow()
        setupToolbar()
    }

    func newDownloadAvailable(databaseManager: DatabaseManager!, download: DubsarModelsDownload!, required: Bool) {
        AppDelegate.instance.newDownloadAvailable(databaseManager, download:download, required:required)
    }

    func downloadComplete(databaseManager: DatabaseManager!) {
        DMDEBUG("Download and Unzip complete")
        unzipping = false
        reloadOfflineRow()
        setupToolbar()
    }

    func unzipStarted(databaseManager: DatabaseManager!) {
        // DMLOG("Unzip started. %ld bytes downloaded in %f s", databaseManager.downloadSize, databaseManager.elapsedDownloadTime)
        unzipping = true
        progressUpdated(databaseManager)
    }

    func downloadStarted(databaseManager: DatabaseManager!) {
        progressUpdated(databaseManager)
    }

    override func viewDownload(sender: UIBarButtonItem!) {
        // super.viewDownload(sender) // just takes us to this view. suppress.
    }

    // These things should move to the DownloadBlahCell
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
            // DEBT: fatal error: floating point value can not be converted to Int because it is less than Int.min
            // happens a lot here
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
