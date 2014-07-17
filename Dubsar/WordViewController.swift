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

        adjustLayout()
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return word.complete ? word.senses.count + 1 : 1
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
        if row == 0 {
            // Word cell as the header
            var cell = tableView.dequeueReusableCellWithIdentifier(WordTableViewCell.identifier) as? WordTableViewCell
            if !cell {
                cell = WordTableViewCell()
            }
            cell!.frame = tableView.bounds
            cell!.word = word
            return cell
        }

        let sense = word.senses[row-1] as DubsarModelsSense
        let frame = tableView.bounds

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
        if row == 0 {
            return word.sizeOfCellWithConstrainedSize(tableView.bounds.size).height
        }

        let sense = word.senses[row-1] as DubsarModelsSense
        let constrainedSize = CGSizeMake(tableView.bounds.size.width-2*SenseTableViewCell.borderWidth-2*SenseTableViewCell.margin-SenseTableViewCell.accessoryWidth, tableView.bounds.size.height)
        return sense.sizeOfCellWithConstrainedSize(constrainedSize).height
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        if !word.complete {
            return
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            return
        }

        let sense = word.senses[row-1] as DubsarModelsSense
        pushViewControllerWithIdentifier(SynsetViewController.identifier, model: sense)
    }

    override func adjustLayout() {
        let numberOfRows = tableView(senseTableView, numberOfRowsInSection: 0)
        var height : CGFloat = 0
        for var j=0; j<numberOfRows; ++j {
            height += tableView(senseTableView, heightForRowAtIndexPath: NSIndexPath(forRow: j, inSection: 0))
        }

        senseTableView.contentSize = CGSizeMake(senseTableView.frame.size.width, height)

        senseTableView.reloadData()
        super.adjustLayout()
    }

}
