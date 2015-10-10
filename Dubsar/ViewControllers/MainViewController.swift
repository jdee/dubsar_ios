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

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(wotdButton != nil)
        assert(wotdLabel != nil)
        assert(wordNetLabel != nil)
        assert(newsButton != nil)
        
        createTwitterButton()

        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "wordOfTheDayUpdated:", name: DubsarModelsDailyWordUpdatedNotification, object: nil)
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
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)

        setupToolbar()
        adjustAlphabetView(UIApplication.sharedApplication().statusBarOrientation)
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration: duration)

        //*
        if alphabetView != nil {
            alphabetView.hidden = true
        }
        // */
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        if wotdButton == nil {
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
                
                if let url = NSURL(string: "dubsar:///words/\(wotd.word._id)"), let userDefaults = NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents") {
                    userDefaults.setBool(AppDelegate.instance.bookmarkManager.isUrlBookmarked(url), forKey: "isFavorite")
                    let isFave = userDefaults.boolForKey("isFavorite")
                    DMTRACE("Updated isFavorite to \(isFave) from WOTD response")
                }
            }
            else if let word = router.model as? DubsarModelsWord {
                DMTRACE("Updating with word \(word.nameAndPos)")
                wotdButton.setTitle(word.nameAndPos, forState: .Normal)
                wotdButton.enabled = true
                
                if let url = NSURL(string: "dubsar:///words/\(word._id)"), let userDefaults = NSUserDefaults(suiteName: "group.com.dubsar-dictionary.Dubsar.Documents") {
                    userDefaults.setBool(AppDelegate.instance.bookmarkManager.isUrlBookmarked(url), forKey: "isFavorite")
                    let isFave = userDefaults.boolForKey("isFavorite")
                    DMTRACE("Updated isFavorite to \(isFave) from word response")
                }
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
        if wotdLabel == nil || wotdButton == nil || wordNetLabel == nil || newsButton == nil {
            return
        }

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
        twitterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(twitterButton)
        view.sendSubviewToBack(twitterButton)
        
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
        let settingButton = navigationItem.leftBarButtonItem as! SettingBarButtonItem
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

    func wordOfTheDayUpdated(notification: NSNotification!) {
        if let userInfo = notification.userInfo, let nameAndPos = userInfo["nameAndPos"] as? String {
            wotdButton.setTitle(nameAndPos, forState: .Normal)
        }
    }
}
