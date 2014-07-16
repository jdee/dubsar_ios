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

    @IBOutlet var scroller : UIScrollView

    var headerView : SynsetHeaderView?

    class var identifier : String {
        get {
            return "Synset"
        }
    }

    var synset : DubsarModelsSynset! {
    get {
        return model as? DubsarModelsSynset
    }
    set {
        model = newValue
    }
    }

    var sense : DubsarModelsSense? {
    didSet {
        if let s = sense {
            s.delegate = self
        }
    }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated) // or not?

        if !synset && sense && !sense!.complete {
            sense!.load()
        }

        // essentially disable scrolling for now?
        scroller.contentSize = scroller.bounds.size
    }

    override func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        if model === sense {
            synset = sense?.synset
            NSLog("finished sense load. synset ID is %d", synset._id)
            headerView = SynsetHeaderView(synset: synset, frame: scroller.bounds)
            scroller.addSubview(headerView)
            synset.load()
            return
        }

        assert(model === synset)
        NSLog("synset load complete")

        adjustLayout()
    }

    override func adjustLayout() {
        headerView?.setNeedsLayout()
        super.adjustLayout()
    }
}
