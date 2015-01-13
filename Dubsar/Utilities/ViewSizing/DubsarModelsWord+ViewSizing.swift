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

/*
 * The model is the thing that needs to tell you what its display size is, but that doesn't really belong in the model
 * framework.
 */
extension DubsarModelsWord {

    func nameAndPosSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = nameAndPos as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func inflectionSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = otherForms as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func freqCntSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = "freq. cnt. \(freqCnt)" as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func sizeOfCellWithConstrainedSize(constrainedSize: CGSize, open: Bool, maxHeightOfAdditions: CGFloat, preview: Bool) -> CGSize {
        var constraint = constrainedSize
        constraint.width -= 2 * WordTableViewCell.margin
        if preview {
            constraint.width -= WordTableViewCell.accessoryWidth
        }

        var size = nameAndPosSizeWithConstrainedSize(constraint, font: AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline))
        size.width = constrainedSize.width
        size.height += WordTableViewCell.margin * 2

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)

        let optionalInflections: [AnyObject]? = inflections
        if optionalInflections != nil && inflections.count > 0 {
            let inflectionSize = inflectionSizeWithConstrainedSize(constraint, font: bodyFont)
            size.height += inflectionSize.height + WordTableViewCell.margin
        }

        if freqCnt > 0 {
            let freqCntSize = freqCntSizeWithConstrainedSize(constraint, font: bodyFont)
            size.height += freqCntSize.height + WordTableViewCell.margin
        }

        if open {
            if !complete {
                size.height += 44
                return size
            }

            assert(senses != nil)
            let sense = senses.firstObject as? DubsarModelsSense
            assert(sense != nil)
            let openSenseCellSize = sense!.sizeOfCellWithConstrainedSize(constrainedSize, open: true, maxHeightOfAdditions: maxHeightOfAdditions)
            DMTRACE("height without open sense cell: \(size.height); with open sense cell: \(size.height + openSenseCellSize.height)")
            size.height += openSenseCellSize.height
        }

        return size
    }

    func estimatedHeightOfCell(constrainedSize: CGSize, open: Bool, maxHeightOfAdditions: CGFloat = 0, preview: Bool) -> CGFloat {
        var constraint = constrainedSize
        constraint.width -= 2 * WordTableViewCell.margin
        if preview {
            constraint.width -= WordTableViewCell.accessoryWidth
        }

        let margin = WordTableViewCell.margin
        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let lineHeight = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: bodyFont]).height + margin

        let width = ("0123456789" as NSString).sizeWithAttributes([NSFontAttributeName: bodyFont]).width
        let numPerLine: CGFloat = 10 * (constraint.width - 2 * margin)/width

        // estimate the number of lines
        let headerLines: CGFloat = 3

        if !open {
            return headerLines * lineHeight
        }

        if !complete {
            return headerLines * lineHeight + 44
        }

        assert(senses != nil)
        let sense = senses.firstObject as? DubsarModelsSense
        assert(sense != nil)
        let openSenseCellHeight = sense!.estimatedHeightOfCell(constrainedSize, open: true, maxHeightOfAdditions: maxHeightOfAdditions)
        return headerLines * lineHeight + openSenseCellHeight
    }

}