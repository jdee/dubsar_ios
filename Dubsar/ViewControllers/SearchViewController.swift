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

    var search : DubsarModelsSearch! {
    get {
        return model as? DubsarModelsSearch
    }

    set {
        model = newValue
    }
    }

    override func viewWillAppear(animated: Bool) {
        // NSLog("In SearchViewController.viewWillAppear() before super: search is %@nil, %@complete; model is %@nil, %@complete", (search ? "" : "not "), (search.complete ? "" : "not "), (model ? "" : "not "), (model?.complete ? "" : "not "))
        super.viewWillAppear(animated)

        title = "Search"
        updateTitle()
        pageControl.hidden = search.totalPages <= 1
    }

    @IBAction
    func pageChanged(sender: UIPageControl) {
        search.currentPage = sender.currentPage + 1
        search.complete = false
        search.load()
        resultTableView.reloadData()
    }

    func updateTitle() {
        var title = "search results for \"\(search.title ? search.title : search.term)\""
        if search.totalPages > 1 {
            title = "\(title) p. \(search.currentPage)/\(search.totalPages)"
        }
        searchLabel.text = title
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section:Int) -> Int {
        return search.complete && search.results.count > 0 ? search.results.count : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        if !search.complete {
            var cell = tableView.dequeueReusableCellWithIdentifier(LoadingTableViewCell.identifier) as? LoadingTableViewCell
            if !cell {
                cell = LoadingTableViewCell()
            }
            return cell
        }

        if search.results.count == 0 {
            let identifier = "no-results"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? UITableViewCell
            if !cell {
                cell = UITableViewCell(style: .Default, reuseIdentifier: identifier)
                cell!.selectionStyle = .None
                cell!.textLabel.text = "search found no matches"
                cell!.textLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            }
            return cell
        }

        let row = indexPath.indexAtPosition(1)
        let word = search.results[row] as DubsarModelsWord

        var cell = tableView.dequeueReusableCellWithIdentifier(WordTableViewCell.identifier) as? WordTableViewCell
        if !cell {
            cell = WordTableViewCell()
        }
        cell!.selectionStyle = .Blue // but gray for some reason
        cell!.accessoryType = .DetailDisclosureButton
        cell!.frame = tableView.bounds
        cell!.word = word
        cell!.cellBackgroundColor = row % 2 == 1 ? UIColor.lightGrayColor() : UIColor.whiteColor()

        return cell
    }

    func tableView(tableView: UITableView!, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath!) {
        if !search.complete || search.results.count == 0 {
            return
        }

        let row = indexPath.indexAtPosition(1)
        let word = search.results[row] as DubsarModelsWord

        pushViewControllerWithIdentifier(WordViewController.identifier, model: word)
    }

    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if !search.complete || search.results.count == 0 {
            return 44
        }

        let row = indexPath.indexAtPosition(1)
        let word = search.results[row] as DubsarModelsWord

        return word.sizeOfCellWithConstrainedSize(resultTableView.bounds.size).height
    }

    override func loadComplete(model : DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        pageControl.hidden = search.totalPages <= 1
        pageControl.currentPage = search.currentPage - 1
        pageControl.numberOfPages = Int(search.totalPages)
        updateTitle()
        resultTableView.reloadData()
    }

    override func adjustLayout() {
        searchLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        resultTableView.reloadData()
        super.adjustLayout()
    }
}
