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

class ViewController: UIViewController, UIAlertViewDelegate {

    @IBOutlet var versionLabel : UILabel
                            
    override func viewDidLoad() {
        super.viewDidLoad()

        let version = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey) as? String

        versionLabel.text = "Version \(version)"
    }

    func showAlert(message: String?) {
        if message {
            // https://devforums.apple.com/message/973043#973043            
            let alert = UIAlertView()
            alert.title = "Word of the Day"
            alert.message = message
            alert.addButtonWithTitle("OK")
            alert.cancelButtonIndex = 0
            alert.show()
        }
        else {
            NSLog("nil message received")
        }
    }
}
