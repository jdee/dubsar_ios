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

class SynsetPointerView: UIView {

    class var margin : CGFloat {
    get {
        return 8
    }
    }

    let synset : DubsarModelsSynset
    var sense : DubsarModelsSense?

    let labels : NSMutableArray

    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset
        labels = NSMutableArray()
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        for label : AnyObject in labels as NSArray {
            if let view = label as? UILabel {
                view.removeFromSuperview()
            }
        }
        labels.removeAllObjects()

        if synset.complete {
            var sections : NSArray
            var count : Int
            // in both cases, numberOfSections does an SQL query and builds the sections array
            if sense {
                count = sense!.numberOfSections
                sections = sense!.sections
            }
            else {
                count = synset.numberOfSections
                sections = synset.sections
            }

            let margin = SynsetPointerView.margin
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin, bounds.size.height)

            var y : CGFloat = margin
            for var sectionNumber = 0; sectionNumber < count; ++sectionNumber {
                let object: AnyObject = sections[sectionNumber]
                if let section = object as? DubsarModelsSection {
                    let title = section.header as NSString
                    let titleSize = title.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
                    let titleLabel = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, titleSize.height))
                    titleLabel.font = font
                    titleLabel.text = title
                    titleLabel.lineBreakMode = .ByWordWrapping
                    titleLabel.numberOfLines = 0
                    titleLabel.textAlignment = .Center
                    addSubview(titleLabel)

                    labels.addObject(titleLabel)

                    y += titleSize.height + margin

                    NSLog("Title for section %d is %@", sectionNumber, title)

                    let numRows = section.numRows
                    NSLog("Section %d (%@) contains %d rows", sectionNumber, title, numRows)
                    for var row=0; row<numRows; ++row {
                        let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber)
                        var pointer : DubsarModelsPointer
                        // could use a base class or a protocol here
                        NSLog("Calling pointerForRowAtIndexPath:")
                        if sense {
                            pointer = sense!.pointerForRowAtIndexPath(indexPath)
                        }
                        else {
                            pointer = synset.pointerForRowAtIndexPath(indexPath)
                        }

                        let text = "\(pointer.targetGloss) (\(pointer.targetText))" as NSString
                        let textSize = text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
                        let textLabel = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, textSize.height))
                        textLabel.text = text
                        textLabel.font = font
                        textLabel.lineBreakMode = .ByWordWrapping
                        textLabel.numberOfLines = 0
                        addSubview(textLabel)
                        labels.addObject(textLabel)

                        y += textSize.height + margin

                        NSLog("Pointer text for section %d, row %d is %@", sectionNumber, row, title)
                    }
                }
            }

            frame.size.height = y
        }

        super.layoutSubviews()
    }
}
