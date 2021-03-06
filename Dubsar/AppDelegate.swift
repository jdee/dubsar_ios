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

import DubsarModels
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate, DatabaseManagerDelegate {

    var window: UIWindow?
    var alertURL: NSURL?
    let dubsar = "dubsar"

    let databaseManager = DatabaseManager()
    let bookmarkManager = BookmarkManager()

    class var instance : AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as! AppDelegate
        }
    }

    var navigationController : UINavigationController {
    get {
        return window!.rootViewController as! UINavigationController
    }
    }

    private var bgTask = UIBackgroundTaskInvalid
    private var updatePending = false

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        #if DEBUG
            // .Debug is also the default, but this is where to change it. (disabled, not to mention compiled out, in release builds)
            DubsarModelsLogger.instance().logLevel = .Debug
        #endif

        setupPushNotificationsForApplication(application, withLaunchOptions:launchOptions)

        setupDBManager()

        bookmarkManager.loadBookmarks()

        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "listenForUpdatesFromExtension:", name: NSUserDefaultsDidChangeNotification, object: nil)

        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        NSUserDefaults.standardUserDefaults().synchronize()

        let viewController = navigationController.topViewController as! BaseViewController
        viewController.adjustLayout() // in case of a font change in the settings

        if let mainVC = viewController as? MainViewController {
            // checks the expiration of any cached WOTD before requesting from the server
            mainVC.load()
        }

        // probably taken care of in the VC's viewWillAppear:
        if let interface = viewController as? DatabaseManagerDelegate {
            databaseManager.delegate = interface
        }

        checkOfflineSetting()
    }

    func applicationDidEnterBackground(theApplication: UIApplication) {
        voidCache()
        NSUserDefaults.standardUserDefaults().synchronize()

        var now: time_t = 0
        time(&now)

        // if a bg task is already running, let it go.
        // If a DL is in progress, we stop it and restart it in the BG.
        // If autoupdate is on, check for updates whenever we enter the BG, which will trigger a background DL when there's a new update.
        // Limit background update checks to once per hour.
        if bgTask != UIBackgroundTaskInvalid || (!databaseManager.downloadInProgress && (!AppConfiguration.autoUpdateSetting || now - AppConfiguration.lastUpdateCheckTime < 3600)) {
            return
        }

        /*
         * If a download is in progress when we enter the background, we first cancel
         * from the main thread, leaving any partial download in Caches.
         */
        databaseManager.cancelDownload()
        databaseManager.delegate = self // avoid calling back any VC in the bg

        /*
         * Now we kick off a fresh download from the BG. This will use an If-Range header
         * to pick up where the original download left off. Callbacks are performed on
         * the thread that initiates the NSURLConnection request.
         */
        bgTask = theApplication.beginBackgroundTaskWithExpirationHandler() {
            [weak self] in

            if let my = self {
                // just cancel the download if the task expires
                my.databaseManager.cancelDownload()

                if theApplication.applicationState == .Active {
                    /*
                     * If in the meantime, the app has become
                     * active again, and this background task has expired, just kick off a new
                     * background download to pick up where we left off. If the app goes into the
                     * bg after that, that download will go into the bg again as a background task.
                     * DEBT: Is it possible to run background tasks when the app is in the foreground?
                     * Is there any sense to making the download a background task every time and just
                     * letting them continue if the app enters the background? The nice thing about
                     * using downloadInBackground() is no time limit.
                     */
                    my.databaseManager.downloadInBackground()
                }
                else if !AppConfiguration.autoUpdateSetting {
                    let localNotif = UILocalNotification()
                    localNotif.alertBody = "Background download expired"

                    theApplication.presentLocalNotificationNow(localNotif)

                    my.databaseManager.reportError(localNotif.alertBody)
                    AppConfiguration.offlineSetting = my.databaseManager.fileExists // may have rolled back to an old DB if the DL fails
                }

                theApplication.endBackgroundTask(my.bgTask)
                my.bgTask = UIBackgroundTaskInvalid
            }
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            [weak self] in

            DMDEBUG("Beginning background task with \(UIApplication.sharedApplication().backgroundTimeRemaining) s time limit")

            if let my = self {
                if AppConfiguration.autoUpdateSetting {
                    AppConfiguration.updateLastUpdateCheckTime()

                    /*
                     * Check for update. block until the response arrives. if there's a new DL, continue blocking
                     * until the download and unzip are finished.
                     */
                    my.databaseManager.updateSynchronous()

                    /*
                     * Autoupdate is on. Notify the user if the DB was actually updated. Otherwise, don't bother.
                     */
                    if my.databaseManager.databaseUpdated {
                        let localNotif = UILocalNotification()
                        localNotif.alertBody = "Database updated"
                        theApplication.presentLocalNotificationNow(localNotif)
                    }
                }
                else {
                    /*
                     * Autoupdate is off here. That probably means that the user was prompted to install the DB, and after a failure
                     * they'll be prompted again later. So we put up local notifications in the BG.
                     */

                    // Resume the download that was just now in progress.
                    // initiate the background download
                    // (in the foreground. in the background. that is, in the foreground in the background.)
                    my.databaseManager.downloadSynchronous()

                    assert(!my.databaseManager.downloadInProgress)

                    // generate a local notification
                    let localNotif = UILocalNotification()
                    if my.databaseManager.errorMessage != nil {
                        // failure
                        localNotif.alertBody = "Download failed: \(my.databaseManager.errorMessage)"
                    }
                    else {
                        // success
                        localNotif.alertBody = "Database updated"
                    }

                    theApplication.presentLocalNotificationNow(localNotif)
                }

                theApplication.endBackgroundTask(my.bgTask)
                my.bgTask = UIBackgroundTaskInvalid
            }
        }
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        voidCache()
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        DubsarServer.postDeviceToken(deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        DMERROR("application did fail (or as we say in English, failed) to register for remote notifications: \(error.localizedDescription)")
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        DMINFO("Received local notification: \(notification.alertBody)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification notification: [NSObject: AnyObject]) {
        // TODO: Check push type (dubsarPayload["type"] == "wotd")

        // Custom (Dubsar) payload handling
        let dubsarPayload = notification[dubsar] as? [NSObject: AnyObject]
        DubsarModelsDailyWord.updateWotdWithNotificationPayload(notification)

        let url = dubsarPayload?["url"] as? String
        if url != nil {
            alertURL = NSURL(string:url! as String)
        }
        else {
            alertURL = nil
        }

        if let urlString = url, let url = NSURL(string: urlString.stringByReplacingOccurrencesOfString("wotd", withString: "words")), let userDefaults = NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents") {
            userDefaults.setBool(bookmarkManager.isUrlBookmarked(url), forKey: "isFavorite")
            let isFave = userDefaults.boolForKey("isFavorite")
            DMDEBUG("Updated isFavorite to \(isFave) from push")
        }

        // Standard APNS payload handling
        let aps = notification["aps"] as? [NSObject: AnyObject]
        var body: String!
        var title: String?
        if let alert = aps?["alert"] as? String {
            body = alert
        }
        else if let alert = aps?["alert"] as? [NSObject: AnyObject] {
            body = alert["body"] as! String
            title = alert["title"] as? String
        }

        switch (application.applicationState) {
        case .Active:
            // TODO: For category "wotd," show options to View, Bookmark or Ignore.
            showAlertWithBody(body, title: title)

        case .Inactive:
            openURL(alertURL)
            alertURL = nil

        default:
            // Just update data in the background.
            break
        }
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        self.application(application, didReceiveRemoteNotification: userInfo)
        completionHandler(.NewData)
    }

    func application(theApplication: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject: AnyObject], completionHandler: (() -> Void)) {
        DMINFO("Received remote notification action \(identifier)")
        if identifier == "view" {
            application(theApplication, didReceiveRemoteNotification: userInfo)
        }
        else if identifier == "bookmark" {
            if let payload = userInfo[dubsar] as? [NSObject: AnyObject], let url = payload["url"] as? String, let aps = userInfo["aps"] as? [NSObject: AnyObject] {
                if bookmarkManager.isUrlBookmarked(NSURL(string: url)!) {
                    completionHandler()
                    return
                }

                var message: String?
                if let alert = aps["alert"] as? [NSObject: AnyObject], let body = alert["body"] as? String {
                    message = body
                }
                else if let alert = aps["alert"] as? String {
                    message = alert
                }

                DMDEBUG("attempting to bookmark word from notification: \(message)")

                var regex: NSRegularExpression?
                do {
                    regex = try NSRegularExpression(pattern: "^(.+), (\\w+)\\.$", options: [])
                }
                catch let error as NSError {
                    // not really a runtime error
                    DMERROR("Regex error: \(error.debugDescription)")
                    abort()
                }

                if let message = message, let regex = regex, let result = regex.firstMatchInString(message, options: [], range: NSMakeRange(0, message.characters.count)) {
                    let word = (message as NSString).substringWithRange(result.rangeAtIndex(1))
                    let pos = (message as NSString).substringWithRange(result.rangeAtIndex(2))

                    let wordUrl = url.stringByReplacingOccurrencesOfString("wotd", withString: "words")
                    
                    let bookmark = Bookmark(url: NSURL(string: wordUrl)!)
                    bookmark.label = "\(word), \(pos)"

                    if !bookmarkManager.isUrlBookmarked(bookmark.url) {
                        DMDEBUG("Adding bookmark for \(bookmark.label): \(bookmark.url)")
                        bookmarkManager.toggleBookmark(bookmark)
                    }
                    else {
                        DMWARN("URL \(bookmark.url) already bookmarked")
                    }
                }
                else {
                    DMWARN("Unable to find word and pos from message for bookmark")
                }
            }
            else {
                DMWARN("Unable to find payload for message to bookmark")
            }
        }
        else {
            DMWARN("Unrecognized action identifier: \(identifier)")
        }

        completionHandler()
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let scheme = url.scheme
        if scheme != dubsar {
            return false
        }

        let path = url.path
        var word : DubsarModelsWord!
        var title : String?
        if path?.hasPrefix("/wotd/") ?? false {
            let last = url.lastPathComponent as NSString?
            let wotdId = UInt(last!.intValue)
            word = DubsarModelsWord(id: wotdId, name: nil, partOfSpeech: .Unknown) // load the name and pos from the DB by ID
            title = "Word of the Day"
        }
        else if path?.hasPrefix("/words/") ?? false {
            let last = url.lastPathComponent as NSString?
            let wotdId = UInt(last!.intValue)
            word = DubsarModelsWord(id: wotdId, name: nil, partOfSpeech: .Unknown) // load the name and pos from the DB by ID
        }
        else {
            return true
        }

        let top = navigationController.topViewController as! BaseViewController

        navigationController.dismissViewControllerAnimated(true, completion: nil)
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in

            if let my = self {
                let viewController : BaseViewController! = top.instantiateViewControllerWithIdentifier(WordViewController.identifier, router: nil)
                if title != nil {
                    viewController.title = title
                }
                viewController.router = Router(viewController: viewController, model: word)
                my.navigationController.pushViewController(viewController, animated: true)
            }
        }

        DMTRACE("push \(WordViewController.identifier) view controller")
        return true
    }

    @available(iOS 8.0, *)
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        DMTRACE("Application did register user notification settings")
    }

    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        DMDEBUG("In application:performFetchWithCompletionHandler:")
        let wotd = DubsarModelsDailyWord()
        let callbackBlock = {
            [unowned self] (model: DubsarModelsModel?, error: String?) in
            if let error = error {
                DMERROR("Error getting WOTD in bg: \(error)")
                completionHandler(.Failed)
            }
            else if let newWotd = model as? DubsarModelsDailyWord {
                let fresh = newWotd.fresh ? "fresh" : "cached"
                DMDEBUG("Successfully updated WOTD in bg. WOTD is \(fresh). ID is \(newWotd.word._id)")

                if let url = NSURL(string: "dubsar:///words/\(newWotd.word._id)"), let userDefaults = NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents") {
                    userDefaults.setBool(self.bookmarkManager.isUrlBookmarked(url), forKey: "isFavorite")
                    let isFave = userDefaults.boolForKey("isFavorite")
                    DMDEBUG("Updated isFavorite to \(isFave) in background fetch")
                }

                completionHandler(newWotd.fresh ? .NewData : .NoData)
            }
        }
        wotd.callbackBlock = callbackBlock
        assert(wotd.delegate != nil)
        wotd.load();
    }

    func voidCache() {
        NavButtonImage.voidCache()
        DownloadButtonImage.voidCache()
        CGHelper.voidCache()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex index: Int) {
        if index == 0 {
            /*
             * Rejected.
             *
             * The question may have been:
             * 1. Open a push notification?
             * 2. Delete the DB and go online?
             * 3. Stop a download in progress?
             * 4. Confirm download of a required update (only on launch of a new version for the first time)?
             * 5. Confirm download of an optional update when an acceptable DB is already installed?
             * 6. Confirm download of the current DB because you just turned the switch on?
             *
             * Cancel in these cases means:
             * 1. Do nothing
             * 2. Leave the DB alone and change the switch
             * 3. Do nothing
             * 4. Change the switch (no DB is present)
             * 5. Reject the new download. This just resets the DB manager's state so that it recognizes the installed DB again. No change to the Offline setting. Nothing deleted.
             * 6. Change the switch (no DB is present)
             */
            if alertURL == nil && !databaseManager.downloadInProgress && (!updatePending || !databaseManager.oldFileExists) {
                AppConfiguration.offlineSetting = !AppConfiguration.offlineSetting
            }
            else if updatePending && databaseManager.oldFileExists {
                databaseManager.rejectDownload()
            }

            let viewController = navigationController.topViewController as! BaseViewController
            viewController.adjustLayout()

            updatePending = false
            return
        }

        if alertURL != nil {
            openURL(alertURL)
            alertURL = nil
            return
        }

        if (databaseManager.downloadInProgress) {
            databaseManager.cancelDownload()
            AppConfiguration.offlineSetting = databaseManager.fileExists // may have rolled back to an old DB in case of DL failure.
        }
        else if (updatePending || AppConfiguration.offlineSetting) {
            databaseManager.download()
        }
        else {
            databaseManager.deleteDatabase()
        }

        let viewController = navigationController.topViewController as! BaseViewController
        viewController.adjustLayout()

        updatePending = false
    }

    func databaseManager(theDatabaseManager: DatabaseManager!, encounteredError errorMessage: String!) {
        AppConfiguration.offlineSetting = theDatabaseManager.fileExists // may have rolled back to an old DB in case of DL failure.
        let viewController = navigationController.topViewController as! BaseViewController
        viewController.adjustLayout()
    }

    func downloadComplete(databaseManager: DatabaseManager!) {
        let viewController = navigationController.topViewController as! BaseViewController
        viewController.adjustLayout()
    }

    func noUpdateAvailable(databaseManager: DatabaseManager!) {
        let viewController = navigationController.topViewController as! BaseViewController
        viewController.adjustLayout()
    }

    func newDownloadAvailable(theDatabaseManager: DatabaseManager!, download: DubsarModelsDownload!, required: Bool) {
        if !AppConfiguration.offlineSetting {
            // this can change in the interim. the checkForUpdate() request doesn't take long, so the user just set the offline switch to off.
            return
        }

        if AppConfiguration.autoUpdateSetting {
            theDatabaseManager.download()
            let viewController = navigationController.topViewController as! BaseViewController
            viewController.adjustLayout()
            return
        }

        // the user might have disabled autoupdate while the bg update check was in progress. just go away in that case.
        if UIApplication.sharedApplication().applicationState != .Active {
            // reset the DB mgr's state so that it will continue to happily use the currently installed DB.
            theDatabaseManager.rejectDownload()
            return
        }

        let zippedMB = Int(Double(download.zippedSize)/Double(1024)/Double(1024) + 0.5)
        let unzippedMB = Int(Double(download.unzippedSize)/Double(1024)/Double(1024) + 0.5)

        let sizeAndPrompt = "a \(zippedMB) MB download and \(unzippedMB) MB on the device. Download and install?"

        // Alert user.
        var message: String
        var cancelTitle = "Cancel"
        let downloadTitle = "Download"
        if (required) {
            /*
             * This means that databaseManager.checkCurrentDownloadVersion() deleted the DB that was installed when the app launched because the version number
             * was too low. That method is only called if the Offline setting is true. So the choice is update or switch to online.
             */
            message = "This version of the app requires a database update. It's \(sizeAndPrompt) You can always use the app online without it."
        }
        else if (theDatabaseManager.oldFileExists) {
            /*
             * This is not a required update. There is a DB installed. The choice is update or keep the old one. (Or go to the Settings and switch to online.)
             */
            message = "A database update is ready. It's \(sizeAndPrompt) You can keep using the app offline without it."
            cancelTitle = "Remind me"
        }
        else {
            /*
             * This is not a required update. There is no DB installed. The user probably just flipped the Offline switch to request a fresh download and install.
             */
            message = "The current database is \(sizeAndPrompt) You can always use the app online without it."
        }

        let alert = UIAlertView(title: "New download available", message: message, delegate: self, cancelButtonTitle: cancelTitle, otherButtonTitles: downloadTitle)
        alert.show()
        updatePending = true
    }

    func checkForUpdate() {
        databaseManager.checkForUpdate()
        AppConfiguration.updateLastUpdateCheckTime()
    }

    func checkOfflineSetting() {
        databaseManager.rootURL = AppConfiguration.rootURL

        // consistency check. the user changed the setting in the Settings app or the Settings view

        // in case we're preparing an alert
        var message: String
        var okTitle: String
        var cancelTitle: String

        let offlineSetting = AppConfiguration.offlineSetting
        if databaseManager.downloadInProgress {
            if (offlineSetting) {
                DMTRACE("Download in progress")
                return // happy. DEBT: Do we need to check for update? If a DL is in progress, we probably just checked.
            }
            else {
                message = "Stop the download in progress?"
                okTitle = "Stop"
                cancelTitle = "Continue"
            }
        }
        else if offlineSetting == databaseManager.fileExists {
            /*
             * When autoupdate is enabled, the app checks on entering the BG. If there's a valid DB present, don't check now
             * in case of autoupdate. If it's disabled, check now (on entering the FG).
             */
            var now: time_t = 0
            time(&now)

            /*
             * Limit the frequency of update checks when autoupdate is off. If autoupdate is on, any update will simply be installed, and if it fails,
             * the app will automatically retry until it succeeds or the user intervenes. If autoupdate is off, we check for updates when the app
             * launches and then whenever the app foregrounds, but not more than once per hour. This is in case the user declines to install the new
             * update right away but keeps using an installed DB. The offline setting will remain on, and we'll get here every time the app enters
             * the foreground. This limits how often we remind the user.
             */
            if offlineSetting && !AppConfiguration.autoUpdateSetting && now - AppConfiguration.lastUpdateCheckTime >= 3600 {
                DMDEBUG("\(databaseManager.fileURL.path) exists. checking for updates")
                checkForUpdate()
            }

            return
        }
        else if offlineSetting && !databaseManager.updateCheckInProgress { // When the response comes back, if autoupdate is on, the download will just start. If autoupdate is off, the user will be prompted with an alert.
            DMTRACE("No database. Offline setting is on. Getting download list.")
            checkForUpdate()
            return
        }
        else if offlineSetting {
            DMTRACE("update check already in progress. waiting for results.")
            return
        }
        else {
            message = "Delete the database? You can download it again if you change your mind."
            okTitle = "Delete"
            cancelTitle = "Cancel"
        }

        let alert = UIAlertView(title: "Offline setting changed", message: message, delegate: self, cancelButtonTitle: cancelTitle, otherButtonTitles: okTitle)
        alert.show()
    }

    func setupDBManager() {
        if AppConfiguration.offlineSetting {
            databaseManager.checkCurrentDownloadVersion()
        }
        else {
            databaseManager.cleanOldDatabases()
        }

        databaseManager.open()
        databaseManager.delegate = self
    }

    func setupPushNotificationsForApplication(theApplication:UIApplication, withLaunchOptions launchOptions: NSDictionary?) {
        // register for push notifications
        PushWrapper.register()

        // extract the push payload, if any, from the launchOptions
        if let payload = launchOptions?.objectForKey(UIApplicationLaunchOptionsRemoteNotificationKey) as? [NSObject: AnyObject] {
            // pass it back to this app. this is where notifications arrive if a notification is tapped while the app is not running. the app is launched by the tap in that case.
            application(theApplication, didReceiveRemoteNotification: payload)
        }
    }

    func showAlertWithBody(body: String, title: String?=nil) {
        // https://devforums.apple.com/message/973043#973043
        let alert = UIAlertView()
        alert.title = title ?? "Dubsar Alert"
        alert.message = body
        alert.addButtonWithTitle("OK")
        if alertURL != nil {
            alert.addButtonWithTitle("More")
        }
        alert.cancelButtonIndex = 0
        alert.show()
        alert.delegate = self
    }

    func openURL(url: NSURL?) {
        if url == nil {
            return
        }

        let application = UIApplication.sharedApplication()

        if url!.scheme == dubsar {
            self.application(application, openURL:url!, sourceApplication:nil, annotation:url!)
        }
        else {
            // pass http/https URLS to Safari
            application.openURL(url!)
        }
    }

    func listenForUpdatesFromExtension(notification: NSNotification!) {
        guard let userDefaults = notification.object as? NSUserDefaults where userDefaults.objectForKey("extensionUpdatedBookmark") != nil else {
            return
        }

        defer {
            userDefaults.removeObjectForKey("extensionUpdatedBookmark") // set only by the extension
        }

        let wotdId = NSUserDefaults.standardUserDefaults().integerForKey(DubsarDailyWordIdKey)
        guard let url = NSURL(string: "dubsar:///words/\(wotdId)"), let wotdName = NSUserDefaults.standardUserDefaults().stringForKey(DubsarDailyWordNameKey), let wotdPos = NSUserDefaults.standardUserDefaults().stringForKey(DubsarDailyWordPosKey) else {
            return
        }

        let isFavorite = userDefaults.boolForKey("extensionUpdatedBookmark")

        // first remove the extensionUpdatedBookmark key to avoid coming in here recursively
        userDefaults.removeObjectForKey("extensionUpdatedBookmark")
        userDefaults.setBool(isFavorite, forKey: "isFavorite")
        DMTRACE("isFavorite updated by extension to \(isFavorite)")

        let label = "\(wotdName), \(wotdPos)."
        let bookmark = Bookmark(url: url)
        bookmark.label = label

        if isFavorite {
            bookmarkManager.addBookmark(bookmark)
        }
        else {
            bookmarkManager.removeBookmark(bookmark)
        }
    }
}

