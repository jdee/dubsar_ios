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

class SearchViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var searchLabel : UILabel!
    @IBOutlet var resultTableView : UITableView!
    @IBOutlet var pageControl : UIPageControl!

    class var identifier : String {
        get {
            return "Search"
        }
    }

    var search: DubsarModelsSearch?
    var selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)

    override func viewWillAppear(animated: Bool) {
        // DMLOG("In SearchViewController.viewWillAppear() before super: search is %@nil, %@complete; model is %@nil, %@complete", (search ? "" : "not "), (search.complete ? "" : "not "), (model ? "" : "not "), (model?.complete ? "" : "not "))
        super.viewWillAppear(animated)

        title = "Search"
        updateTitle()
        pageControl.hidden = !search || search!.totalPages <= 1
        view.backgroundColor = AppConfiguration.alternateBackgroundColor
        resultTableView.backgroundColor = UIColor.clearColor()
    }

    @IBAction
    func pageChanged(sender: UIPageControl) {
        search!.currentPage = sender.currentPage + 1
        search!.complete = false
        self.router = Router(viewController: self, model: search)
        self.router!.routerAction = .UpdateView
        self.router!.load()

        selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)

        updateTitle()
        resultTableView.reloadData()
    }

    func updateTitle() {
        if !search || !search!.complete {
            searchLabel.text = "searching..."
            return
        }

        let scopeName = DubsarModelsSearchScope.Words == search!.scope ? "word" : "synset"
        var title = "\(scopeName) results for \"\(search!.title ? search!.title : search!.term)\""
        if search!.totalPages > 1 {
            title = "\(title) p. \(search!.currentPage)/\(search!.totalPages)"
        }
        searchLabel.text = title
    }

    func maxHeightOfAdditionsForRow(row: Int) -> CGFloat {
        return row == search!.results.count - 1 ? resultTableView.bounds.size.height : 150
    }

    func tableView(tableView: UITableView!, shouldHighlightRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return indexPath != selectedIndexPath
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section:Int) -> Int {
        return search && search!.complete && search!.results.count > 0 ? search!.results.count : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        if !search || !search!.complete {
            var cell = tableView.dequeueReusableCellWithIdentifier(LoadingTableViewCell.identifier) as? LoadingTableViewCell
            if !cell {
                cell = LoadingTableViewCell()
            }
            cell!.spinner.activityIndicatorViewStyle = AppConfiguration.activityIndicatorViewStyle

            return cell
        }

        if search!.results.count == 0 {
            let identifier = "no-results"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
            if !cell {
                cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
                cell!.selectionStyle = .None
                cell!.textLabel.text = "search found no matches"
                cell!.textLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
            }
            return cell
        }

        let row = indexPath.indexAtPosition(1)
        let selectedRow = selectedIndexPath.indexAtPosition(1)

        var cell: UITableViewCell?

        switch (search!.scope) {
        case .Words:
            let word = search!.results[row] as DubsarModelsWord
            var wordCell: WordTableViewCell?

            if selectedRow == row {
                var openCell = tableView.dequeueReusableCellWithIdentifier(OpenWordTableViewCell.openIdentifier) as? OpenWordTableViewCell
                if !openCell {
                    openCell = OpenWordTableViewCell(word: word, frame: tableView.bounds, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row))
                }
                openCell!.cellBackgroundColor = AppConfiguration.highlightColor
                wordCell = openCell
                cell = openCell
            }
            else {
                wordCell = tableView.dequeueReusableCellWithIdentifier(WordTableViewCell.identifier) as? WordTableViewCell
                if !wordCell {
                    wordCell = WordTableViewCell(word: word, preview: true)
                }
                wordCell!.selectionStyle = .Blue // but gray for some reason
                wordCell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor
                cell = wordCell
            }

            wordCell!.accessoryType = .DetailDisclosureButton
            wordCell!.frame = tableView.bounds
            wordCell!.isPreview = true
            wordCell!.word = word
            wordCell!.rebuild()
            
        case .Synsets:
            let synset = search!.results[row] as DubsarModelsSynset

            var synsetCell = tableView.dequeueReusableCellWithIdentifier(SynsetTableViewCell.identifier) as? SynsetTableViewCell
            if !synsetCell {
                synsetCell = SynsetTableViewCell(synset: synset, frame: tableView.bounds, identifier: SynsetTableViewCell.identifier)
            }
            else {
                synsetCell!.synset = synset
                synsetCell!.frame = tableView.bounds
            }

            synsetCell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor
            cell = synsetCell
        }

        DMTRACE("Height of cell at row %\(row): \(cell!.bounds.size.height)")

        return cell
    }

    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        if indexPath == selectedIndexPath {
            // DMLOG("row %d reselected, ignoring", indexPath.row)
            return
        }

        let current = selectedIndexPath

        selectedIndexPath = indexPath

        synchSelectedRow()

        // DMLOG("Selected row %d", selectedIndexPath.indexAtPosition(1))
        dispatch_async(dispatch_get_main_queue()) {
            tableView.reloadRowsAtIndexPaths([current, indexPath], withRowAnimation: .Automatic)
            tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Bottom)
        }
    }

    func tableView(tableView: UITableView!, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath!) {
        if !search || !search!.complete || search!.results.count == 0 {
            return
        }

        let row = indexPath.indexAtPosition(1)

        switch search!.scope {
        case .Words:
            let word = search!.results[row] as DubsarModelsWord
            pushViewControllerWithIdentifier(WordViewController.identifier, model: word, routerAction: .UpdateView)

        case .Synsets:
            let synset = search!.results[row] as DubsarModelsSynset
            pushViewControllerWithIdentifier(SynsetViewController.identifier, model: synset, routerAction: .UpdateView)
        }
    }

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if !search || !search!.complete || search!.results.count == 0 {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        let selectedRow = selectedIndexPath.indexAtPosition(1)

        var height: CGFloat
        switch search!.scope {
        case .Words:
            let word = search!.results[row] as DubsarModelsWord
            height = word.sizeOfCellWithConstrainedSize(resultTableView.bounds.size, open: selectedRow == row, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row), preview: true).height
        default:
            let synset = search!.results[row] as DubsarModelsSynset
            height = synset.sizeOfCellWithConstrainedSize(resultTableView.bounds.size, open: false, maxHeightOfAdditions: 0).height
        }

        DMTRACE("Height of row \(row): \(height)")
        return height
    }

    func synchSelectedRow() {
        let row = selectedIndexPath.indexAtPosition(1)
        if row < 0 || !search || search!.scope == .Synsets {
            // DMLOG("Can't synch row %d", row)
            return
        }

        let word = search!.results[row] as DubsarModelsWord
        if word.complete {
            // DMLOG("Word %@ already complete", word.nameAndPos)
            return
        }

        self.router = Router(viewController: self, model: word)
        self.router!.routerAction = .UpdateRowAtIndexPath
        self.router!.indexPath = selectedIndexPath
        self.router!.load()
        DMTRACE("Synching selected row")
    }

    func selectRowForWord(word: DubsarModelsWord!) {
        let results = search!.results as [AnyObject]
        var index = results.count
        for (j, w) in enumerate(results as [DubsarModelsWord]) {
            if w._id == word._id {
                index = j
                break
            }
        }
        assert(index < results.count)

        // DMLOG("Index of selected row is %d", index)
        selectedIndexPath = NSIndexPath(forRow: index, inSection: 0)
    }

    override func routeResponse(router: Router!) {
        super.routeResponse(router)
        if router.model.error {
            return
        }

        switch (router.routerAction) {
        case .UpdateView:
            search = router.model as? DubsarModelsSearch

            if search!.results.count > 0 {
                selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                synchSelectedRow()
                // DMLOG("Sent request to synch row for word");
            }

            resultTableView.reloadData()

        case .UpdateRowAtIndexPath:
            if (router.indexPath != selectedIndexPath) {
                return
            }

            let word = router.model as? DubsarModelsWord
            let row = selectedIndexPath.indexAtPosition(1)
            if word {
                let resultWord = search!.results[row] as? DubsarModelsWord
                assert(word && resultWord && word === resultWord)

                assert(search && search!.complete && search!.results.count > 0)

                let firstSense = word!.senses.firstObject as DubsarModelsSense
                if !firstSense.complete {
                    self.router = Router(viewController: self, model: firstSense)
                    self.router!.routerAction = .UpdateRowAtIndexPath
                    self.router!.indexPath = selectedIndexPath
                    self.router!.load()
                    // DMLOG("Sent request to synch first sense in open word cell")
                }
            }
            else {
                // DMLOG("Got response for first sense in open word cell")
            }

            resultTableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            resultTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: router.routerAction != RouterAction.UpdateView ? .Bottom : .None)
            return

        default:
            break
        }

        pageControl.hidden = search!.totalPages <= 1
        pageControl.currentPage = search!.currentPage - 1
        pageControl.numberOfPages = Int(search!.totalPages)
        updateTitle()

        resultTableView.backgroundColor = search!.results.count % 2 == 0 ? AppConfiguration.backgroundColor : AppConfiguration.alternateBackgroundColor
    }

    override func adjustLayout() {
        searchLabel.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        searchLabel.textColor = AppConfiguration.foregroundColor

        pageControl.pageIndicatorTintColor = AppConfiguration.alternateHighlightColor
        pageControl.currentPageIndicatorTintColor = AppConfiguration.foregroundColor

        resultTableView.reloadData()
        super.adjustLayout()
    }
}
