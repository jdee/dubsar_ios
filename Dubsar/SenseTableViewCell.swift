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

    // essentially public class constants
    class var identifier : String {
        get {
            return "sense"
        }
    }

    class var padding : Float {
        get {
            return 1
    }
    }

    class var margin : Float {
        get {
            return 4
    }
    }

    var sense : DubsarModelsSense {
    didSet {
        resize()
    }
    }

    var view : UIView?

    init(sense: DubsarModelsSense, frame: CGRect) {
        self.sense = sense
        super.init(style: .Default, reuseIdentifier: SenseTableViewCell.identifier)

        self.frame = frame

        resize()
    }

    func resize() {
        let padding = SenseTableViewCell.padding
        let margin = SenseTableViewCell.margin

        let constrainedSize = CGSizeMake(frame.size.width-2*padding-2*margin, frame.size.height-2*padding-2*margin)
        let size = sense.sizeWithConstrainedSize(constrainedSize)

        frame.size.height = size.height + 2*padding + 2*margin

        view?.removeFromSuperview()

        view = UIView(frame: bounds)
        // view!.backgroundColor = UIColor.blackColor()

        addSubview(view)

        let backgroundLabel = UIView(frame: CGRectMake(padding, padding, bounds.size.width-2*padding, bounds.size.height-2*padding))
        backgroundLabel.backgroundColor = UIColor.whiteColor()
        view!.addSubview(backgroundLabel)

        let textLabel = UILabel(frame: CGRectMake(margin, margin, bounds.size.width-2*padding-2*margin, size.height))
        textLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textLabel.text = sense.gloss
        textLabel.lineBreakMode = .ByWordWrapping
        textLabel.numberOfLines = 0
        backgroundLabel.addSubview(textLabel)
    }

}
