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

class BaseViewController: UIViewController {

    var router: Router?
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "adjustLayout", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        // load()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        load()
        adjustLayout()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        router = nil // avoid coming back to a stale request
    }

    override func didReceiveMemoryWarning() {
        AppDelegate.instance.voidCache()
        super.didReceiveMemoryWarning()
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        adjustLayout()
    }

    func routeResponse(router: Router!) {
        if router.model.errorMessage {
            DMERROR("Error from request: \(router.model.errorMessage)")
        }
    }

    func load() {
        if router && router!.model.complete {
            // DMLOG("reloading view from complete model")
            routeResponse(router)
        }
        else {
            router?.load()
        }
    }

    func adjustLayout() {
        DMTRACE("In BaseViewController.adjustLayout()")
        view.invalidateIntrinsicContentSize()

        view.backgroundColor = AppConfiguration.backgroundColor

        if navigationController {
            navigationController.navigationBar.barStyle = AppConfiguration.barStyle
            navigationController.navigationBar.barTintColor = AppConfiguration.backgroundColor
            navigationController.navigationBar.tintColor = AppConfiguration.foregroundColor
            // Styling for the title
            let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
            let color = AppConfiguration.foregroundColor
            navigationController.navigationBar.titleTextAttributes = [ NSFontAttributeName: font, NSForegroundColorAttributeName: color ]
        }

        AppDelegate.instance.voidCache()

        // any modally presented VC will be adjusted too
        let viewController = presentedViewController as? BaseViewController
        viewController?.adjustLayout()

        setupToolbar()
    }

    func networkLoadFinished(model: DubsarModelsModel!) {
        UIApplication.sharedApplication().stopUsingNetwork()
    }

    func networkLoadStarted(model: DubsarModelsModel!) {
        UIApplication.sharedApplication().startUsingNetwork()
    }

    func instantiateViewControllerWithIdentifier(vcIdentifier: String!, router: Router? = nil) -> BaseViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(vcIdentifier) as? BaseViewController
        if let vc = viewController {
            if let r = router {
                vc.router = r
            }
        }
        return viewController
    }

    func pushViewControllerWithIdentifier(vcIdentifier: String!, router: Router? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in

            if let my = self {
                let vc = my.instantiateViewControllerWithIdentifier(vcIdentifier, router: router)
                my.navigationController.pushViewController(vc, animated: true)
            }
        }
        DMTRACE("push \(vcIdentifier) view controller")
    }

    func pushViewControllerWithIdentifier(vcIdentifier: String!, model: DubsarModelsModel!, routerAction: RouterAction, indexPath: NSIndexPath? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in

            if let my = self {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = storyboard.instantiateViewControllerWithIdentifier(vcIdentifier) as? BaseViewController
                if let vc = viewController {

                    var router: Router

                    if routerAction == RouterAction.UpdateViewWithDependency {
                        if vcIdentifier == WordViewController.identifier {
                            let sense = model as DubsarModelsSense
                            let word: DubsarModelsWord? = sense.word
                            assert(word)
                            router = Router(viewController: vc, model: word)
                            router.dependency = sense
                        }
                        else if vcIdentifier == SynsetViewController.identifier {
                            let sense = model as DubsarModelsSense
                            let synset: DubsarModelsSynset? = sense.synset
                            assert(synset)
                            DMTRACE("Displaying synset view for synset \(synset!._id), sense \(sense._id)")

                            router = Router(viewController: vc, model: synset)
                            router.dependency = sense
                        }
                        else {
                            // shouldn't happen
                            router = Router(viewController: vc, model: model)
                        }
                    }
                    else {
                        router = Router(viewController: vc, model: model)
                    }

                    router.routerAction = routerAction
                    router.indexPath = indexPath

                    vc.router = router
                    my.navigationController.pushViewController(vc, animated: true)
                }
            }
        }
        DMTRACE("push \(vcIdentifier) view controller")
    }

    func setupToolbar() {
        DMTRACE("In BaseViewController.setupToolbar()")

        if !AppDelegate.instance.databaseManager.downloadInProgress {
            DMTRACE("No download in progress")
            // meh
            let rightBarButtonItems: [UIBarButtonItem]? = navigationItem.rightBarButtonItems as? [UIBarButtonItem]
            if let items = rightBarButtonItems {
                var newItems = [UIBarButtonItem]()
                for item in items {
                    let itemAsDownloadButton = item as? DownloadBarButtonItem
                    if !itemAsDownloadButton {
                        newItems += item
                    }
                    else {
                        DMTRACE("Removing download bar button item")
                    }
                }
                navigationItem.rightBarButtonItems = newItems
            }

            return
        }

        let rightBarButtonItem: UIBarButtonItem? = navigationItem.rightBarButtonItem

        let myDownloadButton = DownloadBarButtonItem(target: self, action: "viewDownload:")
        if rightBarButtonItem && !(navigationItem.rightBarButtonItem as? DownloadBarButtonItem) {
            var items = navigationItem.rightBarButtonItems as [UIBarButtonItem]
            items += myDownloadButton

            navigationItem.rightBarButtonItems = items
            DMTRACE("Added a download bar button item")
        }
        else if !rightBarButtonItem {
            navigationItem.rightBarButtonItem = myDownloadButton
            DMTRACE("Right bar button item is a download bar button item")
        }

        #if DEBUG
            if navigationItem.rightBarButtonItem {
                // this could be the home button
                let targetName = navigationItem.rightBarButtonItem.target === self ? "self" :
                    (navigationItem.rightBarButtonItem.target as? UIBarButtonItem) ? "non-nil" : "nil"
                DMTRACE("Action for right bar button item is \(navigationItem.rightBarButtonItem.action.description)")
                DMTRACE("Target for right bar button item is \(targetName)")

                let responds = navigationItem.rightBarButtonItem.target.respondsToSelector(navigationItem.rightBarButtonItem.action) ? "responds" : "doesn't respond"
                DMTRACE("Target \(responds) to selector \(navigationItem.rightBarButtonItem.action.description)")

                assert(navigationItem.rightBarButtonItem.target === self)
                assert(navigationItem.rightBarButtonItem.target.respondsToSelector(navigationItem.rightBarButtonItem.action))
                assert(navigationItem.rightBarButtonItem.enabled)
            }
        #endif
    }

    func addHomeButton() {
        let homeButton = HomeBarButtonItem(target: self, action: "home")
        navigationItem.rightBarButtonItem = homeButton
    }

    @IBAction
    func viewDownload(sender: UIBarButtonItem!) {
        // Go home first?
        pushViewControllerWithIdentifier(SettingsViewController.identifier, router: nil)
    }

    func home() {
        navigationController.popToRootViewControllerAnimated(true)
    }

}
