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

class OpenWordTableViewCell: WordTableViewCell {
    var insertHeightLimit : CGFloat

    class var openIdentifier : String {
        get {
            return "openword"
    }
    }

    init(word: DubsarModelsWord!, frame: CGRect, maxHeightOfAdditions: CGFloat) {
        insertHeightLimit = maxHeightOfAdditions
        super.init(word: word)
        clipsToBounds = true
        self.frame = frame
        selectionStyle = .None
        rebuild() // after frame set
    }

    override func rebuild() {
        super.rebuild()

        let y = bounds.size.height
        backgroundColor = cellBackgroundColor

        // NSLog("Word header height %f for open word cell", Double(y))

        assert(word)
        assert(word!.senses)
        let sense = word!.senses.firstObject as DubsarModelsSense
        let openSenseCell = OpenSenseTableViewCell(sense: sense, frame: CGRectMake(0, y, bounds.size.width, bounds.size.height-y), maxHeightOfAdditions: insertHeightLimit)
        openSenseCell.cellBackgroundColor = cellBackgroundColor

        let openSenseView: UIView! = openSenseCell.view
        openSenseView.frame.origin.x = 0
        openSenseView.frame.origin.y = y
        openSenseView.frame.size.height = openSenseCell.bounds.size.height
        openSenseView.clipsToBounds = true
        openSenseView.backgroundColor = cellBackgroundColor

        openSenseView.removeFromSuperview() // remove this nicely built view from the dummy cell's contentView
        view!.addSubview(openSenseView)

        // NSLog("Open sense view height %f", Double(openSenseView.bounds.size.height))
        frame.size.height += openSenseView.bounds.size.height
        // NSLog("Overall frame height %f", Double(frame.size.height))
    }
}
