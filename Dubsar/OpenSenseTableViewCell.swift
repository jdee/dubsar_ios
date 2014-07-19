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

class OpenSenseTableViewCell: SenseTableViewCell {

    class var openIdentifier : String {
        get {
            return "opensense"
        }
    }

    init(sense: DubsarModelsSense!, frame: CGRect) {
        super.init(sense: sense, frame: frame, identifier: OpenSenseTableViewCell.openIdentifier)
    }

    override func rebuild() {
        super.rebuild()

        let borderWidth = SenseTableViewCell.borderWidth
        let margin = SenseTableViewCell.margin
        let accessoryWidth = SenseTableViewCell.accessoryWidth

        let constrainedSize = CGSizeMake(frame.size.width-2*borderWidth-2*margin-SenseTableViewCell.accessoryWidth, frame.size.height)

        let y = bounds.size.height

        let sampleView = SynsetSampleView(synset: sense.synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, bounds.size.height))
        sampleView.sense = sense
        backgroundLabel.addSubview(sampleView)
        sampleView.layoutSubviews()

        backgroundColor = sampleView.backgroundColor
        frame.size.height += sampleView.bounds.size.height

        NSLog("sample view height is %f. frame height is now %f", sampleView.bounds.size.height, frame.size.height)
    }

}
