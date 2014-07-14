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

@infix func | (type1 : UIRemoteNotificationType, type2: UIRemoteNotificationType) -> UIRemoteNotificationType {
    return UIRemoteNotificationType(type1.toRaw() | type2.toRaw())
}

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

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
        Push.postDeviceToken(deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("application did fail (or as we say in English, failed) to register for remote notifications: %@", error.localizedDescription)
    }

    func application(application: UIApplication, didReceiveRemoteNotification notification: NSDictionary?) {
        if !notification {
            return
        }

        let dubsar = notification?.objectForKey("dubsar") as? NSDictionary
        let url = dubsar?.objectForKey("url") as? NSString
        var wotdId : Int = 0
        if url {
            let last = url!.lastPathComponent as NSString
            var localId : CInt = 0

            localId = last.intValue

            /* Alternately, without resort to NSString
            let scanner = NSScanner(string: last)
            scanner.scanInt(&localId)
            // */

            wotdId = Int(localId)
        }

        let aps = notification?.objectForKey("aps") as? NSDictionary
        let message = aps?.objectForKey("alert") as? NSString

        if let alert = message {
            NSLog("received notification \"%@\", wotd ID %d", alert, wotdId)
        }

        switch (application.applicationState) {
        case .Active:
            //* crashing
            let viewController = window!.rootViewController as ViewController
            viewController.showAlert(message)
            // */
            break
        default:
            // foregrounded or freshly launched; put up WOTD view
            break
        }
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
}

