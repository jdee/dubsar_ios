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

extension DubsarModelsSense {

    func glossSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = gloss as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func synonymSizeWithConstrainedSize(constrainedSize: CGSize, font: UIFont?) -> CGSize {
        let text = synonymsAsString as NSString
        return text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
    }

    func sizeOfCellWithConstrainedSize(constrainedSize: CGSize, open: Bool) -> CGSize {
        var constraint = constrainedSize
        constraint.width -= 2 * SenseTableViewCell.margin + 2 * SenseTableViewCell.borderWidth

        let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let caption1Font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        let subheadlineFont = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)

        let glossSize = glossSizeWithConstrainedSize(constraint, font: bodyFont)

        var size = constrainedSize

        size.height = SenseTableViewCell.labelLineHeight + 3*SenseTableViewCell.margin + glossSize.height + 2 * SenseTableViewCell.borderWidth

        if synonyms.count > 0 {
            let synonymSize = synonymSizeWithConstrainedSize(constraint, font: caption1Font)
            size.height += synonymSize.height + SenseTableViewCell.margin
        }

        NSLog("Cell header height: %f", size.height)

        if open {
            // Yikes
            let sampleView = SynsetSampleView(synset: synset, frame: CGRectMake(0, 0, constrainedSize.width+2*SenseTableViewCell.borderWidth+2*SenseTableViewCell.margin, constrainedSize.height))
            sampleView.sense = self
            sampleView.layoutSubviews()
            size.height += sampleView.bounds.size.height
            NSLog("Computed sample view height is %f; cell height will be %f", sampleView.bounds.size.height, size.height)
        }

        return size
    }
   
}
