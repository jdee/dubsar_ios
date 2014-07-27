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

    func sizeOfCellWithConstrainedSize(constrainedSize: CGSize, open: Bool, maxHeightOfAdditions: CGFloat) -> CGSize {
        var constraint = constrainedSize
        constraint.width -= 2 * WordTableViewCell.margin

        var size = nameAndPosSizeWithConstrainedSize(constraint, font: AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline))
        size.width = constrainedSize.width
        size.height += WordTableViewCell.margin * 2

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)

        if inflections.count > 0 {
            let inflectionSize = inflectionSizeWithConstrainedSize(constraint, font: bodyFont)
            size.height += inflectionSize.height + WordTableViewCell.margin
        }

        if freqCnt > 0 {
            let freqCntSize = freqCntSizeWithConstrainedSize(constraint, font: bodyFont)
            size.height += freqCntSize.height + WordTableViewCell.margin
        }

        if open {
            assert(senses)
            let sense = senses.firstObject as? DubsarModelsSense
            assert(sense)
            let openSenseCell = OpenSenseTableViewCell(sense: sense, frame: CGRectMake(0, 0, constrainedSize.width, constrainedSize.height), maxHeightOfAdditions: maxHeightOfAdditions)
            // NSLog("height without open sense cell: %f; with open sense cell: %f", Double(size.height), Double(size.height + openSenseCell.bounds.size.height))
            size.height += openSenseCell.bounds.size.height
        }

        return size
    }

}