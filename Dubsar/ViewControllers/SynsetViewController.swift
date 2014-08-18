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

        switch router.routerAction {
        case .UpdateView:
            theSynset = router.model as? DubsarModelsSynset
            assert(theSynset)
            if theSynset!.senses.count == 1 {
                sense = theSynset!.senses.firstObject as? DubsarModelsSense
                assert(sense)
                synchSelectedWord()
            }

        case .UpdateViewWithDependency:
            theSynset = router.model as? DubsarModelsSynset
            assert(theSynset)

            sense = router.dependency
            assert(sense)
            synchSelectedWord()

        default:
            break
        }

        if !scroller {
            DMTRACE("Constructing new scroller for synset ID \(theSynset!._id), size: \(view.bounds.size.width) x \(view.bounds.size.height)")
            scroller = ScrollingSynsetView(synset: theSynset, frame: view.bounds)
            view.addSubview(scroller)
            scroller!.setTranslatesAutoresizingMaskIntoConstraints(false)

            var constraint = NSLayoutConstraint(item: scroller, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0.0)
            view.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: scroller, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0.0)
            view.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: scroller, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
            view.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: scroller, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
            view.addConstraint(constraint)
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
            // DMLOG("Selected synonym ID %d (%@)", s._id, s.name)
        }
        else {
            // DMLOG("No synonym selected")
        }

        self.sense = sense
        scroller!.sense = sense // maybe this can be done inside the scroller

        if sense {
            synchSelectedWord()
        }
    }

    func synsetHeaderView(synsetHeaderView: SynsetHeaderView!, navigatedToSense sense: DubsarModelsSense!) {
        // DMLOG("Navigate to sense ID %d (%@)", sense._id, sense.name)

        pushViewControllerWithIdentifier(WordViewController.identifier, model: sense, routerAction: .UpdateViewWithDependency)
    }

    // called from SynsetPointerView
    func navigateToPointer(model : DubsarModelsModel!) {
        if model as? DubsarModelsSense {
            pushViewControllerWithIdentifier(SynsetViewController.identifier, model: model, routerAction: .UpdateViewWithDependency)
        }
        else {
            pushViewControllerWithIdentifier(SynsetViewController.identifier, model: model, routerAction: .UpdateView)
        }
        // DMLOG("Pushed VC for pointer")
    }

    override func setupToolbar() {
        navigationItem.rightBarButtonItems = []

        super.setupToolbar()
    }

    private func synchSelectedWord() {
        assert(sense)
        if sense!.complete {
            return
        }

        let senses = theSynset!.senses as [AnyObject]

        var index = senses.count
        for (j, s) in enumerate(senses as [DubsarModelsSense]) {
            if s._id == sense!._id {
                sense = s
                index = j
                break
            }
        }

        self.router = Router(viewController: self, model: sense)
        self.router!.routerAction = .UpdateRowAtIndexPath
        self.router!.indexPath = nil // should make use of this
        self.router!.load()
        scroller?.reset()
    }
}
