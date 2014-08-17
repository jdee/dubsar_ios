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

    class var margin : CGFloat {
        get {
            return 6
        }
    }

    // just some extra margin on the right to avoid getting clobbered by the accessory
    class var accessoryWidth : CGFloat {
        get {
            return 60
        }
    }

    class var labelLineHeight : CGFloat {
        get {
            return 21
        }
    }

    var sense : DubsarModelsSense!
    var cellBackgroundColor : UIColor! = AppConfiguration.backgroundColor
    
    /*
     * The main thing this class does is build this view, which is added as a subview of
     * contentView. Each time rebuild() is called, this view is removed from the superview
     * if non-nil and reconstructed. Removing it from the superview is the only reason to
     * make this a property.
     */
    var view : UIView?

    init(sense: DubsarModelsSense!, frame: CGRect, identifier: String = SenseTableViewCell.identifier) {
        self.sense = sense
        super.init(style: .Default, reuseIdentifier: identifier)

        self.frame = frame

        //setTranslatesAutoresizingMaskIntoConstraints(false)
        accessoryType = .DetailDisclosureButton
        clipsToBounds = true
    }

    func rebuild() {
        let margin = SenseTableViewCell.margin

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let caption1Font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleCaption1)
        let subheadlineFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleSubheadline)

        let accessoryWidth = SenseTableViewCell.accessoryWidth
        let constrainedSize = CGSizeMake(frame.size.width - 2 * margin - accessoryWidth, frame.size.height)
        let glossSize = sense.glossSizeWithConstrainedSize(constrainedSize, font: bodyFont)
        let synonymSize = sense.synonymSizeWithConstrainedSize(constrainedSize, font: caption1Font)

        DMTRACE("Initial sense cell bounds height: \(bounds.size.height)")
        bounds.size.height = sense.sizeOfCellWithConstrainedSize(frame.size, open:false).height
        DMTRACE("Recomputed to \(bounds.size.height)")

        view?.removeFromSuperview()

        view = UIView(frame: bounds)
        view!.layer.borderColor = UIColor.blackColor().CGColor
        view!.layer.borderWidth = 0
        view!.setTranslatesAutoresizingMaskIntoConstraints(false)
        view!.backgroundColor = cellBackgroundColor

        contentView.addSubview(view)
        contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.removeConstraints(contentView.constraints())
        contentView.layer.borderColor = UIColor.whiteColor().CGColor
        contentView.layer.borderWidth = 0

        var constraint: NSLayoutConstraint
        //* Usually an autoresizing mask works, but this fixes a problem that the autoresizingMask doesn't.
        constraint = NSLayoutConstraint(item: contentView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: contentView, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        // */

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
        lexnameLabel.textColor = AppConfiguration.foregroundColor
        lexnameLabel.textAlignment = .Left
        lexnameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        lexnameLabel.layer.borderWidth = 0
        lexnameLabel.layer.borderColor = UIColor.greenColor().CGColor
        view!.addSubview(lexnameLabel)

        constraint = NSLayoutConstraint(item: lexnameLabel, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -margin - accessoryWidth)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: lexnameLabel, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: margin)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: lexnameLabel, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: margin)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item:lexnameLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 0.0, constant: SenseTableViewCell.labelLineHeight)
        lexnameLabel.addConstraint(constraint)

        let textLabel = UILabel(frame: CGRectMake(margin, 2*margin + SenseTableViewCell.labelLineHeight, constrainedSize.width, glossSize.height))
        textLabel.font = bodyFont
        textLabel.text = sense.gloss
        textLabel.lineBreakMode = .ByWordWrapping
        textLabel.numberOfLines = 0
        textLabel.textColor = AppConfiguration.foregroundColor
        textLabel.textAlignment = .Left
        textLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        textLabel.layer.borderColor = UIColor.blueColor().CGColor
        textLabel.layer.borderWidth = 0
        textLabel.contentMode = .Redraw
        view!.addSubview(textLabel)

        constraint = NSLayoutConstraint(item: textLabel, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: margin)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: textLabel, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -margin - accessoryWidth)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: textLabel, attribute: .Top, relatedBy: .Equal, toItem: lexnameLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
        view!.addConstraint(constraint)

        DMTRACE("Gloss frame for \(sense.gloss) is (\(textLabel.frame.origin.x), \(textLabel.frame.origin.y)) \(textLabel.frame.size.width) x \(textLabel.frame.size.height).")

        if sense.synonyms.count > 0 {
            let synonymLabel = UILabel(frame: CGRectMake(margin, 3*margin + SenseTableViewCell.labelLineHeight + glossSize.height, constrainedSize.width, synonymSize.height))
            synonymLabel.text = sense.synonymsAsString
            synonymLabel.font = caption1Font
            synonymLabel.lineBreakMode = .ByWordWrapping
            synonymLabel.numberOfLines = 0
            synonymLabel.textColor = AppConfiguration.foregroundColor
            synonymLabel.textAlignment = .Left
            synonymLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
            synonymLabel.layer.borderWidth = 0
            synonymLabel.layer.borderColor = UIColor.orangeColor().CGColor
            view!.addSubview(synonymLabel)

            constraint = NSLayoutConstraint(item: synonymLabel, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -margin - accessoryWidth)
            view!.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: synonymLabel, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: synonymLabel, attribute: .Top, relatedBy: .Equal, toItem: textLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
            /*
            constraint = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: synonymLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
        }
        else {
            constraint = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: textLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
            // */
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        view!.backgroundColor = selected ? AppConfiguration.highlightColor : cellBackgroundColor
    }

}
