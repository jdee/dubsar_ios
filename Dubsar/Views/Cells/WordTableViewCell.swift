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

class WordTableViewCell: UITableViewCell {

    // just some extra margin on the right to avoid getting clobbered by the accessory
    class var accessoryWidth : CGFloat {
        get {
            return 60
    }
    }

    class var identifier : String {
        get {
            return "word"
        }
    }

    class var margin : CGFloat {
        get {
            return 10
        }
    }

    var word : DubsarModelsWord?
    var cellBackgroundColor : UIColor! = AppConfiguration.backgroundColor
    var view : UIView?
    var isPreview : Bool

    init(word: DubsarModelsWord?, preview: Bool, reuseIdentifier: String = WordTableViewCell.identifier) {
        self.word = word
        isPreview = preview
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)

        // setTranslatesAutoresizingMaskIntoConstraints(false)

        selectionStyle = .None
    }

    required init(coder aDecoder: NSCoder) {
        isPreview = true
        super.init(coder: aDecoder)
    }

    func rebuild() {
        if word == nil {
            return
        }

        if !word!.complete {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
            spinner.startAnimating()
            spinner.frame = CGRectMake(2, 2, 40, 40)
            view?.addSubview(spinner)
        }

        let accessorySize = WordTableViewCell.accessoryWidth
        let headlineFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let italicFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody, italic: true)

        let margin = WordTableViewCell.margin
        let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin - (isPreview ? accessorySize : 0), bounds.size.height)

        let nameAndPos = word!.nameAndPos as NSString
        let inflectionText = word!.otherForms as NSString
        let freqCntText = "freq. cnt.: \(word!.freqCnt)" as NSString

        let nameAndPosSize = word!.nameAndPosSizeWithConstrainedSize(constrainedSize, font: headlineFont)
        let inflectionSize = word!.inflectionSizeWithConstrainedSize(constrainedSize, font: italicFont)
        let freqCntSize = word!.freqCntSizeWithConstrainedSize(constrainedSize, font: bodyFont)

        let originalWidth = bounds.size.width
        bounds.size = word!.sizeOfCellWithConstrainedSize(bounds.size, open: false, maxHeightOfAdditions: 0, preview: isPreview)
        assert(originalWidth == bounds.size.width)

        view?.removeFromSuperview()

        view = UIView(frame: bounds)
        view!.backgroundColor = selected ? AppConfiguration.highlightColor : cellBackgroundColor
        view!.setTranslatesAutoresizingMaskIntoConstraints(false)

        layer.borderColor = UIColor.redColor().CGColor
        // layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.greenColor().CGColor
        // contentView.layer.borderWidth = 1
        view!.layer.borderColor = UIColor.blueColor().CGColor
        // view!.layer.borderWidth = 1

        contentView.frame = bounds
        contentView.addSubview(view!)
        contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentView.removeConstraints(contentView.constraints())

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

        constraint = NSLayoutConstraint(item: view!, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Leading, relatedBy: .Equal, toItem: contentView, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        contentView.addConstraint(constraint)
        // */

        let nameAndPosLabel = UILabel(frame:CGRectMake(margin, margin, constrainedSize.width, nameAndPosSize.height))
        nameAndPosLabel.lineBreakMode = .ByWordWrapping
        nameAndPosLabel.numberOfLines = 0
        nameAndPosLabel.font = headlineFont
        nameAndPosLabel.text = nameAndPos
        nameAndPosLabel.textColor = AppConfiguration.foregroundColor
        nameAndPosLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        nameAndPosLabel.layer.borderColor = UIColor.orangeColor().CGColor
        // nameAndPosLabel.layer.borderWidth = 1
        view!.addSubview(nameAndPosLabel)

        constraint = NSLayoutConstraint(item: nameAndPosLabel, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -margin - (isPreview ? accessorySize : 0))
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: nameAndPosLabel, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: margin)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: nameAndPosLabel, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: margin)
        view!.addConstraint(constraint)

        var inflectionLabel: UILabel?
        if word!.inflections.count > 0 {
            inflectionLabel = UILabel(frame:CGRectMake(margin, 2*margin+nameAndPosSize.height, constrainedSize.width, inflectionSize.height))
            inflectionLabel!.lineBreakMode = .ByWordWrapping
            inflectionLabel!.numberOfLines = 0
            inflectionLabel!.font = italicFont
            inflectionLabel!.text = inflectionText
            inflectionLabel!.textColor = AppConfiguration.foregroundColor
            inflectionLabel!.layer.borderColor = UIColor.yellowColor().CGColor
            // inflectionLabel.layer.borderWidth = 1
            inflectionLabel!.setTranslatesAutoresizingMaskIntoConstraints(false)
            view!.addSubview(inflectionLabel!)

            constraint = NSLayoutConstraint(item: inflectionLabel!, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -margin - (isPreview ? accessorySize : 0))
            view!.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: inflectionLabel!, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: inflectionLabel!, attribute: .Top, relatedBy: .Equal, toItem: nameAndPosLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
        }

        if word!.freqCnt > 0 {
            var verticalOrigin = 2*margin + nameAndPosSize.height
            if word!.inflections.count > 0 {
                verticalOrigin += margin + inflectionSize.height
            }

            let freqCntLabel = UILabel(frame:CGRectMake(margin, verticalOrigin, constrainedSize.width, freqCntSize.height))
            freqCntLabel.lineBreakMode = .ByWordWrapping
            freqCntLabel.numberOfLines = 0
            freqCntLabel.font = bodyFont
            freqCntLabel.text = freqCntText
            freqCntLabel.textColor = AppConfiguration.foregroundColor
            freqCntLabel.layer.borderColor = UIColor.purpleColor().CGColor
            // freqCntLabel.layer.borderWidth = 1
            freqCntLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
            view!.addSubview(freqCntLabel)

            constraint = NSLayoutConstraint(item: freqCntLabel, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -margin - (isPreview ? accessorySize : 0))
            view!.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: freqCntLabel, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
            constraint = NSLayoutConstraint(item: freqCntLabel, attribute: .Top, relatedBy: .Equal, toItem: inflectionLabel != nil ? inflectionLabel : nameAndPosLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
            view!.addConstraint(constraint)
        }
        /*
            constraint = NSLayoutConstraint(item: freqCntLabel, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: -margin)
            view!.addConstraint(constraint)
        }
        else if inflectionLabel {
            constraint = NSLayoutConstraint(item: inflectionLabel, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: -margin)
            view!.addConstraint(constraint)
        }
        else {
            constraint = NSLayoutConstraint(item: nameAndPosLabel, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: -margin)
            view!.addConstraint(constraint)
        }
        // */
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if let v = view {
            v.backgroundColor = selected ? AppConfiguration.highlightColor : cellBackgroundColor
        }
    }
}
