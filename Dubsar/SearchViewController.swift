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

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DubsarModelsLoadDelegate {

    @IBOutlet var searchLabel : UILabel
    @IBOutlet var resultTableView : UITableView

    class var identifier : String {
        get {
            return "Search"
        }
    }

    var search : DubsarModelsSearch! {
    didSet {
        search.delegate = self
    }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "adjustLayout", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !search.complete {
            search.load()
        }
        else {
            loadComplete(search, withError: nil)
        }

        searchLabel.text = search.term
        adjustLayout()
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

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier("Word") as WordViewController
        viewController.word = word

        AppDelegate.instance.navigationController.pushViewController(viewController, animated: true)
    }

    func loadComplete(model : DubsarModelsModel!, withError error: String?) {
        if let errorMessage = error {
            NSLog("error: %@", errorMessage)
            return
        }

        resultTableView.reloadData()
    }

    func adjustLayout() {
        searchLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        resultTableView.reloadData()
        view.invalidateIntrinsicContentSize()
    }
}
