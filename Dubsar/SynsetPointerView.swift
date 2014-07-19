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

class PointerView : UIView {
    let pointer : DubsarModelsPointer
    let button : NavButton
    let label : UILabel
    let withoutButton : Bool
    weak var viewController : SynsetViewController?

    init(pointer: DubsarModelsPointer!, frame: CGRect, withoutButton: Bool) {
        self.pointer = pointer
        button = NavButton()
        label = UILabel()
        self.withoutButton = withoutButton
        super.init(frame: frame)

        // clipsToBounds = true

        let fudge : CGFloat = 8
        let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let buttonSize = bodyFont.pointSize + fudge // height of one line in the body font, with a little extra space

        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.font = bodyFont
        label.frame = CGRectMake(0, 0, withoutButton ? bounds.size.width : bounds.size.width-buttonSize, bounds.size.height)

        addSubview(label)

        if withoutButton {
            return
        }

        addSubview(button)
        button.frame = CGRectMake(label.bounds.size.width, 0, buttonSize, buttonSize)

        button.addTarget(self, action: "navigate:", forControlEvents: .TouchUpInside)
    }

    @IBAction
    func navigate(sender: UIButton!) {
        var target : DubsarModelsModel
        // NSLog("Selected pointer targetType \"%@\", targetId %d", pointer.targetType, pointer.targetId)
        if pointer.targetType == "Sense" {
            // NSLog("Navigating to sense ID %d (%@)", pointer.targetId, pointer.targetText)
            target = DubsarModelsSense(id: pointer.targetId, name: nil, partOfSpeech: .Unknown)
        }
        else {
            // NSLog("Navigating to synset ID %d (%@)", pointer.targetId, pointer.targetText)
            target = DubsarModelsSynset(id: pointer.targetId, partOfSpeech: .Unknown)
        }

        if let spv = superview as? SynsetPointerView {
            spv.navigateToModel(target)
        }
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

    let isPreview : Bool

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

    init(synset: DubsarModelsSynset!, frame: CGRect, preview: Bool = false) {
        self.synset = synset
        isPreview = preview
        labels = NSMutableArray()
        super.init(frame: frame)
        clipsToBounds = true
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

                    let buttonSize = ("X" as NSString).sizeWithAttributes([NSFontAttributeName: bodyFont]).height // height of one line in the body font

                    var pointerConstrainedSize = constrainedSize
                    pointerConstrainedSize.width -= buttonSize

                    let text = "\(pointer.targetText): \(pointer.targetGloss)" as NSString
                    let textSize = text.sizeOfTextWithConstrainedSize(pointerConstrainedSize, font: bodyFont)
                    let pointerView = PointerView(pointer: pointer, frame: CGRectMake(margin, y, pointerConstrainedSize.width + buttonSize, textSize.height), withoutButton: isPreview)
                    pointerView.label.text = text
                    if pointer.targetType == "Sense" {
                        pointerView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0)
                    }
                    pointerView.viewController = viewController

                    addSubview(pointerView)
                    labels.addObject(pointerView)
                    pointerView.button.refreshImages() // do this after addSubview(). Otherwise, we have no graphics context and can't generate an image.

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
            if let view = label as? UIView {
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

    func navigateToModel(model: DubsarModelsModel?) {
        assert(model)
        viewController?.navigateToPointer(model)
    }
}
