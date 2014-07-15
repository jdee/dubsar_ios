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

class MainViewController: UIViewController, UIAlertViewDelegate, UISearchBarDelegate, DubsarModelsLoadDelegate {

    @IBOutlet var wotdButton : UIButton
    @IBOutlet var searchBar : UISearchBar
    @IBOutlet var wotdLabel : UILabel

    var wotd : DubsarModelsDailyWord!

    override func viewDidLoad() {
        super.viewDidLoad()

        wotd = DubsarModelsDailyWord()
        wotd.delegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "adjustLayout", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        wotd.load()
        adjustLayout()
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

    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(SearchViewController.identifier) as SearchViewController
        viewController.search = DubsarModelsSearch(term: searchBar.text, matchCase: false)

        AppDelegate.instance.navigationController.pushViewController(viewController, animated: true)
    }

    func adjustLayout() {
        wotdButton.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        wotdLabel.font = wotdButton.font
        view.invalidateIntrinsicContentSize()
    }
}
