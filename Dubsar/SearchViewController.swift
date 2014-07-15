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

    @IBOutlet var searchLabel : UILabel
    @IBOutlet var resultTableView : UITableView

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

        searchLabel.text = search.term
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section:Int) -> Int {
        return search.complete ? search.results.count : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        if !search.complete {
            var cell = tableView.dequeueReusableCellWithIdentifier(LoadingTableViewCell.identifier) as? LoadingTableViewCell
            if !cell {
                cell = LoadingTableViewCell()
            }
            return cell
        }

        let row = indexPath.indexAtPosition(1)
        let word = search.results[row] as DubsarModelsWord

        var cell = tableView.dequeueReusableCellWithIdentifier(WordTableViewCell.identifer) as? WordTableViewCell
        if !cell {
            cell = WordTableViewCell()
        }
        cell!.word = word

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !search.complete {
            return
        }

        let row = indexPath.indexAtPosition(1)
        let word = search.results[row] as DubsarModelsWord

        pushViewControllerWithIdentifier(WordViewController.identifier, model: word)
    }

    override func loadComplete(model : DubsarModelsModel!, withError error: String?) {
        super.loadComplete(model, withError: error)
        if error {
            return
        }

        resultTableView.reloadData()
    }

    override func adjustLayout() {
        searchLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        resultTableView.reloadData()
        super.adjustLayout()
    }
}
