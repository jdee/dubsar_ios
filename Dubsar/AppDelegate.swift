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

import DubsarModels
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {

    func checkOfflineSetting() {
        let offlineSetting = AppConfiguration.offlineSetting
        let filePresent = databaseManager.downloadInProgress || databaseManager.fileExists
        if !AppConfiguration.offlineHasChanged {
            if offlineSetting == filePresent {
                return
            }
        }

        // the user changed the setting in the Settings app or the Settings view

        var message: String
        var okTitle: String
        var cancelTitle: String

        if databaseManager.downloadInProgress {
            if (offlineSetting) {
                return // happy
            }
            else {
                message = "Stop download in progress?"
                okTitle = "Stop"
                cancelTitle = "Continue"
            }
        }
        else if offlineSetting == databaseManager.fileExists {
            return; // happy
        }
        else if offlineSetting {
            message = "Download and install the database? It's a 33 MB download and 92 MB on the device."
            okTitle = "Download"
            cancelTitle = "Cancel"
        }
        else {
            message = "Delete the database?"
            okTitle = "Delete"
            cancelTitle = "Cancel"
        }

        let alert = UIAlertView(title: "Offline setting changed", message: message, delegate: self, cancelButtonTitle: cancelTitle, otherButtonTitles: okTitle)
        alert.show()
    }

    class var offlineHasChanged: Bool {
        get {
            return AppConfiguration.offlineHasChanged
        }
    }

    class var offlineSetting: Bool {
        get {
            return AppConfiguration.offlineSetting
        }
        set {
            AppConfiguration.offlineSetting = newValue
        }
    }

    var window: UIWindow?
    var alertURL: NSURL?
    let dubsar = "dubsar"

    let databaseManager = DatabaseManager()

    class var instance : AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as AppDelegate
        }
    }

    var navigationController : UINavigationController {
    get {
        return window!.rootViewController as UINavigationController
    }
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        NSUserDefaults.standardUserDefaults().synchronize()

        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout() // in case of a font change in the settings

        checkOfflineSetting()
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        NavButtonImage.voidCache()
        DownloadButtonImage.voidCache()
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication!) {
        NavButtonImage.voidCache()
        DownloadButtonImage.voidCache()
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        setupPushNotificationsForApplication(application, withLaunchOptions:launchOptions)
        databaseManager.initialize()
        return true
    }

    func application(application: UIApplication!, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData!) {
        DubsarServer.postDeviceToken(deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("application did fail (or as we say in English, failed) to register for remote notifications: %@", error.localizedDescription)
    }

    func application(application: UIApplication, didReceiveRemoteNotification notification: NSDictionary?) {
        if !notification {
            return
        }

        // Custom (Dubsar) payload handling
        let dubsarPayload = notification!.objectForKey(dubsar) as? NSDictionary
        DubsarModelsDailyWord.updateWotdWithNotificationPayload(dubsarPayload)

        let url = dubsarPayload?.objectForKey("url") as? NSString
        if url {
            alertURL = NSURL(string:url)
        }
        else {
            alertURL = nil
        }

        // Standard APNS payload handling
        let aps = notification?.objectForKey("aps") as? NSDictionary
        let alert = aps?.objectForKey("alert") as? NSString

        switch (application.applicationState) {
        case .Active:
            showAlert(alert)

        default:
            openURL(alertURL)
            alertURL = nil
        }
    }

    func application(theApplication: UIApplication!, handleActionWithIdentifier identifier: String!, forRemoteNotification userInfo: NSDictionary!, completionHandler: (() -> Void)!) {
        NSLog("Received remote notification action %@", identifier)
        application(theApplication, didReceiveRemoteNotification: userInfo)
    }

    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        let scheme = url.scheme
        if scheme != dubsar {
            return false
        }

        let path = url.path
        var word : DubsarModelsWord!
        var title : String?
        if path.hasPrefix("/wotd/") {
            let last = url.lastPathComponent as NSString
            let wotdId = UInt(last.intValue)
            word = DubsarModelsWord(id: wotdId, name: nil, partOfSpeech: .Unknown) // load the name and pos from the DB by ID
            title = "Word of the Day"
        }
        else if path.hasPrefix("/words/") {
            let last = url.lastPathComponent as NSString
            let wotdId = UInt(last.intValue)
            word = DubsarModelsWord(id: wotdId, name: nil, partOfSpeech: .Unknown) // load the name and pos from the DB by ID
        }

        let top = navigationController.topViewController as BaseViewController
        let viewController : BaseViewController! = top.instantiateViewControllerWithIdentifier("Word", model: word)
        if title {
            viewController.title = title
        }
        navigationController.dismissViewControllerAnimated(true, completion: nil)
        navigationController.pushViewController(viewController, animated: true)

        return true
    }

    func application(application: UIApplication!, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings!) {
        NSLog("Application did register user notification settings")
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex index: Int) {
        if index == 0 {
            if !alertURL {
                AppConfiguration.offlineSetting = !AppConfiguration.offlineSetting
                let viewController = navigationController.topViewController as BaseViewController
                viewController.adjustLayout()
            }

            return
        }

        if alertURL {
            openURL(alertURL)
            alertURL = nil
            return
        }

        if (databaseManager.downloadInProgress) {
            databaseManager.cancelDownload()
        }
        else if (AppConfiguration.offlineSetting) {
            databaseManager.download()
        }
        else {
            databaseManager.deleteDatabase()
        }

        let viewController = navigationController.topViewController as BaseViewController
        viewController.adjustLayout()
    }

    func setupPushNotificationsForApplication(theApplication:UIApplication, withLaunchOptions launchOptions: NSDictionary?) {
        // register for push notifications
        PushWrapper.register()

        // extract the push payload, if any, from the launchOptions
        let payload = launchOptions?.objectForKey(UIApplicationLaunchOptionsRemoteNotificationKey) as? NSDictionary
        // pass it back to this app. this is where notifications arrive if a notification is tapped while the app is not running. the app is launched by the tap in that case.
        application(theApplication, didReceiveRemoteNotification: payload)
    }

    func showAlert(message: String?) {
        assert(message)
        // https://devforums.apple.com/message/973043#973043
        let alert = UIAlertView()
        alert.title = "Dubsar Alert"
        alert.message = message
        alert.addButtonWithTitle("OK")
        if alertURL {
            alert.addButtonWithTitle("More")
        }
        alert.cancelButtonIndex = 0
        alert.show()
        alert.delegate = self
    }

    func openURL(url: NSURL?) {
        if !url {
            return
        }

        let application = UIApplication.sharedApplication()

        if url!.scheme == dubsar {
            self.application(application, openURL:url, sourceApplication:nil, annotation:nil)
        }
        else {
            // pass http/https URLS to Safari
            application.openURL(url)
        }
    }

}

