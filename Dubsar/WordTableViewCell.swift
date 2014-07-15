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

    class var identifier : String {
        get {
            return "word"
        }
    }

    class var margin : Float {
        get {
            return 4
        }
    }

    var word : DubsarModelsWord? {
    didSet {
        rebuild()
    }
    }

    var cellBackgroundColor : UIColor! = UIColor.whiteColor() {
    didSet {
        rebuild()
    }
    }

    var view : UIView?

    init(word: DubsarModelsWord? = nil) {
        self.word = word
        super.init(style: .Subtitle, reuseIdentifier: WordTableViewCell.identifier)

        selectionStyle = .None

        rebuild()
    }

    func rebuild() {
        if !word {
            return
        }

        let headlineFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        let margin = WordTableViewCell.margin
        let constrainedSize = CGSizeMake(bounds.size.width-2*margin, bounds.size.height)

        let nameAndPos = word!.nameAndPos as NSString
        let inflectionText = word!.otherForms as NSString
        let freqCntText = "freq. cnt.: \(word!.freqCnt)" as NSString

        let nameAndPosSize = word!.nameAndPosSizeWithConstrainedSize(constrainedSize, font: headlineFont)
        let inflectionSize = word!.inflectionSizeWithConstrainedSize(constrainedSize, font: bodyFont)
        let freqCntSize = word!.freqCntSizeWithConstrainedSize(constrainedSize, font: bodyFont)

        var height = nameAndPosSize.height + 2*margin
        if word!.inflections.count > 0 {
            height += inflectionSize.height + margin
        }
        if word!.freqCnt > 0 {
            height += freqCntSize.height + margin
        }

        var viewBounds = bounds
        viewBounds.size.height = height

        view?.removeFromSuperview()

        view = UIView(frame: viewBounds)
        view!.backgroundColor = cellBackgroundColor

        contentView.addSubview(view)

        let nameAndPosLabel = UILabel(frame:CGRectMake(margin, margin, constrainedSize.width, nameAndPosSize.height))
        nameAndPosLabel.lineBreakMode = .ByWordWrapping
        nameAndPosLabel.numberOfLines = 0
        nameAndPosLabel.font = headlineFont
        nameAndPosLabel.text = nameAndPos
        view!.addSubview(nameAndPosLabel)

        if word!.inflections.count > 0 {
            let inflectionLabel = UILabel(frame:CGRectMake(margin, 2*margin+nameAndPosSize.height, constrainedSize.width, inflectionSize.height))
            inflectionLabel.lineBreakMode = .ByWordWrapping
            inflectionLabel.numberOfLines = 0
            inflectionLabel.font = bodyFont
            inflectionLabel.text = inflectionText
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
            view!.addSubview(freqCntLabel)
        }
    }

}
