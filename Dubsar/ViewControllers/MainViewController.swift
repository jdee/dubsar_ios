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

class MainViewController: SearchBarViewController, UIAlertViewDelegate  {

    // MARK: Storyboard outlets
    @IBOutlet var wotdButton : UIButton!
    @IBOutlet var wotdLabel : UILabel!
    @IBOutlet var wordNetLabel : UILabel!
    @IBOutlet var newsButton: UIButton!
    var twitterButton: UIButton!

    var alphabetView : AlphabetView!
    var wotd: DubsarModelsDailyWord?

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createTwitterButton()

        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)
    }

    override func viewWillAppear(animated: Bool) {
        resetSearch()
        stopAnimating()
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimating()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)
        if let viewController = segue.destinationViewController as? WordViewController {
            viewController.router = Router(viewController: viewController, model: wotd!.word)
            viewController.title = "Word of the Day"
            DMTRACE("Prepared segue for WOTD VC")
        }
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation) // calls adjustLayout()

        setupToolbar()
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)

        if alphabetView != nil {
            // DEBT: Move this stuff into the AlphabetView
            alphabetView.hidden = false

            // First position the alphabet view where it will be after the rotation, but unrotated.
            // Move the view without resizing so that the lower righthand corner of the alphabetView
            // is in the lower righthand corner of the new view frame before the rotation begins.

            // Getting this right has been a hassle. This works, but can probably be simplified.
            var newScreenWidth: CGFloat = 0
            var newScreenHeight: CGFloat = 0

            /*
             * Somehow, on the iPhone up to iOS 7, the main screen size is always measured in portrait, so that height > width.
             * On the iPad and on iOS 8+, it's just measured in the current orientation, so height may be less than width.
             */
            let rotatingToPortrait = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)
            let isIPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad

            let currentWidth = UIScreen.mainScreen().bounds.size.width
            let currentHeight = UIScreen.mainScreen().bounds.size.height

            let inverted = !isIPad && rotatingToPortrait && currentWidth < currentHeight

            if inverted {
                newScreenWidth = currentWidth
                newScreenHeight = currentHeight
            }
            else {
                newScreenWidth = currentHeight
                newScreenHeight = currentWidth
            }

            let newViewWidth = newScreenWidth
            var newViewHeight: CGFloat = newScreenHeight - navigationController!.navigationBar.bounds.size.height - 20 // 20 for the status bar

            let fudge: CGFloat = !isIPad ? 12 : 0 // the difference in the height of the nav bar between orientations
            newViewHeight += rotatingToPortrait ? -fudge : +fudge

            // newViewWidth and newViewHeight are now the correct dimensions of this view after the rotation to come.

            //*
            alphabetView.frame.origin.x = newViewWidth - alphabetView.bounds.size.width
            alphabetView.frame.origin.y = newViewHeight - alphabetView.bounds.size.height

            // Now when the rotation occurs and the animation below begins, the alphabet view will have its original size and orientation,
            // but be lined up with the lower righthand corner of the view after the rotation, at the beginning of the animation.

            DMDEBUG("new view size: \(newViewWidth) x \(newViewHeight). alphabet view size: \(alphabetView.bounds.size.width) x \(alphabetView.bounds.size.height). alphabet view origin: \(alphabetView.frame.origin.x), \(alphabetView.frame.origin.y)")

            // font can change on rotation, but:
            let typicalSize = ("WX" as NSString).sizeWithAttributes([NSFontAttributeName: alphabetView.font])

            //*
            /* Now rotate around that lower righthand corner in each case, rather than the center of the view. Actually, rotation
             * occurs around a stationary point just inside the lower righthand corner at the center of a square
             * with sides equal to the short side of the alphabet view. One of its sides is the far end of the alphabet view (bottom
             * or right).
             *
             * In each case, aspect is the ratio of the long side (of the alphabet view) in the new orientation to the long side
             * in the current orientation. The inset variable is half the short side of the alphabet view.
             * The distance from the center of the view to the stationary point (offset) is half the long side of the view minus the
             * inset variable.
             * In each case, the transformations occur like this:
             *
             * 4. Translate the stationary point back to the lower righthand corner, where it originally was.
             * 3. Rotate around the stationary point.
             * 2. Translate the stationary point so that it is at the rotation center, originally the center of the view. If rotating
             *    to portrait, translate left. If rotating to landscape, translate up.
             * 1. Scale the view in the long dimension.
             */
            let π = CGFloat(M_PI)
            var transform = CGAffineTransformIdentity
            var inset: CGFloat = 0
            if rotatingToPortrait {
                // rotating from the bottom of the view to the right side
                let newAlphabetHeight = newViewHeight - searchBar.bounds.size.height
                let aspect = newAlphabetHeight / alphabetView.bounds.size.width // < 1
                let transverseAspect = typicalSize.width / alphabetView.bounds.size.height // > 1
                inset = 0.5 * typicalSize.width
                let transverseOffset: CGFloat = 0.5*(typicalSize.width - alphabetView.bounds.size.height)
                let offset = 0.5 * newAlphabetHeight - 0.5 * aspect * alphabetView.bounds.size.height

                transform = CGAffineTransformTranslate(transform, 0.5*alphabetView.bounds.size.width - inset, transverseOffset)
                transform = CGAffineTransformRotate(transform, 0.5 * π)
                transform = CGAffineTransformTranslate(transform, -offset, 0.0)
                transform = CGAffineTransformScale(transform, aspect, transverseAspect)
            }
            else {
                // rotating from the right side of the view to the bottom
                let aspect = newViewWidth / alphabetView.bounds.size.height // > 1
                let transverseAspect = typicalSize.height / alphabetView.bounds.size.width // < 1
                inset = 0.5 * typicalSize.height
                let transverseOffset: CGFloat = 0.5*(alphabetView.bounds.size.width - typicalSize.height)
                let offset = 0.5 * newViewWidth - 0.5 * alphabetView.bounds.size.width * aspect

                transform = CGAffineTransformTranslate(transform, -transverseOffset, 0.5*alphabetView.bounds.size.height - inset)
                transform = CGAffineTransformRotate(transform, -0.5 * π)
                transform = CGAffineTransformTranslate(transform, 0.0, -offset)
                transform = CGAffineTransformScale(transform, transverseAspect, aspect)
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

            // alphabetView.transform = transform
        }
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        switch router.routerAction {
        case .UpdateView:
            DMTRACE(".UpdateView")
            if let wotd = router.model as? DubsarModelsDailyWord {
                self.wotd = wotd
                DMTRACE("Updating with WOTD \(wotd.word.nameAndPos)")
                wotdButton.setTitle(wotd.word.nameAndPos, forState: .Normal)
                wotdButton.enabled = true
            }
            else if let word = router.model as? DubsarModelsWord {
                DMTRACE("Updating with word \(word.nameAndPos)")
                wotdButton.setTitle(word.nameAndPos, forState: .Normal)
                wotdButton.enabled = true
            }

        default:
            DMTRACE("Unexpected routerAction")
            break
        }
    }

    override func load() {
        if router != nil && router!.model.loading {
            return
        }

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

    override func adjustLayout() {
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        DMTRACE("Using font \(font.fontName)")
        wotdLabel.font = font
        wotdButton.titleLabel!.font = font
        wordNetLabel.font = font
        newsButton.titleLabel!.font = font

        wotdLabel.textColor = AppConfiguration.foregroundColor
        wordNetLabel.textColor = AppConfiguration.foregroundColor
        wotdButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        wotdButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        wotdButton.setTitleColor(AppConfiguration.alternateBackgroundColor, forState: .Disabled)

        newsButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        newsButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        newsButton.setTitleColor(AppConfiguration.alternateBackgroundColor, forState: .Disabled)
        
        createTwitterButton()
        
        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)

        AppDelegate.instance.bookmarkManager.loadBookmarks()
        bookmarkListView.frame = CGRectMake(0, 44, view.bounds.size.width, view.bounds.size.height - 44)
        bookmarkListView.setNeedsLayout()

        DMTRACE("Actual view size: \(view.bounds.size.width) x \(view.bounds.size.height)")

        super.adjustLayout()
    }

    override func setupToolbar() {
        let imageView = UIImageView(image: UIImage(named: "dubsar-full"))
        imageView.contentMode = .ScaleAspectFit
        navigationItem.titleView = imageView

        let settingButton = AppDelegate.instance.databaseManager.downloadInProgress ? DownloadBarButtonItem(target:self, action:"viewDownload:") : SettingBarButtonItem(target: self, action: "showSettingView:")
        settingButton.width = 32
        navigationItem.leftBarButtonItem = settingButton
        
        let newsButtonItem = UIBarButtonItem(title: "News", style: .Bordered, target: self, action: "showNewsView:")
        navigationItem.rightBarButtonItem = newsButtonItem

        // super.setupToolbar()
    }
    
    @IBAction func showNewsView(sender: AnyObject!) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(NewsViewController.identifier) as UIViewController
        navigationController!.pushViewController(viewController, animated: true)
    }

    @IBAction func followOnTwitter(sender: UIButton!) {
        let application = UIApplication.sharedApplication()
        let urlString = "twitter://user?id=335105958"
        let url = NSURL(string: urlString)
        if application.canOpenURL(url!) {
            application.openURL(url!)
        }
        else {
            let webUrl = NSURL(string: "https://twitter.com/intent/follow?user_id=335105958")
            application.openURL(webUrl!)
        }
    }
    
    func createTwitterButton() {
        if twitterButton != nil {
            twitterButton.removeFromSuperview()
        }

        // create button with target selector. add as a subview of view.
        twitterButton = UIButton(frame: CGRectMake(0, 0, 44, 44))
        twitterButton.addTarget(self, action: "followOnTwitter:", forControlEvents: .TouchUpInside)
        twitterButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(twitterButton)
        
        // constrain to have constant height and width
        var constraint = NSLayoutConstraint(item: twitterButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 44.0)
        twitterButton.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: twitterButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 44.0)
        twitterButton.addConstraint(constraint)

        // constrain to align with the top of the WOTD label
        constraint = NSLayoutConstraint(item: twitterButton, attribute: .Top, relatedBy: .Equal, toItem: wotdLabel, attribute: .Top, multiplier: 1.0, constant: -12)
        view.addConstraint(constraint)

        // constrain to be always just to the left of the WOTD label
        let wotdLabelWidth = computeWotdLabelSize().width
        constraint = NSLayoutConstraint(item: twitterButton, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: -48 - 0.5 * wotdLabelWidth)
        view.addConstraint(constraint)
        
        positionTwitterButton()
        setTwitterButtonImage()
    }
    
    func setTwitterButtonImage() {
        let twitterImage = UIImage(named: "twitter-\(AppConfiguration.twitterColor)")
        twitterButton.setImage(twitterImage, forState: .Normal)
    }
    
    func computeWotdLabelSize() -> CGSize {
        let string: NSString = wotdLabel.text!
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)

        let size = string.sizeWithAttributes([NSFontAttributeName: font])
        return size
    }

    func positionTwitterButton() {
        let size = computeWotdLabelSize()
        twitterButton.frame.origin.x = 0.5 * (view.bounds.size.width - size.width) - 48
        twitterButton.frame.origin.y = wotdLabel.frame.origin.y
        DMTRACE("Twitter button at (\(twitterButton.frame.origin.x), \(twitterButton.frame.origin.y))")
    }

    func showSettingView(sender: SettingBarButtonItem!) {
        let settingButton = navigationItem.leftBarButtonItem as SettingBarButtonItem
        settingButton.startAnimating()

        pushViewControllerWithIdentifier(SettingsViewController.identifier, router: nil)
    }

    func stopAnimating() {
        let settingButton = navigationItem.leftBarButtonItem as? SettingBarButtonItem
        if let s = settingButton {
            s.stopAnimating()
        }
    }

    private func computeAlphabetFrame(orientation: UIInterfaceOrientation) -> CGRect {
        var alphabetFrame = CGRectZero
        let dimension: CGFloat = 50 // DEBT <-
        let searchBarHeight: CGFloat = 44

        // always place the alphabet view so that the top is under the scope buttons, at the bottom of the search bar proper.

        if UIInterfaceOrientationIsPortrait(orientation) {
            alphabetFrame = CGRectMake(view.bounds.size.width - dimension, searchBarHeight, dimension, view.bounds.size.height - searchBarHeight)
            // DMLOG("portrait: frame (%f, %f) %f x %f", Double(alphabetFrame.origin.x), Double(alphabetFrame.origin.y), Double(alphabetFrame.size.width), Double(alphabetFrame.size.height))
        }
        else {
            alphabetFrame = CGRectMake(0, view.bounds.size.height - dimension, view.bounds.size.width, dimension)
            // DMLOG("landscape: frame (%f, %f) %f x %f", Double(alphabetFrame.origin.x), Double(alphabetFrame.origin.y), Double(alphabetFrame.size.width), Double(alphabetFrame.size.height))
        }

        return alphabetFrame
    }

    func adjustAlphabetView(orientation: UIInterfaceOrientation) {
        DMTRACE("adjusting alphabet view")
        var alphabetFrame = CGRectZero
        if alphabetView == nil {
            alphabetView = AlphabetView(frame: alphabetFrame)
            alphabetView.viewController = self
            view.addSubview(alphabetView)
            view.sendSubviewToBack(alphabetView)
        }

        alphabetFrame = computeAlphabetFrame(orientation)

        alphabetView.transform = CGAffineTransformIdentity
        alphabetView.frame = alphabetFrame
        alphabetView.hidden = false
        alphabetView.setNeedsLayout()
    }

    func alphabetView(_:AlphabetView!, selectedButton button: GlobButton!) {
        let search = DubsarModelsSearch(wildcard: button.globExpression, page: 1, title: button.titleForState(.Normal), scope: .Words)
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: search, routerAction: .UpdateView)
    }

    override func newSearch(newSearch: DubsarModelsSearch!) {
        pushViewControllerWithIdentifier(SearchViewController.identifier, model: newSearch, routerAction: .UpdateView)
    }

    override func resetSearch() {
        super.resetSearch()

        searchBar.text = ""
        searchBar.showsScopeBar = false
        searchBar.layer.shadowOpacity = 0
    }
}
