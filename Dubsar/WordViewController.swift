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

class WordViewController: UIViewController, DubsarModelsLoadDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var nameAndPosLabel : UILabel
    @IBOutlet var inflectionsLabel : UILabel
    @IBOutlet var freqCntLabel : UILabel
    @IBOutlet var senseTableView : UITableView

    class var identifier : String {
        get {
            return "Word"
        }
    }

    var word : DubsarModelsWord! {
    didSet {
        word.delegate = self
    }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if word.complete {
            loadComplete(word, withError: nil)
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "adjustLayout", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        if !word.complete {
            word.load()
        }
        else {
            loadComplete(word, withError: nil)
        }
        adjustLayout()
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        senseTableView.reloadData()
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
        // for (j, inflection: String!) in enumerate(inflections as Array) // or whatever; nothing like this works
        for var j=0; j<inflections.count; ++j {
            let inflection = inflections[j] as String

            if j < inflections.count-1 {
                inflectionText = "\(inflectionText)\(inflection), "
            }
            else {
                inflectionText = "\(inflectionText)\(inflection)"
            }
        }

        if inflectionText.isEmpty {
            inflectionsLabel.text = ""
            inflectionsLabel.hidden = true
        }
        else {
            inflectionsLabel.text = "other forms: \(inflectionText)"
            inflectionsLabel.hidden = false
        }
        inflectionsLabel.invalidateIntrinsicContentSize()

        if word.freqCnt > 0 {
            freqCntLabel.text = "freq. cnt. \(word.freqCnt)"
            freqCntLabel.hidden = false
        }
        else {
            freqCntLabel.text = ""
            freqCntLabel.hidden = true
        }
        freqCntLabel.invalidateIntrinsicContentSize()

        senseTableView.reloadData()
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return word.complete ? word.senses.count : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        if !word.complete {
            var cell = tableView.dequeueReusableCellWithIdentifier(LoadingTableViewCell.identifier) as? LoadingTableViewCell
            if !cell {
                cell = LoadingTableViewCell()
            }
            return cell
        }

        let row = indexPath.indexAtPosition(1)
        let sense = word.senses[row] as DubsarModelsSense
        let frame = CGRectMake(0, 0, tableView.frame.size.width, view.bounds.size.height)

        var cell = tableView.dequeueReusableCellWithIdentifier(SenseTableViewCell.identifier) as? SenseTableViewCell
        if !cell {
            cell = SenseTableViewCell(sense: sense, frame: frame)
        }
        else {
            cell!.frame = frame
            cell!.sense = sense // resized on assignment to .sense
        }

        cell!.cellBackgroundColor = row % 2 == 1 ? UIColor.lightGrayColor() : UIColor.whiteColor()

        return cell
    }

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if !word.complete {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        if row > word.senses.count {
            return 44
        }

        let sense = word.senses[row] as DubsarModelsSense
        let paddingAndMargins = 2*SenseTableViewCell.borderWidth + 2*SenseTableViewCell.margin

        return sense.sizeWithConstrainedSize(CGSizeMake(tableView.frame.size.width-paddingAndMargins, view.bounds.size.height)).height + paddingAndMargins + SenseTableViewCell.labelLineHeight + SenseTableViewCell.margin
    }

    func adjustLayout() {
        nameAndPosLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        inflectionsLabel.font = nameAndPosLabel.font
        freqCntLabel.font = nameAndPosLabel.font
        senseTableView.reloadData()
        view.invalidateIntrinsicContentSize()
    }

}
