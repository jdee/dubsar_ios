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

class WordViewController: UIViewController, DubsarModelsLoadDelegate {

    @IBOutlet var nameAndPosLabel : UILabel
    @IBOutlet var inflectionsLabel : UILabel
    @IBOutlet var freqCntLabel : UILabel

    var word : DubsarModelsWord!

    override func viewDidLoad() {
        super.viewDidLoad()

        word.delegate = self
        if word.complete {
            loadComplete(word, withError: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        if !word.complete {
            word.load()
        }
    }

    func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        if let errorMessage = error {
            NSLog("error: %@", errorMessage)
            return
        }

        nameAndPosLabel.text = word.nameAndPos

        let inflections = word.inflections
        var inflectionText = ""

        // the compiler and the sourcekit crap out if I try to do
        // for (j, inflection: DubsarModelsInflection!) in enumerate(inflections as Array) // or whatever; nothing like this works
        for var j=0; j<inflections.count; ++j {
            let inflection = inflections[j] as DubsarModelsInflection

            if j < inflections.count {
                inflectionText = "\(inflectionText)\(inflection), "
            }
            else {
                inflectionText = "\(inflectionText)\(inflection)"
            }
        }

        if inflectionText.isEmpty {
            inflectionsLabel.text = ""
        }
        else {
            inflectionsLabel.text = "other forms: \(inflectionText)"
        }

        if word.freqCnt > 0 {
            freqCntLabel.text = "freq. cnt. \(word.freqCnt)"
        }
        else {
            freqCntLabel.text = ""
        }
    }
}
