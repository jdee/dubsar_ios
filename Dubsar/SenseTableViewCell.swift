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

class SenseTableViewCell: UITableViewCell {

    class var identifier : String {
        get {
            return "sense"
        }
    }

    var sense : DubsarModelsSense {
    didSet {
        resize()
    }
    }

    var label : UILabel?

    init(sense: DubsarModelsSense, frame: CGRect) {
        self.sense = sense
        super.init(style: .Default, reuseIdentifier: SenseTableViewCell.identifier)

        self.frame = frame

        resize()
    }

    func resize() {
        let size = sense.sizeWithConstrainedSize(frame.size)

        frame.size = CGSizeMake(size.width, size.height)

        label?.removeFromSuperview()

        label = UILabel(frame: self.bounds)
        label!.text = sense.gloss
        label!.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label!.lineBreakMode = .ByWordWrapping
        label!.numberOfLines = 0
        addSubview(label)
    }

}
