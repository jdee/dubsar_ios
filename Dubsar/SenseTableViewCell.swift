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

    class var borderWidth : CGFloat {
        get {
            return 0
        }
    }

    class var margin : CGFloat {
        get {
            return 6
        }
    }

    // just some extra margin on the right to avoid getting clobbered by the accessory
    class var accessoryWidth : CGFloat {
        get {
            return 25
        }
    }

    class var labelLineHeight : CGFloat {
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

        accessoryType = .DisclosureIndicator

        rebuild()
    }

    func rebuild() {
        let borderWidth = SenseTableViewCell.borderWidth
        let margin = SenseTableViewCell.margin

        let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let caption1Font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        let subheadlineFont = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)

        let constrainedSize = CGSizeMake(frame.size.width-2*borderWidth-2*margin-SenseTableViewCell.accessoryWidth, frame.size.height)
        let glossSize = sense.glossSizeWithConstrainedSize(constrainedSize, font: bodyFont)
        let synonymSize = sense.synonymSizeWithConstrainedSize(constrainedSize, font: caption1Font)

        bounds.size.height = sense.sizeOfCellWithConstrainedSize(constrainedSize).height

        view?.removeFromSuperview()

        view = UIView(frame: bounds)
        view!.backgroundColor = UIColor.blackColor()

        contentView.addSubview(view)

        let backgroundLabel = UIView(frame: CGRectMake(borderWidth, borderWidth, bounds.size.width-2*borderWidth, bounds.size.height-2*borderWidth))
        backgroundLabel.backgroundColor = cellBackgroundColor
        view!.addSubview(backgroundLabel)

        var lexnameText = "<\(sense.lexname)>"
        if !sense.marker.isEmpty {
            lexnameText = "\(lexnameText) (\(sense.marker))"
        }

        if sense.freqCnt > 0 {
            lexnameText = "\(lexnameText) freq. cnt.: \(sense.freqCnt)"
        }

        let lexnameLabel = UILabel(frame: CGRectMake(margin, margin, constrainedSize.width, SenseTableViewCell.labelLineHeight))
        lexnameLabel.text = lexnameText
        lexnameLabel.font = subheadlineFont
        lexnameLabel.numberOfLines = 1
        backgroundLabel.addSubview(lexnameLabel)

        let textLabel = UILabel(frame: CGRectMake(margin, 2*margin + SenseTableViewCell.labelLineHeight, constrainedSize.width, glossSize.height))
        textLabel.font = bodyFont
        textLabel.text = sense.gloss
        textLabel.lineBreakMode = .ByWordWrapping
        textLabel.numberOfLines = 0
        backgroundLabel.addSubview(textLabel)

        if sense.synonyms.count > 0 {
            let synonymLabel = UILabel(frame: CGRectMake(margin, 3*margin + SenseTableViewCell.labelLineHeight + glossSize.height, constrainedSize.width, synonymSize.height))
            synonymLabel.text = sense.synonymsAsString
            synonymLabel.font = caption1Font
            synonymLabel.lineBreakMode = .ByWordWrapping
            synonymLabel.numberOfLines = 0
            backgroundLabel.addSubview(synonymLabel)
        }
    }

}
