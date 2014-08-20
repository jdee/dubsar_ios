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

    private var favoriteButton: FavoriteBarButtonItem!

    private var url: NSURL {
    get {
        return NSURL(string: "dubsar:///words/\(theWord!._id)")
    }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        case .UpdateRowAtIndexPath: // we get here as a result of calling synchSelectedRow()
            assert(theWord != nil)

            assert(router.indexPath == selectedIndexPath)

            let sense = router.model as? DubsarModelsSense
            let row = selectedIndexPath.indexAtPosition(1)
            let wordSense = theWord!.senses[row-1] as? DubsarModelsSense

            assert(sense != nil && wordSense != nil && sense === wordSense)

            // DMLOG("Received response for sense %d (%@). Updating row %d", sense!._id, sense!.gloss, row)

            senseTableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            senseTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: row == theWord!.senses.count ? .Top : .Bottom)
            return

        case .UpdateViewWithDependency:
            theWord = router.model as? DubsarModelsWord
            selectRowForSense(router.dependency)

        default:
            break
        }

        synchSelectedRow()
        adjustLayout()
        senseTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: router.routerAction == RouterAction.UpdateViewWithDependency ? selectedIndexPath.indexAtPosition(1) == theWord!.senses.count ? .Top : .Bottom : .None)
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

        // DMLOG("Index of selected row is %d", index)
        selectedIndexPath = NSIndexPath(forRow: index+1, inSection: 0)
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return theWord != nil && theWord!.complete ? theWord!.senses.count + 1 : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        if theWord == nil || !theWord!.complete {
            var cell = tableView.dequeueReusableCellWithIdentifier(LoadingTableViewCell.identifier) as? LoadingTableViewCell
            if cell == nil {
                cell = LoadingTableViewCell()
            }
            return cell
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            // Word cell as the header
            let identifier = "word-without-accessory"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? WordTableViewCell
            if cell == nil {
                cell = WordTableViewCell(word: theWord, preview: false, reuseIdentifier: identifier)
            }
            cell!.frame = tableView.bounds
            cell!.isPreview = false
            cell!.word = theWord
            cell!.rebuild()

            // DMLOG("Height of word cell at row 0: %f", Double(cell!.bounds.size.height))
            return cell
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense
        let frame = tableView.bounds

        var cell : SenseTableViewCell?
        var selectedRow = selectedIndexPath.indexAtPosition(1)

        if selectedRow == row {
            let identifier = OpenSenseTableViewCell.openIdentifier
            var openCell = tableView.dequeueReusableCellWithIdentifier(identifier) as? OpenSenseTableViewCell
            if openCell == nil {
                openCell = OpenSenseTableViewCell(sense: sense, frame: frame, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row))
            }
            else {
                openCell!.insertHeightLimit = maxHeightOfAdditionsForRow(row)
            }
            openCell!.cellBackgroundColor = AppConfiguration.highlightColor // calls rebuild()
            DMTRACE("Cell for row \(row) is open")
            cell = openCell
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(SenseTableViewCell.identifier) as? SenseTableViewCell
            if cell == nil {
                cell = SenseTableViewCell(sense: sense, frame: frame)
            }
            DMTRACE("Cell for row \(row) is closed")
            cell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor // calls rebuild()
        }

        cell!.frame = frame
        cell!.sense = sense
        cell!.rebuild()

        DMTRACE("Height of cell at row \(row) with row \(selectedRow) selected: \(cell!.bounds.size.height)")
        DMTRACE("Cell width: \(cell!.bounds.size.width). contentView width: \(cell!.contentView.bounds.size.width). view width: \((cell! as SenseTableViewCell).view!.bounds.size.width).")

        return cell
    }

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if theWord == nil || !theWord!.complete {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            let height = theWord!.sizeOfCellWithConstrainedSize(tableView.bounds.size, open: false, maxHeightOfAdditions: 0, preview: false).height
            // DMLOG("Height of row 0 (word header): %f", Double(height))
            return height
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense

        var selectedRow :Int = selectedIndexPath.indexAtPosition(1)
        let height = sense.sizeOfCellWithConstrainedSize(tableView.bounds.size, open: row == selectedRow, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row)).height

        DMTRACE("Height of row \(row) with row \(selectedRow) selected: \(height)")
        return height
    }

    func tableView(tableView: UITableView!, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if theWord == nil || !theWord!.complete {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            let height = theWord!.estimatedHeightOfCell(tableView.bounds.size, open: false, maxHeightOfAdditions: 0, preview: false)
            DMTRACE("Estimated height of row 0 (word header): \(height)")
            return height
        }

        let sense = theWord!.senses[row-1] as DubsarModelsSense

        var selectedRow :Int = selectedIndexPath.indexAtPosition(1)
        let height = sense.estimatedHeightOfCell(tableView.bounds.size, open: row == selectedRow, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row))

        DMTRACE("estimated Height of row \(row) with row \(selectedRow) selected: \(height)")
        return height
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        // DMLOG("Selected row is %d", selectedIndexPath.indexAtPosition(1))
        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            return
        }

        if indexPath == selectedIndexPath {
            // DMLOG("row %d reselected, ignoring", indexPath.indexAtPosition(1))
            return
        }

        // DMLOG("Selected new row %d", row)

        let current = selectedIndexPath

        selectedIndexPath = indexPath

        synchSelectedRow()

        // DMLOG("Reloading rows %d & %d", row, current.indexAtPosition(1))

        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in

            if let my = self {
                tableView.reloadRowsAtIndexPaths([current, indexPath], withRowAnimation: .Automatic)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: my.theWord!.senses.count == indexPath.indexAtPosition(1) ? .Top : .Bottom)
            }
        }
    }

    func tableView(tableView: UITableView!, shouldHighlightRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        let row = indexPath.indexAtPosition(1)
        return row != 0 && indexPath != selectedIndexPath
    }

    func tableView(tableView: UITableView!, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath!) {
        if theWord == nil || !theWord!.complete {
            return
        }

        let row = indexPath.indexAtPosition(1)
        if row == 0 {
            return
        }


        assert(row <= theWord!.senses.count)

        let sense = theWord!.senses[row-1] as? DubsarModelsSense
        assert(sense != nil)
        assert(sense!.synset != nil)
        pushViewControllerWithIdentifier(SynsetViewController.identifier, model: sense, routerAction: .UpdateViewWithDependency)
    }

    func maxHeightOfAdditionsForRow(row: Int) -> CGFloat {
        return row == theWord!.senses.count ? 0 : 150 // 0: unlimited
    }

    func synchSelectedRow() {
        let row = selectedIndexPath.indexAtPosition(1)
        if row < 1 || theWord == nil {
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

    func favoriteTapped(sender: FavoriteBarButtonItem!) {
        let bookmark = Bookmark(url:url)
        bookmark.label = theWord!.nameAndPos

        favoriteButton.selected = AppDelegate.instance.bookmarkManager.toggleBookmark(bookmark)
    }

    override func adjustLayout() {
        if !loaded || view == nil {
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
        DMTRACE("Setting up toolbar for word view")

        navigationItem.rightBarButtonItems = []

        super.setupToolbar()

        if theWord != nil {
            var items = navigationItem.rightBarButtonItems as [UIBarButtonItem]
            favoriteButton = FavoriteBarButtonItem(target:self, action:"favoriteTapped:")
            favoriteButton.selected = theWord != nil && AppDelegate.instance.bookmarkManager.isUrlBookmarked(url)

            // need to break up super.setToolbar, so that I can make the buttons in the right order.
            if items.count == 1 {
                navigationItem.rightBarButtonItems = [ favoriteButton, items[0] ]
            }
            else {
                navigationItem.rightBarButtonItem = favoriteButton
            }
        }
    }

}
