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

    class var borderWidth : Float {
        get {
            return 0
        }
    }

    class var margin : Float {
        get {
            return 6
        }
    }

    class var labelLineHeight : Float {
        get {
            return 21
        }
    }

    var sense : DubsarModelsSense! {
    didSet {
        rebuild()
    }
    }

    var cellBackgroundColor : UIColor! = UIColor.whiteColor() {
    didSet {
        rebuild()
    }
    }

    /*
     * The main thing this class does is build this view, which is added as a subview of
     * contentView. Each time rebuild() is called, this view is removed from the superview
     * if non-nil and reconstructed. Removing it from the superview is the only reason to
     * make this a property.
     */
    var view : UIView?

    init(sense: DubsarModelsSense!, frame: CGRect) {
        self.sense = sense
        super.init(style: .Default, reuseIdentifier: SenseTableViewCell.identifier)

        self.frame = frame

        rebuild()
    }

    func rebuild() {
        let borderWidth = SenseTableViewCell.borderWidth
        let margin = SenseTableViewCell.margin

        let constrainedSize = CGSizeMake(frame.size.width-2*borderWidth-2*margin, frame.size.height)
        let size = sense.sizeWithConstrainedSize(constrainedSize)
        let synonymSize = sense.synonymSizeWithConstrainedSize(constrainedSize)

        frame.size.height = size.height + 2*borderWidth + 3*margin + SenseTableViewCell.labelLineHeight
        if synonymSize.height > 0 {
            frame.size.height += synonymSize.height + margin
        }

        view?.removeFromSuperview()

        view = UIView(frame: contentView.bounds)
        view!.backgroundColor = UIColor.blackColor()

        contentView.addSubview(view)

        let backgroundLabel = UIView(frame: CGRectMake(borderWidth, borderWidth, bounds.size.width-2*borderWidth, bounds.size.height-2*borderWidth))
        backgroundLabel.backgroundColor = cellBackgroundColor
        view!.addSubview(backgroundLabel)

        var lexnameText = "<\(sense.lexname)>"
        if sense.freqCnt > 0 {
            lexnameText = "\(lexnameText) freq. cnt.: \(sense.freqCnt)"
        }

        let lexnameLabel = UILabel(frame: CGRectMake(margin, margin, bounds.size.width-2*borderWidth-2*margin, SenseTableViewCell.labelLineHeight))
        lexnameLabel.text = lexnameText
        lexnameLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        lexnameLabel.numberOfLines = 1
        backgroundLabel.addSubview(lexnameLabel)

        let textLabel = UILabel(frame: CGRectMake(margin, 2*margin + SenseTableViewCell.labelLineHeight, bounds.size.width-2*borderWidth-2*margin, size.height))
        textLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        textLabel.text = sense.gloss
        textLabel.lineBreakMode = .ByWordWrapping
        textLabel.numberOfLines = 0
        backgroundLabel.addSubview(textLabel)

        if synonymSize.height > 0 {
            let synonymLabel = UILabel(frame: CGRectMake(margin, 3*margin + SenseTableViewCell.labelLineHeight + size.height, bounds.size.width-2*borderWidth-2*margin, synonymSize.height))
            synonymLabel.text = sense.synonymsAsString
            synonymLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
            synonymLabel.lineBreakMode = .ByWordWrapping
            synonymLabel.numberOfLines = 0
            backgroundLabel.addSubview(synonymLabel)
        }
    }

}
