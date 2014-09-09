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

class SearchViewController: SearchBarViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var resultTableView : UITableView!
    @IBOutlet var pageControl : UIPageControl!

    class var identifier : String {
        get {
            return "Search"
        }
    }

    var search: DubsarModelsSearch?
    var selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.layer.shadowOpacity = 1
    }

    override func viewWillAppear(animated: Bool) {
        // DMLOG("In SearchViewController.viewWillAppear() before super: search is %@nil, %@complete; model is %@nil, %@complete", (search ? "" : "not "), (search.complete ? "" : "not "), (model ? "" : "not "), (model?.complete ? "" : "not "))
        super.viewWillAppear(animated)

        if let s = search {
            searchBar.selectedScopeButtonIndex = s.scope == .Words ? 0 : 1
        }

        title = "Search"
        updateTitle()
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

    @IBAction
    func scopeChanged(sender: UISegmentedControl!) {
        let scope = sender.selectedSegmentIndex == 0 ? DubsarModelsSearchScope.Words : DubsarModelsSearchScope.Synsets

        search!.scope = scope
        search!.currentPage = 1
        search!.complete = false

        self.router = Router(viewController: self, model: search)
        self.router!.routerAction = .UpdateView
        self.router!.load()

        selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)

        updateTitle()
        resultTableView.reloadData()
    }

    func updateTitle() {
        var newTitle = "Search"
        if search != nil {
            if !searchBarEditing {
                searchBar.text = search!.term
            }

            if search!.totalPages > 1 {
            newTitle = "\(newTitle) p. \(search!.currentPage)/\(search!.totalPages)"
        }
        }
        title = newTitle
    }

    func maxHeightOfAdditionsForRow(row: Int) -> CGFloat {
        return row == search!.results.count - 1 ? 0 : 150 // 0: unlimited
    }

    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        bookmarkListView.hidden = true

        return indexPath != selectedIndexPath
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return search != nil && search!.complete && search!.results.count > 0 ? search!.results.count : 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        if search == nil || !search!.complete {
            var cell = tableView.dequeueReusableCellWithIdentifier(LoadingTableViewCell.identifier) as? LoadingTableViewCell
            if cell == nil {
                cell = LoadingTableViewCell()
            }
            cell!.spinner.activityIndicatorViewStyle = AppConfiguration.activityIndicatorViewStyle

            return cell!
        }

        if search!.results.count == 0 {
            let identifier = "no-results"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
            if cell == nil {
                cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
                cell!.selectionStyle = .None
                cell!.textLabel!.text = "search found no matches"
                cell!.textLabel!.font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
            }
            return cell!
        }

        let row = indexPath.indexAtPosition(1)
        let selectedRow = selectedIndexPath.indexAtPosition(1)

        var cell: UITableViewCell?

        let result = search!.results[row] as DubsarModelsModel

        if let word = result as? DubsarModelsWord {
            var wordCell: WordTableViewCell?

            if selectedRow == row {
                var openCell = tableView.dequeueReusableCellWithIdentifier(OpenWordTableViewCell.openIdentifier) as? OpenWordTableViewCell
                let maxForRow = maxHeightOfAdditionsForRow(row)
                if openCell == nil {
                    openCell = OpenWordTableViewCell(word: word, frame: tableView.bounds, maxHeightOfAdditions: maxForRow)
                }
                openCell!.insertHeightLimit = maxForRow
                openCell!.cellBackgroundColor = AppConfiguration.highlightColor
                wordCell = openCell
                cell = openCell
            }
            else {
                wordCell = tableView.dequeueReusableCellWithIdentifier(WordTableViewCell.identifier) as? WordTableViewCell
                if wordCell == nil {
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
            DMTRACE("Cell width: \(cell!.bounds.size.width). contentView width: \(cell!.contentView.bounds.size.width). view width: \(wordCell!.view!.bounds.size.width).")
        }
        else if let synset = result as? DubsarModelsSynset {
            var synsetCell: SynsetTableViewCell?

            if selectedRow == row {
                var openCell = tableView.dequeueReusableCellWithIdentifier(OpenSynsetTableViewCell.openSynsetIdentifier) as? OpenSynsetTableViewCell
                let maxForRow = maxHeightOfAdditionsForRow(row)
                if openCell == nil {
                    openCell = OpenSynsetTableViewCell(synset: synset, frame: tableView.bounds, maxHeightOfAdditions: maxForRow)
                }
                else {
                    openCell!.insertHeightLimit = maxForRow
                    openCell!.synset = synset
                    openCell!.frame = tableView.bounds
                }
                openCell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor
                openCell!.rebuild()
                cell = openCell
            }
            else {
                synsetCell = tableView.dequeueReusableCellWithIdentifier(SynsetTableViewCell.synsetIdentifier) as? SynsetTableViewCell
                if synsetCell == nil {
                    synsetCell = SynsetTableViewCell(synset: synset, frame: tableView.bounds)
                }
                else {
                    synsetCell!.synset = synset
                    synsetCell!.frame = tableView.bounds
                }
                synsetCell!.cellBackgroundColor = row % 2 == 1 ? AppConfiguration.alternateBackgroundColor : AppConfiguration.backgroundColor
                synsetCell!.rebuild()
                cell = synsetCell
            }
        }

        DMTRACE("Height of cell at row \(row): \(cell!.bounds.size.height)")
        if row == 0 {
            DMTRACE("row 0")
        }

        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        bookmarkListView.hidden = true

        if indexPath == selectedIndexPath {
            // DMLOG("row %d reselected, ignoring", indexPath.row)
            return
        }

        let current = selectedIndexPath

        selectedIndexPath = indexPath

        synchSelectedRow()

        // DMLOG("Selected row %d", selectedIndexPath.indexAtPosition(1))
        dispatch_async(dispatch_get_main_queue()) {
            [weak self] in

            if let my = self {
                tableView.reloadRowsAtIndexPaths([current, indexPath], withRowAnimation: .Automatic)
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: my.search!.results.count - 1 == indexPath.indexAtPosition(1) ? .Top : .Bottom)
            }
        }
    }

    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        bookmarkListView.hidden = true

        if search == nil || !search!.complete || search!.results.count == 0 {
            return
        }

        let row = indexPath.indexAtPosition(1)

        let result = search!.results[row] as DubsarModelsModel

        if let word = result as? DubsarModelsWord {
            pushViewControllerWithIdentifier(WordViewController.identifier, model: word, routerAction: .UpdateView)
        }
        else if let synset = result as? DubsarModelsSynset {
            pushViewControllerWithIdentifier(SynsetViewController.identifier, model: synset, routerAction: .UpdateView)
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if search == nil || !search!.complete || search!.results.count == 0 {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        let selectedRow = selectedIndexPath.indexAtPosition(1)

        let result = search!.results[row] as DubsarModelsModel

        var height: CGFloat = 0.0
        if let word = result as? DubsarModelsWord {
            height = word.sizeOfCellWithConstrainedSize(resultTableView.bounds.size, open: selectedRow == row, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row), preview: true).height
        }
        else if let synset = result as? DubsarModelsSynset {
            height = synset.sizeOfCellWithConstrainedSize(resultTableView.bounds.size, open: selectedRow == row, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row)).height
        }

        if row == search!.results.count - 1 && search!.totalPages > 1 {
            height += pageControl.bounds.size.height
        }

        DMTRACE("Height of row \(row): \(height)")
        return height
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if search == nil || !search!.complete || search!.results.count == 0 {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        let selectedRow = selectedIndexPath.indexAtPosition(1)

        let result = search!.results[row] as DubsarModelsModel

        var height: CGFloat = 0.0
        if let word = result as? DubsarModelsWord {
            height = word.estimatedHeightOfCell(resultTableView.bounds.size, open: selectedRow == row, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row), preview: true)
        }
        else if let synset = result as? DubsarModelsSynset {
            height = synset.estimatedHeightOfCell(resultTableView.bounds.size, open: selectedRow == row, maxHeightOfAdditions: maxHeightOfAdditionsForRow(row))
        }

        DMTRACE("Estimated height of row \(row): \(height)")
        return height
    }

    func synchSelectedRow() {
        let row = selectedIndexPath.indexAtPosition(1)
        if row < 0 || search == nil {
            // DMLOG("Can't synch row %d", row)
            return
        }

        let result = search!.results[row] as DubsarModelsModel
        if result.complete {
            return
        }

        self.router = Router(viewController: self, model: result)

        self.router!.routerAction = .UpdateRowAtIndexPath
        self.router!.indexPath = selectedIndexPath
        self.router!.load()
        DMTRACE("Synching selected row")
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
                DMTRACE("Sent request to synch row for word");
            }

            resultTableView.reloadData()

        case .UpdateRowAtIndexPath:
            if (router.indexPath != selectedIndexPath) {
                return
            }

            let row = selectedIndexPath.indexAtPosition(1)

            if let word = router.model as? DubsarModelsWord {
                let resultWord = search!.results[row] as? DubsarModelsWord
                assert(resultWord != nil && word === resultWord)

                assert(search != nil && search!.complete && search!.results.count > 0)

                let firstSense = word.senses.firstObject as DubsarModelsSense
                if !firstSense.complete {
                    self.router = Router(viewController: self, model: firstSense)
                    self.router!.routerAction = .UpdateRowAtIndexPath
                    self.router!.indexPath = selectedIndexPath
                    self.router!.load()
                    DMTRACE("Sent request to synch first sense in open word cell")
                }
            }
            else if let synset = router.model as? DubsarModelsSynset {
                let resultSynset = search!.results[row] as? DubsarModelsSynset
                assert(resultSynset != nil && synset === resultSynset)

                assert(search != nil && search!.complete && search!.results.count > 0)

                let firstSense = synset.senses.firstObject as DubsarModelsSense
                if !firstSense.complete {
                    self.router = Router(viewController: self, model: firstSense)
                    self.router!.routerAction = .UpdateRowAtIndexPath
                    self.router!.indexPath = selectedIndexPath
                    self.router!.load()
                    DMTRACE("Sent request to synch first sense in open synset cell")
                }
            }
            else {
                DMTRACE("Got response for first sense in open cell")
            }

            resultTableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            resultTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: router.routerAction != RouterAction.UpdateView ? search!.results.count - 1 == row ? .Top : .Bottom : .None)
            return

        default:
            break
        }

        searchBar.selectedScopeButtonIndex = search!.scope == .Words ? 0 : 1

        pageControl.hidden = search!.totalPages <= 1
        pageControl.currentPage = search!.currentPage - 1
        pageControl.numberOfPages = Int(search!.totalPages)
        updateTitle()

        updateBackgroundColor()
    }

    override func adjustLayout() {
        pageControl.pageIndicatorTintColor = AppConfiguration.alternateHighlightColor
        pageControl.currentPageIndicatorTintColor = AppConfiguration.foregroundColor
        pageControl.hidden = search == nil || search!.totalPages <= 1

        resultTableView.reloadData()
        view.backgroundColor = AppConfiguration.alternateBackgroundColor
        updateBackgroundColor()

        resultTableView.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .None)

        super.adjustLayout()
    }

    private func updateBackgroundColor() {
        resultTableView.backgroundColor = search != nil && search!.complete && search!.results.count % 2 == 0 ? AppConfiguration.backgroundColor : AppConfiguration.alternateBackgroundColor
    }

    override func newSearch(newSearch: DubsarModelsSearch!) {
        search = newSearch

        self.router = Router(viewController: self, model: search)
        self.router!.routerAction = .UpdateView
        self.router!.load()

        selectedIndexPath = NSIndexPath(forRow: 0, inSection: 0)

        updateTitle()
        resultTableView.reloadData()
    }

    override func searchBar(theSearchBar: UISearchBar!, selectedScopeButtonIndexDidChange selectedScope: Int) {
        // disallow for wild cards (words only)
        if let s = search {
            if s.isWildCard {
                searchBar.selectedScopeButtonIndex = DubsarModelsSearchScope.Words.toRaw()
                DMDEBUG("Wild card search. Forcing words.")
                return
            }
        }

        if let scope = DubsarModelsSearchScope.fromRaw(selectedScope) {
            searchScope = scope

            let enumString = scope == .Words ? "words" : "synsets"
            DMDEBUG("Changed search scope. Selected scope index \(selectedScope). Scope: \(enumString)")
            if !(theSearchBar.text as String).isEmpty {

                if searchBarEditing {
                    triggerAutocompletion()
                }
                else if search != nil {
                    search!.scope = searchScope
                    search!.complete = false
                    search!.currentPage = 1

                    newSearch(search)
                }
            }
        }
    }

    override func resetSearch() {
        super.resetSearch()
        updateTitle()
    }

}
