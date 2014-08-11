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

extension DubsarModelsSynset {

    func synonymSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = synonymsAsString as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func glossSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = gloss as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func sizeOfCellWithConstrainedSize(constrainedSize: CGSize, open: Bool, maxHeightOfAdditions: CGFloat = 0) -> CGSize {
        var constraint = constrainedSize
        constraint.width -= 2 * SynsetTableViewCell.margin + 2 * SynsetTableViewCell.borderWidth + SynsetTableViewCell.accessoryWidth

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let caption1Font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleCaption1)

        let glossSize = glossSizeWithConstrainedSize(constraint, font: bodyFont)

        var size = constrainedSize

        size.height = SynsetTableViewCell.labelLineHeight + 3 * SynsetTableViewCell.margin + glossSize.height + 2 * SynsetTableViewCell.borderWidth

        var synonymSize = CGSizeZero
        if senses.count > 0 {
            synonymSize = synonymSizeWithConstrainedSize(constraint, font: caption1Font)
            size.height += synonymSize.height + SynsetTableViewCell.margin
        }

        DMDEBUG("Computed height of synset header \(size.height) = 4 * \(SynsetTableViewCell.margin) + 2 * \(SynsetTableViewCell.borderWidth) + \(SynsetTableViewCell.labelLineHeight) + \(glossSize.height) + \(synonymSize.height)")

        if open {
            if !complete {
                size.height += 44
                return size
            }

            // Yikes
            let sampleView = SynsetSampleView(synset: self, frame: CGRectMake(0, 0, constrainedSize.width+2*SynsetTableViewCell.borderWidth+2*SynsetTableViewCell.margin, constrainedSize.height), preview: true)
            sampleView.layoutSubviews()
            // DMLOG("Computed sample view height is %f; cell height will be %f", sampleView.bounds.size.height, size.height)

            var additions = sampleView.bounds.size.height
            if maxHeightOfAdditions > 0 && additions >= maxHeightOfAdditions {
                size.height += maxHeightOfAdditions
                return size
            }

            if numberOfSections == 0 {
                return size
            }

            let pointerView = SynsetPointerView(synset: self, frame: CGRectMake(0, 0, constrainedSize.width+2*SynsetTableViewCell.borderWidth+2*SynsetTableViewCell.margin, constrainedSize.height), preview: true)
            pointerView.scrollViewTop = 0
            pointerView.scrollViewBottom = constrainedSize.height
            pointerView.layoutSubviews()

            additions += pointerView.bounds.size.height
            if maxHeightOfAdditions > 0 && additions >= maxHeightOfAdditions {
                size.height += maxHeightOfAdditions
                return size
            }
            size.height += additions
        }

        DMDEBUG("Computed height of synset cell: \(size.height)")

        return size
    }
    
}
