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

class MainViewController: BaseViewController, UIAlertViewDelegate, UISearchBarDelegate {

    @IBOutlet var wotdButton : UIButton
    @IBOutlet var searchBar : UISearchBar
    @IBOutlet var wotdLabel : UILabel

    var wotd : DubsarModelsDailyWord!
    var autocompleter : DubsarModelsAutocompleter?
    var lastSequence : Int = -1
    var searchBarEditing : Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        wotd = DubsarModelsDailyWord()
        wotd.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        wotd.load()
    }

    override func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        if let a = model as? DubsarModelsAutocompleter {
            if a.seqNum < lastSequence {
                return
            }
            autocompleterFinished(a, withError: nil)
        }
        else if let dailyWord = model as? DubsarModelsDailyWord {
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

    func autocompleterFinished(theAutocompleter: DubsarModelsAutocompleter!, withError error: String!) {
        NSLog("Autocompleter finished for term %@, seq. %d, result count %d", theAutocompleter.term, theAutocompleter.seqNum, theAutocompleter.results.count)
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)
        if let viewController = segue.destinationViewController as? WordViewController {
            viewController.word = wotd.word
            wotd.word.complete = false
            viewController.title = "Word of the Day"
        }
    }

    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool {
        searchBar.showsCancelButton = true
        searchBarEditing = true
        return true
    }

    func searchBarDidEndEditing(searchBar: UISearchBar!) {
        searchBarEditing = false
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false

        let search = DubsarModelsSearch(term: searchBar.text, matchCase: false)
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search)
    }

    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
        autocompleter?.cancel()

        if !searchBarEditing {
            return
        }

        NSLog("Autocompletion text: %@", searchText)
        autocompleter = DubsarModelsAutocompleter(term: searchText, matchCase: false)
        autocompleter!.delegate = self
        autocompleter!.max = 3 // should depend on view size. this includes iPads.
        autocompleter!.load()
        lastSequence = autocompleter!.seqNum
    }

    override func adjustLayout() {
        wotdLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        wotdButton.titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        super.adjustLayout()
    }

    override func setupToolbar() {
    }
}
