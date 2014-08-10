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

    var word : DubsarModelsWord? {
    didSet {
        rebuild()
    }
    }

    var cellBackgroundColor : UIColor! = AppConfiguration.backgroundColor {
    didSet {
        rebuild()
    }
    }

    var view : UIView?
    var isPreview : Bool

    init(word: DubsarModelsWord?, preview: Bool, reuseIdentifier: String = WordTableViewCell.identifier) {
        self.word = word
        isPreview = preview
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)

        selectionStyle = .None

        rebuild()
    }

    func rebuild() {
        if !word {
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
        let italicFontDescriptor = bodyFont.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitItalic)
        let italicFont = UIFont(descriptor: italicFontDescriptor, size:0.0)

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

        contentView.frame = bounds
        contentView.addSubview(view)

        let nameAndPosLabel = UILabel(frame:CGRectMake(margin, margin, constrainedSize.width, nameAndPosSize.height))
        nameAndPosLabel.lineBreakMode = .ByWordWrapping
        nameAndPosLabel.numberOfLines = 0
        nameAndPosLabel.font = headlineFont
        nameAndPosLabel.text = nameAndPos
        nameAndPosLabel.textColor = AppConfiguration.foregroundColor
        view!.addSubview(nameAndPosLabel)

        if word!.inflections.count > 0 {
            let inflectionLabel = UILabel(frame:CGRectMake(margin, 2*margin+nameAndPosSize.height, constrainedSize.width, inflectionSize.height))
            inflectionLabel.lineBreakMode = .ByWordWrapping
            inflectionLabel.numberOfLines = 0
            inflectionLabel.font = italicFont
            inflectionLabel.text = inflectionText
            inflectionLabel.textColor = AppConfiguration.foregroundColor
            view!.addSubview(inflectionLabel)
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
            view!.addSubview(freqCntLabel)
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if let v = view {
            v.backgroundColor = selected ? AppConfiguration.highlightColor : cellBackgroundColor
        }
    }
}
