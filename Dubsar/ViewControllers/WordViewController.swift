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

    @IBOutlet var senseTableView : UITableView!

    class var identifier : String {
        get {
            return "Word"
        }
    }

    /*
    * Three computed properties to help distinguish between load scenarios.
    * The sense and word properties are just aliases for model, cast to an
    * appropriate model optional. They will be nil if the model is of the other
    * type. The property theWord always returns a DubsarModelsWord reference
    * if an appropriate model is present. If model is nil, or if a different
    * model type is incorrectly assigned, theWord will be nil. Otherwise, if
    * model is a DubsarModelsSense, theWord will be sense.word; if model is
    * a DubsarModelsWord, theWord will be equal to word.
    */

    var word : DubsarModelsWord? {
    get {
        return model as? DubsarModelsWord
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

    var theWord : DubsarModelsWord? {
    get {
        if (sense) {
            return sense!.word
        }
        return word
    }
    }

    var selectedIndexPath : NSIndexPath = NSIndexPath(forRow: -1, inSection: 0)

    override func viewDidLayoutSubviews() {
        super.viewDidLoad()
        senseTableView.backgroundColor = UIColor.clearColor()
    }

    override func load() {
        if (model && model!.complete) {
            loadComplete(model, withError: nil)
        }
        else if (sense) {
            // NSLog("Loading sense ID %d with word", sense!._id)
            sense!.loadWithWord()
        }
        else {
            word?.loadWithSynsets()
        }
    }

    override func loadComplete(model: DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        if let s = sense {
            NSLog("Load complete for sense ID %d", s._id)
            var index: Int
            for index = 0; index < theWord!.senses.count; ++index  {
                let object: AnyObject = theWord!.senses.objectAtIndex(index)
                if let sense = object as? DubsarModelsSense {
                    if sense._id == s._id {
                        break
                    }
                }
            }
            assert(index < theWord!.senses.count)
            // NSLog("Index of selected row is %d", index)
            selectedIndexPath = NSIndexPath(forRow:index+1, inSection: 0)
            senseTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .Bottom)
        }
        else if let w = word {
            NSLog("Load complete for word ID %d", w._id)
            selectedIndexPath = NSIndexPath(forRow:1, inSection: 0)
            senseTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .None)
        }

        assert(theWord)
        assert(theWord!.complete)

        adjustLayout()
        senseTableView.backgroundColor = theWord!.senses.count % 2 == 1 ? AppConfiguration.backgroundColor : AppConfiguration.alternateBackgroundColor
   }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return theWord && theWord!.complete ? theWord!.senses.count + 1 : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        if !theWord || !theWord!.complete {
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
            cell!.word = theWord
            return cell
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense
        let frame = tableView.bounds

        var cell : SenseTableViewCell?
        var selectedRow = selectedIndexPath.indexAtPosition(1)

        if selectedRow == row {
            var openCell = tableView.dequeueReusableCellWithIdentifier(OpenSenseTableViewCell.openIdentifier) as? OpenSenseTableViewCell
            if !openCell {
                openCell = OpenSenseTableViewCell(sense: sense, frame: frame, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row))
            }
            else {
                openCell!.insertHeightLimit = maxHeightOfAdditionsForRow(row)
            }
            openCell!.cellBackgroundColor = AppConfiguration.highlightColor
            // NSLog("Cell for row %d is open", row)
            cell = openCell
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(SenseTableViewCell.identifier) as? SenseTableViewCell
            if !cell {
                cell = SenseTableViewCell(sense: sense, frame: frame)
            }
            // NSLog("Cell for row %d is closed", row)
            cell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor
        }

        cell!.frame = frame
        cell!.sense = sense

        return cell
    }

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if !theWord || !theWord!.complete {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            return theWord!.sizeOfCellWithConstrainedSize(tableView.bounds.size, open: false, maxHeightOfAdditions: 0).height
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense

        let constrainedSize = CGSizeMake(tableView.bounds.size.width-2*SenseTableViewCell.borderWidth-2*SenseTableViewCell.margin-SenseTableViewCell.accessoryWidth, tableView.bounds.size.height)
        var selectedRow :Int = selectedIndexPath.indexAtPosition(1)
        let height = sense.sizeOfCellWithConstrainedSize(constrainedSize, open: row == selectedRow, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row)).height

        // NSLog("Height of row %d with row %d selected: %f", row, selectedRow, height)
        return height
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        if indexPath == selectedIndexPath {
            NSLog("row %d reselected, ignoring", indexPath.row)
            return
        }

        let current = selectedIndexPath

        selectedIndexPath = indexPath

        // NSLog("Selected row %d", selectedIndexPath.indexAtPosition(1))
        tableView.reloadRowsAtIndexPaths([current, indexPath], withRowAnimation: .Automatic)
    }

    func tableView(tableView: UITableView!, shouldHighlightRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return indexPath != selectedIndexPath
    }

    func tableView(tableView: UITableView!, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath!) {
        if !theWord || !theWord!.complete {
            return
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            return
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense
        /*
         * This sense model may already be complete from an earlier load, but without the synset. Force a reload
         * here.
         */
        let newSense = DubsarModelsSense(id: sense._id, name: sense.name, partOfSpeech: sense.partOfSpeech)
        pushViewControllerWithIdentifier(SynsetViewController.identifier, model: newSense)
    }

    func maxHeightOfAdditionsForRow(row: Int) -> CGFloat {
        return row == theWord!.senses.count ? senseTableView.bounds.size.height : 150
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

    override func setupToolbar() {
        let string : String? = title
        if string {
            // not yet set in an ordinary word view. need a better way to distinguish this.
            return
        }

        addHomeButton()
    }

}
