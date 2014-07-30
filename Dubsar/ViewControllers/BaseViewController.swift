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

class BaseViewController: UIViewController, DubsarModelsLoadDelegate {

    var model : DubsarModelsModel? {
    didSet {
        if let m = model {
            m.delegate = self
        }
    }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "adjustLayout", name: UIContentSizeCategoryDidChangeNotification, object: nil)

        if model && model!.complete {
            loadComplete(model, withError: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // NSLog("In BaseViewController.viewWillAppear(): model is %@nil, %@complete", (model ? "" : "not "), (model?.complete ? "" : "not "))

        assert(!model || model!.delegate === self)

        load()
        adjustLayout()
        setupToolbar()
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

    func load() {
        if model && model!.complete {
            // NSLog("reloading view from complete model")
            loadComplete(model, withError: nil)
        }
        else {
            /*
            if model {
            NSLog("loading incomplete model")
            }
            else {
            NSLog("No model in base class")
            }
            // */
            model?.load()
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

        NavButtonImage.voidCache() // dump all cached images in case of font size changes

        // any modally presented VC will be adjusted too
        let viewController = presentedViewController as? BaseViewController
        viewController?.adjustLayout()
    }

    func loadComplete(model : DubsarModelsModel!, withError error: String?) {
        if let errorMessage = error {
            NSLog("error: %@", errorMessage)
        }
    }

    func instantiateViewControllerWithIdentifier(vcIdentifier: String!, model: DubsarModelsModel? = nil) -> BaseViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(vcIdentifier) as? BaseViewController
        if let vc = viewController {
            vc.model = model
        }
        return viewController
    }

    func pushViewControllerWithIdentifier(vcIdentifier: String!, model: DubsarModelsModel? = nil) {
        let vc = instantiateViewControllerWithIdentifier(vcIdentifier, model: model)
        navigationController.pushViewController(vc, animated: true)
    }

    func setupToolbar() {
        // Base does nothing. Subviews can addHomeButton() if appropriate.
    }

    func addHomeButton() {
        let homeButton = UIBarButtonItem(title: "Home", style: UIBarButtonItemStyle.Bordered, target: self, action: "home")
        navigationItem.rightBarButtonItem = homeButton
    }

    func home() {
        navigationController.popToRootViewControllerAnimated(true)
    }

}
