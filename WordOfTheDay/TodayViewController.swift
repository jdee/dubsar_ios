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
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet var wotdButton: UIButton!
    @IBOutlet var faveHolder: UIView!

    var wotdURL: NSURL?
    var wotdUpdated = false

    var favoriteButton: FavoriteButton!

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        let gold = UIColor(red: 1.0, green: 0.843, blue: 0.000, alpha: 1.0)
        // let blue = UIColor(red: 0.255, green: 0.412, blue: 0.882, alpha: 1.0) // royal blue #4169e1
        // let blue = UIColor(red: 0.392, green: 0.584, blue: 0.929, alpha: 1.0) // cornflower blue #6495ed
        let blue = UIColor(red: 0.118, green: 0.565, blue: 1.000, alpha: 1.0) // dodger blue #1e90ff

        self.favoriteButton = FavoriteButton(frame: self.faveHolder.bounds)
        self.favoriteButton.setTitleColor(gold, forState: .Normal)
        self.favoriteButton.fillColor = blue
        self.favoriteButton.addTarget(self, action: "faveTapped:", forControlEvents: .TouchUpInside)
        self.faveHolder.addSubview(self.favoriteButton)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsUpdated:", name: NSUserDefaultsDidChangeNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUserDefaults()
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

    func userDefaultsUpdated(notification: NSNotification!) {
        updateUserDefaults()
    }
    
    func updateUserDefaults() {
        if let userDefaults = NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents") {
            if let text = userDefaults.stringForKey("wotdText") {
                wotdButton.setTitle(text, forState: .Normal)
            }

            if let url = userDefaults.stringForKey("wotdURL") {
                wotdURL = NSURL(string: url)
            }

            if userDefaults.objectForKey("wotdUpdated") != nil {
                wotdUpdated = userDefaults.boolForKey("wotdUpdated")
            }
            else {
                wotdUpdated = false
            }

            if userDefaults.objectForKey("isFavorite") != nil {
                favoriteButton.selected = userDefaults.boolForKey("isFavorite")
            }
        }
        else {
            NSLog("Failed to get shared user defaults suite")
        }
    }
    
    @available(iOSApplicationExtension 8.0, *)
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        completionHandler(wotdUpdated ? .NewData : .NoData)

        wotdUpdated = false
        NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents")?.setBool(false, forKey: "wotdUpdated")
    }

    @available(iOSApplicationExtension 8.0, *)
    @IBAction func viewWordOfTheDay(sender: UIButton!) {
        if let url = wotdURL {
            self.extensionContext?.openURL(url, completionHandler: nil)
        }
    }

    func faveTapped(sender: FavoriteButton!) {
        if let userDefaults = NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents") {
            userDefaults.setBool(true, forKey: "toggleBookmark")
            userDefaults.setBool(!sender.selected, forKey: "isFavorite") // triggers udpateUserDefaults, where the button state is reset
        }
    }
}
