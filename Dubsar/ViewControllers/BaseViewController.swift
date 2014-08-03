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

        if router && router!.model.complete {
            routeResponse(router)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        load()
        adjustLayout()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // this probably amounts to nothing, but any cached images are easily recreated
        NavButtonImage.voidCache()
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
        adjustLayout()
    }

    func routeResponse(router: Router!) {
        if router.model.errorMessage {
            NSLog("Error from request: %@", router.model.errorMessage)
        }
    }

    func load() {
        if router && router!.model.complete {
            // NSLog("reloading view from complete model")
            routeResponse(router)
        }
        else {
            router?.load()
        }
    }

    func adjustLayout() {
        view.invalidateIntrinsicContentSize()

        view.backgroundColor = AppConfiguration.backgroundColor

        if navigationController {
            navigationController.navigationBar.barStyle = AppConfiguration.navBarStyle
            navigationController.navigationBar.barTintColor = AppConfiguration.backgroundColor
            navigationController.navigationBar.tintColor = AppConfiguration.foregroundColor
        }

        NavButtonImage.voidCache() // dump all cached images in case of font size or theme changes
        DownloadButtonImage.voidCache()
        CGHelper.voidCache()

        // any modally presented VC will be adjusted too
        let viewController = presentedViewController as? BaseViewController
        viewController?.adjustLayout()

        setupToolbar()
    }

    func loadComplete(model : DubsarModelsModel!, withError error: String?) {
        if let errorMessage = error {
            NSLog("error: %@", errorMessage)
        }
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
        let vc = instantiateViewControllerWithIdentifier(vcIdentifier, router: router)
        navigationController.pushViewController(vc, animated: true)
    }

    func pushViewControllerWithIdentifier(vcIdentifier: String!, model: DubsarModelsModel!, routerAction: RouterAction, indexPath: NSIndexPath? = nil) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(vcIdentifier) as? BaseViewController
        if let vc = viewController {
            var router: Router

            if let search = model as? DubsarModelsSearch {
                router = SearchRouter(viewController: vc, search: search)
            }
            else {
                router = Router(viewController: vc, model: model)
                router.routerAction = routerAction
                router.indexPath = indexPath
            }

            vc.router = router
            navigationController.pushViewController(vc, animated: true)
        }
    }

    func setupToolbar() {
        if !AppDelegate.instance.databaseManager.downloadInProgress {
            // meh
            let rightBarButtonItems: [UIBarButtonItem]? = navigationItem.rightBarButtonItems as? [UIBarButtonItem]
            if let items = rightBarButtonItems {
                var newItems = [UIBarButtonItem]()
                for item in items {
                    let itemAsDownloadButton = item as? DownloadBarButtonItem
                    if !itemAsDownloadButton {
                        newItems += item
                    }
                }
                navigationItem.rightBarButtonItems = newItems
            }

            return
        }

        let rightBarButtonItem: UIBarButtonItem? = navigationItem.rightBarButtonItem

        if rightBarButtonItem && !(navigationItem.rightBarButtonItem as? DownloadBarButtonItem) {
            var items = navigationItem.rightBarButtonItems as [UIBarButtonItem]
            items += downloadButton

            navigationItem.rightBarButtonItems = items
        }
        else if !rightBarButtonItem {
            navigationItem.rightBarButtonItem = downloadButton
        }
    }

    func addHomeButton() {
        let homeButton = UIBarButtonItem(title: "Home", style: UIBarButtonItemStyle.Bordered, target: self, action: "home")
        let rightBarButtonItem: UIBarButtonItem? = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = homeButton // short cut, since no view puts anything there before calling this
    }

    private var downloadButton: UIBarButtonItem {
    get {
        return DownloadBarButtonItem(target: self, action: "viewDownload:")
    }
    }

    func viewDownload(sender: UIBarButtonItem!) {
        // Go home first?
        pushViewControllerWithIdentifier(SettingsViewController.identifier, router: nil)
    }

    func home() {
        navigationController.popToRootViewControllerAnimated(true)
    }

}
