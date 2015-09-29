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

    var wotdURL: NSURL?

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

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
                // NSLog("wotd text: \(text)")
            }

            if let url = userDefaults.stringForKey("wotdURL") {
                wotdURL = NSURL(string: url)
                // NSLog("wotd URL: \(url)")
            }
        }
        else {
            NSLog("Failed to get shared user defaults suite")
        }
    }
    
    @available(iOSApplicationExtension 8.0, *)
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }

    @available(iOSApplicationExtension 8.0, *)
    @IBAction func viewWordOfTheDay(sender: UIButton!) {
        if let url = wotdURL {
            self.extensionContext?.openURL(url, completionHandler: nil)
        }
    }
}