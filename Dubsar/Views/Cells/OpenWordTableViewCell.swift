/*
Dubsar Dictionary Project
Copyright (C) 2010-15 Jimmy Dee

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

class OpenWordTableViewCell: WordTableViewCell {
    var insertHeightLimit : CGFloat

    class var openIdentifier : String {
        get {
            return "openword"
    }
    }

    init(word: DubsarModelsWord!, frame: CGRect, maxHeightOfAdditions: CGFloat) {
        insertHeightLimit = maxHeightOfAdditions
        super.init(word: word, preview: true, reuseIdentifier: OpenWordTableViewCell.openIdentifier)
        clipsToBounds = true
        self.frame = frame
        selectionStyle = .None
    }

    required init?(coder aDecoder: NSCoder) {
        insertHeightLimit = 0
        super.init(coder: aDecoder)
    }

    override func rebuild() {
        super.rebuild()

        let y = bounds.size.height
        backgroundColor = cellBackgroundColor

        DMTRACE("Word header height \(y) for open word cell")

        assert(word != nil)

        if !word!.complete {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
            spinner.frame = CGRectMake(2.0, y + 2.0, 40.0, 40.0)
            spinner.startAnimating()
            view!.addSubview(spinner)
            frame.size.height += 44
            return
        }

        assert(word!.senses != nil)

        let sense = word!.senses.firstObject as! DubsarModelsSense
        let openSenseCell = OpenSenseTableViewCell(sense: sense, frame: CGRectMake(0, y, bounds.size.width, bounds.size.height-y), maxHeightOfAdditions: insertHeightLimit)
        openSenseCell.cellBackgroundColor = cellBackgroundColor
        openSenseCell.rebuild()

        let openSenseView: UIView! = openSenseCell.removeView()
        openSenseView.frame.origin.x = 0
        openSenseView.frame.origin.y = y
        openSenseView.frame.size.height = openSenseCell.bounds.size.height
        openSenseView.backgroundColor = cellBackgroundColor

        let lastSubview = (view!.subviews as NSArray).lastObject as! UIView
        // view!.removeConstraint(NSLayoutConstraint(item: lastSubview, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: -WordTableViewCell.margin))

        view!.addSubview(openSenseView)

        DMTRACE("Open sense view height \(openSenseView.bounds.size.height)")
        frame.size.height += openSenseView.bounds.size.height
        DMTRACE("Overall frame height \(frame.size.height)")

        var constraint: NSLayoutConstraint
        constraint = NSLayoutConstraint(item: view!, attribute: .Leading, relatedBy: .Equal, toItem: openSenseView, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Trailing, relatedBy: .Equal, toItem: openSenseView, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Bottom, relatedBy: .Equal, toItem: openSenseView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: lastSubview, attribute: .Bottom, relatedBy: .Equal, toItem: openSenseView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
    }
}
