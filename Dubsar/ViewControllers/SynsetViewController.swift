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

class SynsetViewController: BaseViewController {

    var scroller : ScrollingSynsetView?

    class var identifier : String {
        get {
            return "Synset"
        }
    }

    var theSynset : DubsarModelsSynset?
    var sense: DubsarModelsSense?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Synset"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textSizeChanged", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        theSynset = router.model as? DubsarModelsSynset
        assert(theSynset)

        switch router.routerAction {
        case .UpdateViewWithDependency:
            sense = router.dependency
            break
        default:
            break
        }

        if !scroller {
            // NSLog("Constructing new scroller for synset ID %d", theSynset!._id)
            scroller = ScrollingSynsetView(synset: theSynset, frame: view.bounds)
            view.addSubview(scroller)
        }
        scroller!.viewController = self
        scroller!.sense = sense // resets the scroller

        adjustLayout()
    }

    override func adjustLayout() {
        if let s = scroller {
            s.frame = view.bounds
            s.reset() // force a full redraw, which will include new fonts
        }

        // calls view.invalidateBlahBlah()
        // super.adjustLayout()
        setupToolbar()
    }

    func textSizeChanged() {
        scroller?.reset()
    }

    func synsetHeaderView(synsetHeaderView: SynsetHeaderView!, selectedSense sense: DubsarModelsSense?) {
        if let s = sense {
            NSLog("Selected synonym ID %d (%@)", s._id, s.name)
        }
        else {
            NSLog("No synonym selected")
        }

        scroller!.sense = sense // maybe this can be done inside the scroller
    }

    func synsetHeaderView(synsetHeaderView: SynsetHeaderView!, navigatedToSense sense: DubsarModelsSense!) {
        NSLog("Navigate to sense ID %d (%@)", sense._id, sense.name)

        pushViewControllerWithIdentifier(WordViewController.identifier, model: sense, routerAction: .UpdateViewWithDependency)
    }

    // called from SynsetPointerView
    func navigateToPointer(model : DubsarModelsModel!) {
        pushViewControllerWithIdentifier(SynsetViewController.identifier, model: model, routerAction: .UpdateView)
        // NSLog("Pushed VC for pointer")
    }

    override func setupToolbar() {
        navigationItem.rightBarButtonItems = []

        addHomeButton()
        super.setupToolbar()
    }
}
