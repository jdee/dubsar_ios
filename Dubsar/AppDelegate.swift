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
                            
    var window: UIWindow?
    var alertURL: NSURL?
    let dubsar = "dubsar"

    class var instance : AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as AppDelegate
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        setupPushNotificationsForApplication(application, withLaunchOptions:launchOptions)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
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
        let dubsarPayload = notification?.objectForKey(dubsar) as? NSDictionary
        let url = dubsarPayload?.objectForKey("url") as? NSString
        let type = dubsarPayload?.objectForKey("type") as? NSString
        var nsurl : NSURL?
        if url {
            nsurl = NSURL(string:url)
            if type == "wotd" {
                updateWotdByUrl(nsurl, withExpiration: dubsarPayload?.objectForKey("expiration"))
            }
        }

        // Standard APNS payload handling
        let aps = notification?.objectForKey("aps") as? NSDictionary
        let message = aps?.objectForKey("alert") as? NSString

        if let alert = message {
            NSLog("received notification \"%@\"", alert)
        }

        switch (application.applicationState) {
        case .Active:
            alertURL = nsurl
            showAlert(message)

        default:
            openURL(nsurl)
        }
    }

    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool{
        let scheme = url.scheme
        if scheme != dubsar {
            return false
        }

        let path = url.path
        if path.hasPrefix("/wotd/") {
            var wotdId : Int = 0
            var localId : CInt = 0

            let last = url.lastPathComponent as NSString
            localId = last.intValue

            wotdId = Int(localId)
        }

        return true
    }

    func setupPushNotificationsForApplication(theApplication:UIApplication, withLaunchOptions launchOptions: NSDictionary?) {
        // register for push notifications
        theApplication.registerForRemoteNotificationTypes(.Alert | .Sound)
        // extract the push payload, if any, from the launchOptions
        let payload = launchOptions?.objectForKey(UIApplicationLaunchOptionsRemoteNotificationKey) as? NSDictionary
        // pass it back to this app. this is where notifications arrive if a notification is tapped while the app is not running. the app is launched by the tap in that case.
        application(theApplication, didReceiveRemoteNotification: payload)
        if theApplication.applicationIconBadgeNumber > 0 {
            theApplication.applicationIconBadgeNumber = 0
        }
    }

    func showAlert(message: String?) {
        assert(message)
        // https://devforums.apple.com/message/973043#973043
        let alert = UIAlertView()
        alert.title = "Word of the Day"
        alert.message = message
        alert.addButtonWithTitle("OK")
        if alertURL {
            alert.addButtonWithTitle("More")
        }
        alert.cancelButtonIndex = 0
        alert.show()
        alert.delegate = self
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex index: Int) {
        if index == 1 {
            openURL(alertURL)
        }
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

    func updateWotdByUrl(url: NSURL!, withExpiration expiration: AnyObject?) {
        let last = url.lastPathComponent as NSString
        let wotdId = Int(last.intValue)

        if let nsexpiration = expiration as? NSString {
            var texpiration : time_t = 0

            if nsexpiration.hasPrefix("+") {
                // relative value if begins with a +
                time(&texpiration)
            }

            texpiration += time_t(nsexpiration.intValue)

            DubsarModelsDailyWord.updateWotdId(wotdId, expiration: texpiration)
        }
   }
}

