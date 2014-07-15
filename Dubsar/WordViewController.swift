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

class WordViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var nameAndPosLabel : UILabel
    @IBOutlet var inflectionLabel : UILabel
    @IBOutlet var freqCntLabel : UILabel
    @IBOutlet var senseTableView : UITableView

    class var identifier : String {
        get {
            return "Word"
        }
    }

    var word : DubsarModelsWord! {
    get {
        return model as? DubsarModelsWord
    }

    set {
        model = newValue
    }
    }

    override func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        nameAndPosLabel.text = word.nameAndPos

        let inflectionText = word.otherForms

        if inflectionText.isEmpty {
            inflectionLabel.text = ""
        }
        else {
            inflectionLabel.text = "other forms: \(inflectionText)"
        }

        if word.freqCnt > 0 {
            freqCntLabel.text = "freq. cnt. \(word.freqCnt)"
        }
        else {
            freqCntLabel.text = ""
        }

        adjustLayout()
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

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> Float {
        if !word.complete {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        if row > word.senses.count {
            return 44
        }

        let sense = word.senses[row] as DubsarModelsSense
        let paddingAndMargins = 2*SenseTableViewCell.borderWidth + 2*SenseTableViewCell.margin
        let constrainedSize = CGSizeMake(tableView.frame.size.width-paddingAndMargins, view.bounds.size.height)
        let synonymSize = sense.synonymSizeWithConstrainedSize(constrainedSize)

        var height = sense.sizeWithConstrainedSize(constrainedSize).height + paddingAndMargins + SenseTableViewCell.labelLineHeight + SenseTableViewCell.margin
        if synonymSize.height > 0 {
            height += synonymSize.height + SenseTableViewCell.margin
        }
        return height
    }

    override func adjustLayout() {
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)

        nameAndPosLabel.font = font
        inflectionLabel.font = font
        freqCntLabel.font = font

        let numberOfRows = tableView(senseTableView, numberOfRowsInSection: 0)
        var height : Float = 0
        for var j=0; j<numberOfRows; ++j {
            height += tableView(senseTableView, heightForRowAtIndexPath: NSIndexPath(forRow: j, inSection: 0))
        }

        senseTableView.contentSize = CGSizeMake(senseTableView.frame.size.width, height)

        senseTableView.reloadData()
        super.adjustLayout()
    }

}
