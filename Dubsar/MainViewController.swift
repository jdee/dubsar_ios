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

class MainViewController: UIViewController, UIAlertViewDelegate, DubsarModelsLoadDelegate {

    @IBOutlet var versionLabel : UILabel
    @IBOutlet var wotdButton : UIButton

    var wotd : DubsarModelsDailyWord!

    override func viewDidLoad() {
        super.viewDidLoad()

        let version = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey) as? String

        versionLabel.text = "Version \(version)"

        wotd = DubsarModelsDailyWord()
        wotd.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        wotd.load()
    }

    func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        if let errorMessage = error {
            NSLog("error: %@", errorMessage)
            return
        }

        if let dailyWord = model as? DubsarModelsDailyWord {
            /*
             * First determine the ID of the WOTD by consulting the user defaults or requesting
             * from the server. Once we have that, load the actual word entry for info to display.
             */
            dailyWord.word.delegate = self
            dailyWord.word.load()
        }
        else if let word = model as? DubsarModelsWord {
            /*
             * Now we've loaded the word from the DB. Display it.
             */

            wotdButton.setTitle(word.nameAndPos, forState: .Normal)
        }

    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if let viewController = segue.destinationViewController as? WordViewController {
            viewController.word = wotd.word
            viewController.title = "Word of the Day"
        }
    }
}
