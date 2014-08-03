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

    var selectedIndexPath : NSIndexPath = NSIndexPath(forRow: -1, inSection: 0)

    var theWord: DubsarModelsWord?

    var loaded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad() // just calls load()

        loaded = true
        senseTableView.backgroundColor = UIColor.clearColor()
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        switch (router.routerAction) {
        case .UpdateView:
            theWord = router.model as? DubsarModelsWord
            selectedIndexPath = NSIndexPath(forRow:1, inSection:0)
            synchSelectedRow()

            senseTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .None)

        case .UpdateRowAtIndexPath: // we get here as a result of calling synchSelectedRow()
            assert(theWord)

            assert(router.indexPath == selectedIndexPath)

            let sense = router.model as? DubsarModelsSense
            let row = selectedIndexPath.indexAtPosition(1)
            let wordSense = theWord!.senses[row-1] as? DubsarModelsSense

            assert(sense && wordSense && sense === wordSense)

            NSLog("Received response for sense %d (%@). Updating row %d", sense!._id, sense!.gloss, row)

            senseTableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)

        case .UpdateViewWithDependency:
            theWord = router.model as? DubsarModelsWord
            selectRowForSense(router.dependency)
            synchSelectedRow()

            senseTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .Bottom)

        default:
            break
        }

        adjustLayout()
        senseTableView.backgroundColor = theWord!.senses.count % 2 == 1 ? AppConfiguration.backgroundColor : AppConfiguration.alternateBackgroundColor
    }

    func selectRowForSense(sense: DubsarModelsSense!) {
        let senses = theWord!.senses as [AnyObject]
        var index = senses.count
        for (j, s) in enumerate(senses as [DubsarModelsSense]) {
            if s._id == sense._id {
                index = j
                break
            }
        }
        assert(index < senses.count)

        // NSLog("Index of selected row is %d", index)
        selectedIndexPath = NSIndexPath(forRow: index+1, inSection: 0)
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
            let identifier = "word-without-accessory"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? WordTableViewCell
            if !cell {
                cell = WordTableViewCell(word: theWord, preview: false, reuseIdentifier: identifier)
            }
            cell!.frame = tableView.bounds
            cell!.isPreview = false
            cell!.word = theWord

            // NSLog("Height of word cell at row 0: %f", Double(cell!.bounds.size.height))
            return cell
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense
        let frame = tableView.bounds

        var cell : SenseTableViewCell?
        var selectedRow = selectedIndexPath.indexAtPosition(1)

        if selectedRow == row {
            let identifier = OpenSenseTableViewCell.openIdentifier
            var openCell = tableView.dequeueReusableCellWithIdentifier(identifier) as? OpenSenseTableViewCell
            if !openCell {
                openCell = OpenSenseTableViewCell(sense: sense, frame: frame, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row))
            }
            else {
                openCell!.insertHeightLimit = maxHeightOfAdditionsForRow(row)
            }
            openCell!.cellBackgroundColor = AppConfiguration.highlightColor // calls rebuild()
            // NSLog("Cell for row %d is open", row)
            cell = openCell
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(SenseTableViewCell.identifier) as? SenseTableViewCell
            if !cell {
                cell = SenseTableViewCell(sense: sense, frame: frame)
            }
            // NSLog("Cell for row %d is closed", row)
            cell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor // calls rebuild()
        }

        cell!.frame = frame
        cell!.sense = sense // calls rebuild()

        return cell
    }

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if !theWord || !theWord!.complete {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            let height = theWord!.sizeOfCellWithConstrainedSize(tableView.bounds.size, open: false, maxHeightOfAdditions: 0, preview: false).height
            // NSLog("Height of row 0 (word header): %f", Double(height))
            return height
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense

        let constrainedSize = CGSizeMake(tableView.bounds.size.width-2*SenseTableViewCell.borderWidth-2*SenseTableViewCell.margin-SenseTableViewCell.accessoryWidth, tableView.bounds.size.height)
        var selectedRow :Int = selectedIndexPath.indexAtPosition(1)
        let height = sense.sizeOfCellWithConstrainedSize(constrainedSize, open: row == selectedRow, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row)).height

        // NSLog("Height of row %d with row %d selected: %f", row, selectedRow, Double(height))
        return height
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // NSLog("Selected row is %d", selectedIndexPath.indexAtPosition(1))
        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            return
        }

        if indexPath == selectedIndexPath {
            NSLog("row %d reselected, ignoring", indexPath.indexAtPosition(1))
            return
        }

        // NSLog("Selected new row %d", row)

        let current = selectedIndexPath

        selectedIndexPath = indexPath

        synchSelectedRow()

        // NSLog("Reloading rows %d & %d", row, current.indexAtPosition(1))

        tableView.reloadRowsAtIndexPaths([current, indexPath], withRowAnimation: .Automatic)
    }

    func tableView(tableView: UITableView!, shouldHighlightRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        let row = indexPath.indexAtPosition(1)
        return row != 0 && indexPath != selectedIndexPath
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
        pushViewControllerWithIdentifier(SynsetViewController.identifier, model: sense, routerAction: .UpdateViewWithDependency)
    }

    func maxHeightOfAdditionsForRow(row: Int) -> CGFloat {
        return row == theWord!.senses.count ? senseTableView.bounds.size.height : 150
    }

    func synchSelectedRow() {
        let row = selectedIndexPath.indexAtPosition(1)
        if row < 1 || !theWord {
            return
        }

        let sense = theWord!.senses[row - 1] as DubsarModelsSense
        if sense.complete {
            return
        }

        self.router = Router(viewController: self, model: sense)
        self.router!.routerAction = .UpdateRowAtIndexPath
        self.router!.indexPath = selectedIndexPath
        self.router!.load()
    }

    override func adjustLayout() {
        if !loaded || !view {
            return
        }

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

        navigationItem.rightBarButtonItems = []

        addHomeButton()
        super.setupToolbar()
    }

}
