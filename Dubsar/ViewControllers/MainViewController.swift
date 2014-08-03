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

    // MARK: Storyboard outlets
    @IBOutlet var wotdButton : UIButton!
    @IBOutlet var searchBar : UISearchBar!
    @IBOutlet var wotdLabel : UILabel!
    @IBOutlet var wordNetLabel : UILabel!

    var alphabetView : AlphabetView!
    var autocompleterView : AutocompleterView!
    var autocompleter : DubsarModelsAutocompleter?
    var lastSequence : Int = -1
    var searchBarEditing : Bool = false
    var keyboardHeight : CGFloat = 0
    var rotated : Bool = false

    var wotd: DubsarModelsDailyWord?

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)

        // this view resizes its own height
        autocompleterView = AutocompleterView(frame: CGRectMake(0, searchBar.bounds.size.height+searchBar.frame.origin.y, view.bounds.size.width, view.bounds.size.height))
        autocompleterView.hidden = true
        autocompleterView.viewController = self
        view.addSubview(autocompleterView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardShowing:", name: UIKeyboardDidShowNotification, object: nil)

        // deprecated, but somehow not showing up in the storyboard
        searchBar.autocapitalizationType = .None
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetSearch()
        rotated = false
    }

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)
        if let viewController = segue.destinationViewController as? WordViewController {
            viewController.router = Router(viewController: viewController, model: wotd!.word)
            viewController.title = "Word of the Day"
        }
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        /* avoid the default behavior
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation) // calls adjustLayout()
        */

        // NSLog("Actual view size: %f x %f", Double(view.bounds.size.width), Double(view.bounds.size.height))
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        if alphabetView {
            alphabetView.hidden = true
        }
        rotated = true

        if alphabetView {
            // DEBT: Move this stuff into the AlphabetView
            alphabetView.hidden = false

            // First position the alphabet view where it will be after the rotation, but unrotated.
            // Move the view without resizing so that the lower righthand corner of the alphabetView
            // is in the lower righthand corner of the new view frame before the rotation begins.

            // Getting this right has been a hassle. This works, but can probably be simplified.
            var newScreenWidth: CGFloat = 0
            var newScreenHeight: CGFloat = 0

            /*
             * Somehow, on the iPhone, the main screen size is always measured in portrait, so that height > width.
             * On the iPad, it's just measured in the current orientation, so height may be less than width.
             */
            let rotatingToPortrait = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)
            let isIPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad

            if !isIPad && rotatingToPortrait {
                newScreenWidth = UIScreen.mainScreen().bounds.size.width
                newScreenHeight = UIScreen.mainScreen().bounds.size.height
            }
            else {
                newScreenWidth = UIScreen.mainScreen().bounds.size.height
                newScreenHeight = UIScreen.mainScreen().bounds.size.width
            }

            let newViewWidth = newScreenWidth
            var newViewHeight: CGFloat = newScreenHeight - navigationController.navigationBar.bounds.size.height - 20 // 20 for the status bar

            let fudge: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Phone ? 12 : 0 // the difference in the height of the nav bar between orientations
            newViewHeight += UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? -fudge : +fudge

            // newViewWidth and newViewHeight are now the correct dimensions of this view after the rotation to come.

            //*
            alphabetView.frame.origin.x = newViewWidth - alphabetView.bounds.size.width
            alphabetView.frame.origin.y = newViewHeight - alphabetView.bounds.size.height

            // Now when the rotation occurs and the animation below begins, the alphabet view will have its original size and orientation,
            // but be lined up with the lower righthand corner of the view after the rotation, at the beginning of the animation.

            /*
            NSLog("new view size: %f x %f. alphabet view size: %f x %f. alphabet view origin: %f, %f", Double(newViewWidth), Double(newViewHeight),
                Double(alphabetView.bounds.size.width), Double(alphabetView.bounds.size.height), Double(alphabetView.frame.origin.x), Double(alphabetView.frame.origin.y))
            // */

            //*
            /* Now rotate around that lower righthand corner in each case, rather than the center of the view. Actually, rotation
             * occurs around a stationary point just inside the lower righthand corner at the center of a square
             * with sides equal to the short side of the alphabet view. One of its sides is the far end of the alphabet view (bottom
             * or right).
             *
             * In each case, aspect is the ratio of the long side (of the alphabet view) in the new orientation to the long side
             * in the current orientation. The inset variable is half the short side of the alphabet view.
             * The distance from the center of the view to the stationary point is half the long side of the view minus the
             * inset variable.
             * In each case, the transformations occur like this:
             *
             * 5. The scale operation in the 4th step left the center where it was after the rotation and transverse translation, half
             *    the original long dimension (before the scale) away from the bottom right. But now that the scale has changed the size
             *    of the alphabet view, it no longer lines up with the bottom right. Finally translate it so that it lines up properly.
             * 4. Scale the view in the long dimension (after rotation, so y when rotating to portrait and x when landscape).
             * 3. Translate the stationary point back to the lower righthand corner, where it originally was.
             * 2. Rotate around the the stationary point.
             * 1. Translate the stationary point so that it is at the rotation center, originally the center of the view. If rotating
             *    to portrait, translate left. If rotating to landscape, translate up.
             */
            let π = CGFloat(M_PI)
            var transform = CGAffineTransformIdentity
            var inset: CGFloat = 0
            if UIInterfaceOrientationIsPortrait(toInterfaceOrientation) {
                // rotating from the bottom of the view to the right side
                let newAlphabetHeight = newViewHeight - searchBar.bounds.size.height
                let aspect = newAlphabetHeight / alphabetView.bounds.size.width
                inset = 0.5 * alphabetView.bounds.size.height
                let offset = 0.5 * alphabetView.bounds.size.width - inset

                transform = CGAffineTransformTranslate(transform, 0, 0.5 * (alphabetView.bounds.size.width - newAlphabetHeight))
                transform = CGAffineTransformScale(transform, 1.0, aspect)
                transform = CGAffineTransformTranslate(transform, offset, 0.0)
                transform = CGAffineTransformRotate(transform, 0.5 * π)
                transform = CGAffineTransformTranslate(transform, -offset, 0.0)
            }
            else {
                // rotating from the right side of the view to the bottom
                let aspect = newViewWidth / alphabetView.bounds.size.height
                inset = 0.5 * alphabetView.bounds.size.width
                let offset = 0.5 * alphabetView.bounds.size.height - inset

                transform = CGAffineTransformTranslate(transform, -0.5 * (newViewWidth - alphabetView.bounds.size.height), 0)
                transform = CGAffineTransformScale(transform, aspect, 1.0)
                transform = CGAffineTransformTranslate(transform, 0.0, offset)
                transform = CGAffineTransformRotate(transform, -0.5 * π)
                transform = CGAffineTransformTranslate(transform, 0.0, -offset)
            }
            // */

            //*
            UIView.animateWithDuration(duration, delay: 0.0, options: .CurveLinear,
                animations: {
                    [weak self] in
                    if let my = self {
                        my.alphabetView.transform = transform
                    }
                },
                completion: {
                    [weak self]
                    (finished: Bool) in
                    if finished {
                        self?.adjustAlphabetView(toInterfaceOrientation)
                    }
                })
            // */
        }
    }

    // MARK: UISearchBarDelegate
    func searchBarShouldBeginEditing(searchBar: UISearchBar!) -> Bool {
        searchBar.showsCancelButton = true
        searchBarEditing = true
        return true
    }

    func searchBarDidEndEditing(searchBar: UISearchBar!) {
        resetSearch()
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        resetSearch()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
        let search = DubsarModelsSearch(term: searchBar.text, matchCase: false)
        resetSearch()

        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search, routerAction: .UpdateView)
    }

    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
        autocompleter?.cancel()

        if !searchBarEditing || searchText.isEmpty {
            autocompleterView.hidden = true
            return
        }

        if !rotated {
            triggerAutocompletion()
        }
        // else wait for keyboardShown: to be called to recompute the keyboard height
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        switch router.routerAction {
        case .UpdateView:
            NSLog(".UpdateView")
            if let wotd = router.model as? DubsarModelsDailyWord {
                self.wotd = wotd
                wotdButton.setTitle(wotd.word.nameAndPos, forState: .Normal)
            }

        case .UpdateAutocompleter:
            NSLog(".UpdateAutocompleter")
            let ac = router.model as DubsarModelsAutocompleter
            if ac.seqNum >= lastSequence {
                autocompleterFinished(ac, withError: nil)
            }

        default:
            NSLog("Unexpected routerAction")
            break
        }
    }

    override func load() {
        /*
         * This is an exceptional case where we want to load every time. The load entails checking the
         * user defaults for the expiration.
         */

        // new router and model each time
        router = Router(viewController: self, model: DubsarModelsDailyWord())
        router!.load()

        /*
         * If the data stored in user defaults are current (expiration is present and in the future),
         * routeResponse() is immediately called in the same thread to refresh the WOTD button. Otherwise,
         * the new WOTD is fetched from the server.
         */
    }

    func autocompleterFinished(theAutocompleter: DubsarModelsAutocompleter!, withError error: String!) {
        // NSLog("Autocompleter finished for term %@, seq. %d, result count %d", theAutocompleter.term, theAutocompleter.seqNum, theAutocompleter.results.count)
        if !searchBarEditing || searchBar.text.isEmpty {
            return
        }

        autocompleterView.autocompleter = theAutocompleter
        autocompleterView.hidden = false
    }

    override func adjustLayout() {
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        // NSLog("Using font %@", font.fontName)
        wotdLabel.font = font
        wotdButton.titleLabel.font = font
        wordNetLabel.font = font

        wotdLabel.textColor = AppConfiguration.foregroundColor
        wordNetLabel.textColor = AppConfiguration.foregroundColor
        wotdButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)

        // rerun the autocompletion request with the new max
        searchBar(searchBar, textDidChange: searchBar.text)

        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)

        // NSLog("Actual view size: %f x %f", Double(view.bounds.size.width), Double(view.bounds.size.height))

        super.adjustLayout()
    }

    override func setupToolbar() {
        let settingsButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "showSettingsView")
        navigationItem.leftBarButtonItem = settingsButton

        super.setupToolbar()
    }

    func showSettingsView() {
        pushViewControllerWithIdentifier(SettingsViewController.identifier, router: nil)
    }

    func triggerAutocompletion() {
        // compute available space
        let available = view.bounds.size.height - keyboardHeight - searchBar.bounds.size.height
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let margin = AutocompleterView.margin
        let lineHeight = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: font]).height + 3*margin

        var max: UInt = UInt(available / lineHeight) // floor
        if max < 1 {
            max = 1
        }

        // NSLog("avail. ht: %f, lineHeight: %f, max: %d", available, lineHeight, max)

        // NSLog("Autocompletion text: %@", searchText)
        autocompleter = DubsarModelsAutocompleter(term: searchBar.text, matchCase: false)
        autocompleter!.max = max
        lastSequence = autocompleter!.seqNum

        router = Router(viewController: self, model: autocompleter)
        router!.routerAction = .UpdateAutocompleter
        router!.load()
    }

    func resetSearch() {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.showsCancelButton = false

        autocompleterView.hidden = true
        searchBarEditing = false
    }

    func autocompleterView(_: AutocompleterView!, selectedResult result: String!) {
        let search = DubsarModelsSearch(term: result, matchCase: false)
        resetSearch()
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search, routerAction: .UpdateView)
    }

    func keyboardShowing(notification: NSNotification!) {
        keyboardHeight = KeyboardHelper.keyboardSizeFromNotification(notification)

        // why does this crash?
        // NSLog("Keyboard height is %f, rotated = %@", keyboardHeight, (rotated ? "true" : "false"))

        if rotated {
            triggerAutocompletion()
            rotated = false
        }
    }

    private func computeAlphabetFrame(orientation: UIInterfaceOrientation) -> CGRect {
        var alphabetFrame = CGRectZero
        let dimension: CGFloat = 50 // DEBT <-

        if UIInterfaceOrientationIsPortrait(orientation) {
            alphabetFrame = CGRectMake(view.bounds.size.width - dimension, searchBar.bounds.size.height, dimension, view.bounds.size.height - searchBar.bounds.size.height)
            // NSLog("portrait: frame (%f, %f) %f x %f", Double(alphabetFrame.origin.x), Double(alphabetFrame.origin.y), Double(alphabetFrame.size.width), Double(alphabetFrame.size.height))
        }
        else {
            alphabetFrame = CGRectMake(0, view.bounds.size.height - dimension, view.bounds.size.width, dimension)
            // NSLog("landscape: frame (%f, %f) %f x %f", Double(alphabetFrame.origin.x), Double(alphabetFrame.origin.y), Double(alphabetFrame.size.width), Double(alphabetFrame.size.height))
        }

        return alphabetFrame
    }

    func adjustAlphabetView(orientation: UIInterfaceOrientation) {
        // NSLog("adjusting alphabet view")
        var alphabetFrame = CGRectZero
        if !alphabetView {
            alphabetView = AlphabetView(frame: alphabetFrame)
            alphabetView.viewController = self
            view.addSubview(alphabetView)
        }

        alphabetFrame = computeAlphabetFrame(orientation)

        alphabetView.transform = CGAffineTransformIdentity
        alphabetView.frame = alphabetFrame
        alphabetView.hidden = false
        alphabetView.setNeedsLayout()
    }

    func alphabetView(_:AlphabetView!, selectedButton button: GlobButton!) {
        let search = DubsarModelsSearch(wildcard: button.globExpression, page: 1, title: button.titleForState(.Normal))
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search, routerAction: .UpdateView)
    }
}
