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

extension DubsarModelsSense {

    func glossSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = gloss as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func synonymSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = synonymsAsString as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func sizeOfCellWithConstrainedSize(constrainedSize: CGSize, open: Bool, maxHeightOfAdditions: CGFloat = 0) -> CGSize {
        var constraint = constrainedSize
        constraint.width -= 2 * SenseTableViewCell.margin + SenseTableViewCell.accessoryWidth

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let caption1Font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleCaption1)

        let glossSize = glossSizeWithConstrainedSize(constraint, font: bodyFont)

        var size = constrainedSize

        size.height = SenseTableViewCell.labelLineHeight + 3*SenseTableViewCell.margin + glossSize.height

        if synonyms.count > 0 {
            let synonymSize = synonymSizeWithConstrainedSize(constraint, font: caption1Font)
            size.height += synonymSize.height + SenseTableViewCell.margin
        }

        DMTRACE("Cell header height: \(size.height)")

        if open {
            if !complete {
                size.height += 44
                return size
            }

            // these views have to fit between the borders and the accessory, but they have their own margins
            constraint.width += 2 * SenseTableViewCell.margin

            // Yikes
            let sampleView = SynsetSampleView(synset: synset, frame: CGRectMake(0, 0, constraint.width, constraint.height), preview: true)
            sampleView.layoutMode = true
            sampleView.sense = self
            sampleView.layoutSubviews()
            DMTRACE("Computed sample view height is \(sampleView.bounds.size.height); cell height will be \(size.height+sampleView.bounds.size.height)")

            var additions = sampleView.bounds.size.height
            if maxHeightOfAdditions > 0 && additions >= maxHeightOfAdditions {
                size.height += maxHeightOfAdditions
                return size
            }

            if numberOfSections == 0 {
                size.height += additions
                return size
            }

            let pointerView = SynsetPointerView(synset: synset, frame: CGRectMake(0, 0, constraint.width, constraint.height), preview: true)
            pointerView.layoutMode = true
            pointerView.sense = self
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

        return size
    }

    func estimatedHeightOfCell(constrainedSize: CGSize, open: Bool, maxHeightOfAdditions: CGFloat = 0) -> CGFloat {
        var constraint = constrainedSize
        constraint.width -= 2 * SenseTableViewCell.margin + SenseTableViewCell.accessoryWidth

        let margin = SenseTableViewCell.margin
        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let lineHeight = ("Qp" as NSString).sizeWithAttributes([NSFontAttributeName: bodyFont]).height + margin

        let width = ("0123456789" as NSString).sizeWithAttributes([NSFontAttributeName: bodyFont]).width
        let numPerLine: CGFloat = 10 * (constraint.width - 2 * margin)/width

        // estimate the number of lines
        let numGlossLines = CGFloat((gloss as NSString).length) / numPerLine

        let numHeaderLines = numGlossLines + 2 // 1 for the lexname, 1 for synonyms

        if !open {
            return numHeaderLines * lineHeight
        }

        if !complete {
            return numHeaderLines * lineHeight + 44
        }

        let numSampleLines = CGFloat(samples.count)
        let sampleHeight = lineHeight * numSampleLines

        if maxHeightOfAdditions > 0 && sampleHeight >= maxHeightOfAdditions {
            return numHeaderLines * lineHeight + maxHeightOfAdditions
        }

        if maxHeightOfAdditions > 0 {
            return numHeaderLines * lineHeight + maxHeightOfAdditions
        }

        return 300 // punt for now
    }
   
}
