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

    /*
     * Three computed properties to help distinguish between load scenarios.
     * The sense and synset properties are just aliases for model, cast to an
     * appropriate model optional. They will be nil if the model is of the other
     * type. The property theSynset always returns a DubsarModelsSynset reference
     * if an appropriate model is present. If model is nil, or if a different
     * model type is incorrectly assigned, theSynset will be nil. Otherwise, if
     * model is a DubsarModelsSense, theSynset will be sense.synset; if model is
     * a DubsarModelsSynset, theSynset will be equal to synset.
     */

    var synset : DubsarModelsSynset? {
    get {
        return model as? DubsarModelsSynset
    }
    set {
        model = newValue
    }
    }

    var sense : DubsarModelsSense? {
    get {
        return model as? DubsarModelsSense
    }
    set {
        model = newValue
    }
    }

    var theSynset : DubsarModelsSynset? {
    get {
        if sense {
            return sense!.synset
        }
        else {
            return synset
        }
    }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Synset"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textSizeChanged", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    override func load() {
        /*
         * We no longer have a sense view. When the user taps a sense in a word view, they
         * come here, and model is a DubsarModelsSense instead of a DubsarModelsSynset. Since each
         * sense belongs to exactly one synset, it is sense.synset that we wish to display. There
         * is very little info in the sense table, and most of the information in the old sense
         * view came from the synsets table. The sense view amounted to the synset displayed in the
         * lexical context of the given word, which is identified by the sense.
         *
         * Obviously WordNet is a huge graph of data, and it's not feasible to load every association to
         * all depths. Model loads are lazy and only load enough information to display the current model
         * in its view and prepare to load any additional data from associations by loading foreign keys
         * into dummy model objects, which can later be used to load the associations.
         *
         * For instance, when displaying a word, the DubsarModelsWord.load() method loads the name,
         * part of speech, inflections and frequency count for the word as well as the ID of each
         * associated sense and the following fields for each sense: synset ID, list of synonyms
         * (word text only), lexical name, frequency count and adjective marker. This is all that is
         * necessary to display the word view in its entirety. Whenever a user tapped a sense in the old
         * word view, the load() method was called on the associated DubsarModelsSense object. This
         * loads the data necessary for the old sense view, including the sense's synset ID. A dummy
         * DubsarModelsSynset object is created to hold the synset ID and prepare for a synset load,
         * should the user visit that view.
         *
         * The sense and synset views were similar enough to be confusing, and the distinction is very
         * fine. Now the app only has a synset view. This view can be seen by tapping a sense in the
         * word view or by tapping pointers in the synset view. WordNet has two kinds of pointer: lexical
         * pointers from one sense to another, and semantic pointers from one synset to another. If the 
         * user taps a lexical pointer, they are taken to a synset view in the context of the word
         * associated with that sense (the adjective marker will be shown if present, that word will be
         * highlighted in the synonyms, and lexical pointers for that sense will be displayed as well as
         * verb frames for verb senses). If the user taps a semantic pointer, they will be taken to a
         * synset view with no word context (no adjective marker, lexical pointers or verb frames will be
         * shown, and no word will be highlighted in the synonyms).
         *
         * In the lexical case, the WordViewController passes a DubsarModelsSense object to this view
         * controller, which needs to be certain to load the associated DubsarModelsSynset object. In
         * some cases (when following lexical pointers, e.g.) the sense model itself may be incomplete
         * and require a load. In this case, both sense and sense.synset must be loaded; the model
         * property is a DubsarModelsSense, the sense property is non-nil, and the synset property is nil.
         *
         * In the semantic case, another instance of the SynsetViewController passes a DubsarModelsSynset
         * object to this view controller, which needs to be loaded simply by calling its load() method
         * as usual. In that case, the model property is a DubsarModelsSynset, the sense property is nil,
         * and the synset property is non-nil.
         *
         * Since the lexical display when viewing a sense from a word view or a lexical pointer from
         * another sense requires that both sense and sense.synset (which is not the same as the synset
         * property; synset is just an alias for model, which is not a synset in this case) be loaded,
         * a new method loadWithSynset() was introduced to load the dependency in the same DB pass.
         *
         * This greatly simplifies this view controller. A loadWithWord() method was also introduced.
         * When the viewer navigates to one of the words in the synonyms, they will be selecting a sense
         * from the DubsarModelsSynset.senses association and displaying the associated word (the
         * DubsarModelsSense.word association) in a WordViewController.
         *
         * This may be indicative of a need to change the model structure or at least load a little more
         * information when loading a word or synset. This requires review.
         */

        if model && model!.complete {
            loadComplete(model, withError: nil)
        }
        else if let s = sense {
            s.loadWithSynset()
        }
        else if let s = synset {
            s.load()
        }
    }

    override func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        assert(model)
        assert(model!.complete)
        assert(theSynset)
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

        /*
         * This sense model may already be complete from an earlier load, but without the word. Force a reload
         * here.
         */
        let newSense = DubsarModelsSense(id: sense._id, name: sense.name, partOfSpeech: sense.partOfSpeech)
        pushViewControllerWithIdentifier(WordViewController.identifier, model: newSense)
    }

    // called from SynsetPointerView
    func navigateToPointer(model : DubsarModelsModel!) {
        pushViewControllerWithIdentifier(SynsetViewController.identifier, model: model)
        // NSLog("Pushed VC for pointer")
    }

    override func setupToolbar() {
        addHomeButton()
        super.setupToolbar()
    }
}
