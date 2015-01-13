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

class SearchBarViewController: BaseViewController, UISearchBarDelegate, AutocompleterDelegate {
    
    @IBOutlet var searchBar : UISearchBar!
    var autocompleterView : AutocompleterView!
    var bookmarkListView: BookmarkListView!
    var autocompleter : DubsarModelsAutocompleter?
    var lastSequence : Int = -1
    var searchBarEditing : Bool = false
    var keyboardHeight : CGFloat = 0
    var rotated : Bool = false
    var searchScope = DubsarModelsSearchScope.Words

    override func viewDidLoad() {
        super.viewDidLoad()

        // this view resizes its own height
        autocompleterView = AutocompleterView(frame: CGRectMake(0, searchBar.bounds.size.height+searchBar.frame.origin.y, view.bounds.size.width, view.bounds.size.height))
        autocompleterView.hidden = true
        autocompleterView.viewController = self
        view.addSubview(autocompleterView)

        // The search bar is always closed (no scope buttons visible) when the bookmark view is showing. but if we try to place it while the buttons
        // are still showing, it ends up in the wrong place. This hack is the most straightforward way of dealing with it. Maybe a constraint would do the job.
        bookmarkListView = BookmarkListView(frame: CGRectMake(0, 44, view.bounds.size.width, view.bounds.size.height-44))
        bookmarkListView.hidden = true
        bookmarkListView.autoresizingMask = .FlexibleWidth | .FlexibleBottomMargin
        view.addSubview(bookmarkListView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardShowing:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardHidden:", name: UIKeyboardDidHideNotification, object: nil)

        // deprecated? but somehow not showing up in the storyboard
        searchBar.autocapitalizationType = .None
        searchBar.scopeButtonTitles = [ "Words", "Synsets" ]
        searchBar.selectedScopeButtonIndex = 0
        searchBar.layer.shadowOffset = CGSizeMake(0, 3)
        searchBar.showsBookmarkButton = true
        searchBar.clipsToBounds = false
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        rotated = true
    }


    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        /* avoid the default behavior
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation) // calls adjustLayout()
        */

        if !bookmarkListView.hidden {
            bookmarkListView.frame = CGRectMake(0, 44, view.bounds.size.width, view.bounds.size.height - 44)
            bookmarkListView.setNeedsLayout()
        }
    }

    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)

        bookmarkListView.hidden = true
    }

    // MARK: UISearchBarDelegate
    func searchBar(theSearchBar: UISearchBar!, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let scope = DubsarModelsSearchScope(rawValue: selectedScope) {
            searchScope = scope

            let enumString = scope == .Words ? "words" : "synsets"
            DMDEBUG("Changed search scope. Selected scope index \(selectedScope). Scope: \(enumString)")
            if !(theSearchBar.text as String).isEmpty {
                triggerAutocompletion()
            }
        }
    }

    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool {
        searchBar.showsCancelButton = true

        // Might want to move these into the MainViewController. If on the search view, scope bar always showing, shadow always present
        searchBar.showsScopeBar = true
        searchBar.layer.shadowOpacity = 1
        // searchBar.layer.shadowPath = UIBezierPath(rect: searchBar.bounds).CGPath

        searchBarEditing = true
        bookmarkListView.hidden = true
        return true
    }

    func searchBarBookmarkButtonClicked(searchBar: UISearchBar!) {
        DMTRACE("Bookmark button tapped")
        if searchBarEditing {
            resetSearch()
        }

        bookmarkListView.hidden = !bookmarkListView.hidden
        if !bookmarkListView.hidden {
            bookmarkListView.setNeedsLayout()
        }
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        resetSearch()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
        let search = DubsarModelsSearch(term: searchBar.text, matchCase: false, scope: searchScope)
        resetSearch()

        newSearch(search)
    }

    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
        autocompleter?.cancel(true)

        if !searchBarEditing || searchText.isEmpty {
            autocompleterView.hidden = true
            return
        }

        if !rotated {
            triggerAutocompletion()
        }
        // else wait for keyboardShown: to be called to recompute the keyboard height
    }

    func autocompleterFinished(theAutocompleter: DubsarModelsAutocompleter!, withError error: String!) {
        // DMLOG("Autocompleter finished for term %@, seq. %d, result count %d", theAutocompleter.term, theAutocompleter.seqNum, theAutocompleter.results.count)
        if !searchBarEditing || searchBar.text.isEmpty {
            return
        }

        autocompleterView.autocompleter = theAutocompleter
        autocompleterView.hidden = false
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        switch (router.routerAction) {
        case .UpdateAutocompleter:
            DMTRACE(".UpdateAutocompleter")
            let ac = router.model as DubsarModelsAutocompleter
            if ac.seqNum >= lastSequence {
                autocompleterFinished(ac, withError: nil)
            }

        default:
            break
        }
    }

    override func adjustLayout() {
        super.adjustLayout()

        // rerun the autocompletion request with the new max
        searchBar(searchBar, textDidChange: searchBar.text)

        searchBar.barStyle = AppConfiguration.barStyle
        searchBar.tintColor = AppConfiguration.foregroundColor
        searchBar.autocorrectionType = AppConfiguration.autoCorrectSetting ? .Default : .No
        // searchBar.layer.shadowPath = UIBezierPath(rect: searchBar.bounds).CGPath

    }

    func triggerAutocompletion() {
        // compute available space
        let available = view.bounds.size.height - keyboardHeight - 44
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let margin = AutocompleterView.margin
        let lineHeight = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: font]).height + 3*margin

        var max: UInt = UInt(available / lineHeight) // floor
        if max < 1 {
            max = 1
        }

        // DMLOG("avail. ht: %f, lineHeight: %f, max: %d", available, lineHeight, max)

        // DMLOG("Autocompletion text: %@", searchText)
        autocompleter = DubsarModelsAutocompleter(term: searchBar.text, matchCase: false, scope: searchScope)
        autocompleter!.max = max
        lastSequence = autocompleter!.seqNum

        router = Router(viewController: self, model: autocompleter)
        router!.routerAction = .UpdateAutocompleter
        router!.load()
    }

    func resetSearch() {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false

        autocompleterView.hidden = true
        bookmarkListView.hidden = true

        searchBarEditing = false

        adjustLayout()
    }

    func autocompleterView(_: AutocompleterView!, selectedResult result: String!) {
        let search = DubsarModelsSearch(term: result, matchCase: false, scope: searchScope)
        resetSearch()

        newSearch(search)
    }

    func keyboardShowing(notification: NSNotification!) {
        keyboardHeight = KeyboardHelper.keyboardSizeFromNotification(notification)
        if rotated {
            triggerAutocompletion()
            rotated = false
        }
    }
    
    func keyboardHidden(notification: NSNotification!) {
        adjustLayout()
    }

    // to be overridden by child class
    func newSearch(newSearch: DubsarModelsSearch!) {
    }
}
