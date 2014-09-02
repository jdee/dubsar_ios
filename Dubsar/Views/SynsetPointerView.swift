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

    required init(coder aDecoder: NSCoder) {
        pointer = DubsarModelsPointer()
        button = NavButton()
        label = UILabel()
        withoutButton = true
        super.init(coder: aDecoder)
    }

    init(pointer: DubsarModelsPointer!, frame: CGRect, withoutButton: Bool) {
        self.pointer = pointer
        button = NavButton()
        label = UILabel()
        self.withoutButton = withoutButton
        super.init(frame: frame)

        // clipsToBounds = true

        let fudge : CGFloat = 8
        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let buttonSize = bodyFont.pointSize + fudge // height of one line in the body font, with a little extra space

        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.font = bodyFont
        label.textColor = AppConfiguration.foregroundColor
        label.frame = CGRectMake(0, 0, withoutButton ? bounds.size.width : bounds.size.width-buttonSize, bounds.size.height)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)

        addSubview(label)

        var constraint: NSLayoutConstraint
        constraint = NSLayoutConstraint(item: label, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: label, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)

        if withoutButton {
            constraint = NSLayoutConstraint(item: label, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
            addConstraint(constraint)
            return
        }

        addSubview(button)
        button.frame = CGRectMake(label.bounds.size.width, 0, buttonSize, buttonSize)

        button.addTarget(self, action: "navigate:", forControlEvents: .TouchUpInside)
        button.setTranslatesAutoresizingMaskIntoConstraints(false)

        constraint = NSLayoutConstraint(item: button, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: button, attribute: .Leading, relatedBy: .Equal, toItem: label, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: button, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 0.0, constant: buttonSize)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: button, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 0.0, constant: buttonSize)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: label, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: -buttonSize)
        addConstraint(constraint)
    }

    override func intrinsicContentSize() -> CGSize {
        return bounds.size
    }

    @IBAction
    func navigate(sender: UIButton!) {
        var target : DubsarModelsModel
        // DMLOG("Selected pointer targetType \"%@\", targetId %d", pointer.targetType, pointer.targetId)
        if pointer.targetType == "Sense" || pointer.targetType == "sense" {
            // DMLOG("Navigating to sense ID %d (%@)", pointer.targetId, pointer.targetText)
            let sense = DubsarModelsSense(id: pointer.targetId, name: nil, partOfSpeech: .Unknown)
            sense.synset = DubsarModelsSynset(id: pointer.targetSynsetId, partOfSpeech: .Unknown)
            target = sense
        }
        else {
            // DMLOG("Navigating to synset ID %d (%@)", pointer.targetId, pointer.targetText)
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

    var labels : [UIView] = []
    var myConstraints = [NSLayoutConstraint]()

    var scrollViewTop : CGFloat = 0
    var scrollViewBottom : CGFloat = 0

    weak var viewController : SynsetViewController?

    var layoutMode = false

    private var hasReset : Bool = true
    private var numberOfSections : UInt = 0
    private var sections : [AnyObject] = []
    private var totalRows : UInt = 0
    private var completedUpToY : CGFloat = 0
    private var completedUpToRow : Int = 0
    private var nextSection : Int = 0
    private var nextRow : Int = -1

    init(synset: DubsarModelsSynset!, frame: CGRect, preview: Bool = false) {
        self.synset = synset
        isPreview = preview
        super.init(frame: frame)
        clipsToBounds = true
    }

    required init(coder aDecoder: NSCoder) {
        synset = DubsarModelsSynset()
        isPreview = true
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        if synset.complete || (sense != nil && sense!.complete) {
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
            if (scrollViewBottom > 0.0 && completedUpToY >= scrollViewBottom) || nextSection == Int(numberOfSections) {
                // nothing to do.
                super.layoutSubviews()
                return
            }

            tileViewport()

            // now estimate
            frame.size.height = completedUpToY * CGFloat(totalRows) / CGFloat(completedUpToRow)
            DMTRACE("completed up to y: \(completedUpToY), row: \(completedUpToRow), total rows \(totalRows), est. total height: \(frame.size.height)")
            invalidateIntrinsicContentSize()
        }

        hasReset = false
        super.layoutSubviews()
    }

    func navigateToModel(model: DubsarModelsModel?) {
        assert(model != nil)
        viewController?.navigateToPointer(model)
    }

    func reset() {
        hasReset = true
    }

    override func intrinsicContentSize() -> CGSize {
        return bounds.size
    }

    private func pointerForRowAtIndexPath(indexPath: NSIndexPath!) -> DubsarModelsPointer {
        // could use a base class or a protocol here
        DMTRACE("Calling pointerForRowAtIndexPath:")
        if let s = sense {
            assert(indexPath != nil)
            return s.pointerForRowAtIndexPath(indexPath)
        }
        else if synset.senses.count == 1 {
            let firstSense = synset.senses.firstObject as DubsarModelsSense
            return firstSense.pointerForRowAtIndexPath(indexPath)
        }
        return synset.pointerForRowAtIndexPath(indexPath)
    }

    private func tileViewport() {
        DMTRACE("Tiling down to y = \(scrollViewBottom)")
        // convenient constants
        let margin = SynsetPointerView.margin
        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        let titleFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin, bounds.size.height)

        // y is where the next tile will go (frame.origin.y)
        var y : CGFloat = margin + completedUpToY

        var sectionNumber: Int
        var finished = false
        for sectionNumber = nextSection; sectionNumber < Int(numberOfSections); ++sectionNumber {
            let section = sections[sectionNumber] as DubsarModelsSection
            if nextRow == -1 {
                let title = section.header as NSString
                let titleSize = title.sizeOfTextWithConstrainedSize(constrainedSize, font: titleFont)
                if !layoutMode {
                    let titleLabel = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, titleSize.height))
                    titleLabel.font = titleFont
                    titleLabel.text = title
                    titleLabel.lineBreakMode = .ByWordWrapping
                    titleLabel.numberOfLines = 0
                    titleLabel.textAlignment = .Center
                    titleLabel.textColor = AppConfiguration.foregroundColor
                    titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
                    addSubview(titleLabel)

                    let previousLabel: UIView? = labels.isEmpty ? nil : ((labels as NSArray).lastObject as UIView)

                    labels.append(titleLabel)

                    var constraint = NSLayoutConstraint(item: titleLabel, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: margin)
                    addConstraint(constraint)
                    myConstraints.append(constraint)

                    constraint = NSLayoutConstraint(item: titleLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: -margin)
                    addConstraint(constraint)
                    myConstraints.append(constraint)

                    if previousLabel != nil {
                        constraint = NSLayoutConstraint(item: titleLabel, attribute: .Top, relatedBy: .Equal, toItem: previousLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
                    }
                    else {
                        constraint = NSLayoutConstraint(item: titleLabel, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: margin)
                    }
                    addConstraint(constraint)
                    myConstraints.append(constraint)

                }

                y += titleSize.height + margin
                nextRow = 0
                ++completedUpToRow

                if scrollViewBottom > 0.0 && y >= scrollViewBottom {
                    break
                }
                DMTRACE("Title for section \(sectionNumber) is \(title)")
            }

            let fudge : CGFloat = 8
            let buttonSize = isPreview ? 0 : bodyFont.pointSize + fudge // height of one line in the body font

            var pointerConstrainedSize = constrainedSize
            pointerConstrainedSize.width -= buttonSize

            let numRows = section.numRows // another SQL query
            var row: Int
            for row=nextRow; row<Int(numRows); ++row {
                let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber)
                let pointer : DubsarModelsPointer = pointerForRowAtIndexPath(indexPath)

                let text = "\(pointer.targetText): \(pointer.targetGloss)" as NSString
                let textSize = text.sizeOfTextWithConstrainedSize(pointerConstrainedSize, font: bodyFont)
                DMTRACE("Pointer text size is \(textSize.width) x \(textSize.height)/\(constrainedSize.height) (font: \(bodyFont.pointSize) pt.)")

                if !layoutMode {
                    let pointerView = PointerView(pointer: pointer, frame: CGRectMake(margin, y, constrainedSize.width, textSize.height), withoutButton: isPreview)
                    pointerView.label.text = text
                    if !isPreview && pointer.targetType == "Sense" {
                        pointerView.backgroundColor = AppConfiguration.highlightColor
                    }
                    pointerView.viewController = viewController
                    pointerView.setTranslatesAutoresizingMaskIntoConstraints(false)

                    addSubview(pointerView)

                    let previousLabel: UIView = (labels as NSArray).lastObject as UIView
                    labels.append(pointerView)
                    pointerView.button.refreshImages() // do this after addSubview(). Otherwise, we have no graphics context and can't generate an image.

                    var constraint = NSLayoutConstraint(item: pointerView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: margin)
                    addConstraint(constraint)
                    myConstraints.append(constraint)

                    constraint = NSLayoutConstraint(item: pointerView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: -margin)
                    addConstraint(constraint)
                    myConstraints.append(constraint)

                    constraint = NSLayoutConstraint(item: pointerView, attribute: .Top, relatedBy: .Equal, toItem: previousLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
                    addConstraint(constraint)
                    myConstraints.append(constraint)

                }

                DMTRACE("Pointer text for section \(sectionNumber), row \(row) is \(text). y = \(y). height = \(textSize.height). bottom = \(y + textSize.height). scrollViewBottom = \(scrollViewBottom)")

                y += textSize.height + margin

                ++completedUpToRow

                if scrollViewBottom > 0.0 && y >= scrollViewBottom {
                    finished = true
                    ++row
                    break
                }
            }

            nextRow = row

            if finished {
                break
            }
            nextRow = -1
        }
        nextSection = sectionNumber
        completedUpToY = y - margin

        //*
        let lastLabel = (labels as NSArray).lastObject as? UIView
        if lastLabel != nil {
            var constraint = NSLayoutConstraint(item: lastLabel!, attribute: .Bottom, relatedBy: .LessThanOrEqual, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: -margin)
            addConstraint(constraint)
            myConstraints.append(constraint)
        }
        // */
    }

    private func performReset() {
        for view in labels {
            view.removeFromSuperview()
        }
        labels = []

        for constraint in myConstraints {
            removeConstraint(constraint)
        }
        myConstraints = []

        // in both cases, numberOfSections does an SQL query and builds the sections array
        if sense != nil {
            numberOfSections = sense!.numberOfSections
            sections = sense!.sections
        }
        else if synset.senses.count == 1 {
            let firstSense = synset.senses.firstObject as DubsarModelsSense
            numberOfSections = firstSense.numberOfSections
            sections = firstSense.sections
        }
        else {
            numberOfSections = synset.numberOfSections
            sections = synset.sections
        }

        totalRows = numberOfSections
        for section in sections as [DubsarModelsSection] {
            totalRows += section.numRows
        }
        completedUpToY = 0
        completedUpToRow = 0
        nextRow = -1
        nextSection = 0
    }

}
