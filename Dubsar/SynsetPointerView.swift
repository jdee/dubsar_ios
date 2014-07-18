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

class PointerLabel : UILabel {
    let pointer : DubsarModelsPointer
    weak var viewController : SynsetViewController?

    init(pointer: DubsarModelsPointer!, frame: CGRect) {
        self.pointer = pointer
        super.init(frame: frame)

        lineBreakMode = .ByWordWrapping
        numberOfLines = 0
        font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    }
}

class SynsetPointerView: UIView {
    class var margin : CGFloat {
    get {
        return 8
    }
    }

    let synset : DubsarModelsSynset
    var sense : DubsarModelsSense?

    let labels : NSMutableArray

    var scrollViewTop : CGFloat = 0
    var scrollViewBottom : CGFloat = 0

    var hasReset : Bool = true
    var numberOfSections : Int = 0
    var sections : NSArray!
    var totalRows : Int = 0
    var completedUpToY : CGFloat = 0
    var completedUpToRow : Int = 0
    var nextSection : Int = 0
    var nextRow : Int = -1

    weak var viewController : SynsetViewController?

    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset
        labels = NSMutableArray()
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        if synset.complete {
            if hasReset {
                performReset()
            }

            /*
             * Every time we come through here, we must make sure the region from MAX(0, scrollViewTop) to 
             * scrollViewBottom is tiled.
             * We must also refine our estimate of the size of this view given the overall row count and adjust 
             * frame.size.height.
             */

            /*
             * The safest thing to do (to begin with) is start at the top of this view (y = 0) and work our way down.
             */
            if completedUpToY >= scrollViewBottom || nextSection == numberOfSections {
                // nothing to do.
                return
            }

            tileViewport()

            // now estimate
            frame.size.height = completedUpToY * CGFloat(totalRows) / CGFloat(completedUpToRow)
            // NSLog("completed up to y: %f, row: %d, total rows %d, est. total height: %f", completedUpToY, completedUpToRow, totalRows, frame.size.height)
        }

        hasReset = false
        super.layoutSubviews()
    }

    func pointerForRowAtIndexPath(indexPath: NSIndexPath!) -> DubsarModelsPointer {
        // could use a base class or a protocol here
        // NSLog("Calling pointerForRowAtIndexPath:")
        if sense {
            return sense!.pointerForRowAtIndexPath(indexPath)
        }
        return synset.pointerForRowAtIndexPath(indexPath)
    }

    func tileViewport() {
        // convenient constants
        let margin = SynsetPointerView.margin
        let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let titleFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin, bounds.size.height)

        // y is where the next tile will go (frame.origin.y)
        var y : CGFloat = margin + completedUpToY

        var sectionNumber: Int
        var finished = false
        for sectionNumber = nextSection; sectionNumber < numberOfSections; ++sectionNumber {
            let object: AnyObject = sections[sectionNumber]
            if let section = object as? DubsarModelsSection {
                if nextRow == -1 {
                    let title = section.header as NSString
                    let titleSize = title.sizeOfTextWithConstrainedSize(constrainedSize, font: titleFont)
                    let titleLabel = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, titleSize.height))
                    titleLabel.font = titleFont
                    titleLabel.text = title
                    titleLabel.lineBreakMode = .ByWordWrapping
                    titleLabel.numberOfLines = 0
                    titleLabel.textAlignment = .Center
                    addSubview(titleLabel)

                    labels.addObject(titleLabel)

                    y += titleSize.height + margin
                    nextRow = 0
                    ++completedUpToRow

                    if y >= scrollViewBottom {
                        break
                    }
                    // NSLog("Title for section %d is %@", sectionNumber, title)
                }

                let numRows = section.numRows // another SQL query
                var row: Int
                for row=nextRow; row<numRows; ++row {
                    let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber)
                    let pointer : DubsarModelsPointer = pointerForRowAtIndexPath(indexPath)

                    let text = "\(pointer.targetText): \(pointer.targetGloss)" as NSString
                    let textSize = text.sizeOfTextWithConstrainedSize(constrainedSize, font: bodyFont)
                    let pointerLabel = PointerLabel(pointer: pointer, frame: CGRectMake(margin, y, constrainedSize.width, textSize.height))
                    pointerLabel.text = text
                    pointerLabel.viewController = viewController

                    addSubview(pointerLabel)
                    labels.addObject(pointerLabel)

                    y += textSize.height + margin

                    ++completedUpToRow

                    // NSLog("Pointer text for section %d, row %d is %@", sectionNumber, row, title)
                    if y >= scrollViewBottom {
                        finished = true
                        ++row
                        break
                    }
                }

                nextRow = row
            }

            if finished {
                break
            }
            nextRow = -1
        }
        nextSection = sectionNumber
        completedUpToY = y
    }

    func reset() {
        hasReset = true
    }

    func performReset() {
        for label : AnyObject in labels as NSArray {
            if let view = label as? UILabel {
                view.removeFromSuperview()
            }
        }
        labels.removeAllObjects()

        // in both cases, numberOfSections does an SQL query and builds the sections array
        if sense {
            numberOfSections = sense!.numberOfSections
            sections = sense!.sections
        }
        else {
            numberOfSections = synset.numberOfSections
            sections = synset.sections
        }

        totalRows = numberOfSections
        for object: AnyObject in sections as NSArray { // as NSArray? seriously?
            if let section = object as? DubsarModelsSection {
                totalRows += section.numRows
            }
        }
        completedUpToY = 0
        completedUpToRow = 0
        nextRow = -1
        nextSection = 0
   }
}
