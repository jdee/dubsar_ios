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

class SynsetSampleView: UIView {

    class var margin : CGFloat {
        get {
            return 8
        }
    }

    let synset : DubsarModelsSynset
    var sense : DubsarModelsSense?
    let isPreview : Bool

    var layoutMode = false

    var labels : [UILabel] = []
    var myConstraints = [NSLayoutConstraint]()

    init(synset: DubsarModelsSynset!, frame: CGRect, preview: Bool) {
        self.synset = synset
        isPreview = preview
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        DMTRACE("Entered SynsetSampleView.layoutSubviews()")
        for label in labels {
            label.removeFromSuperview()
        }
        labels = []

        for constraint in myConstraints {
            removeConstraint(constraint)
        }
        myConstraints = []

        var samples = [AnyObject]()
        if synset.complete {
            samples = synset.samples
        }
        else if sense && sense!.complete {
            samples = sense!.samples
        }

        var y = SynsetSampleView.margin

        let bodyFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)
        var font = bodyFont
        if isPreview {
            let italicFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody, italic: true)
            font = italicFont
        }
        else {
            backgroundColor = AppConfiguration.alternateHighlightColor
        }

        for sample in samples as [NSString] {
            y = addSample(sample, atY: y, background: UIColor.clearColor(), font: font)
            DMTRACE("Added \(sample) at \(y)")
        }

        /*
        * Always include lexical info when displaying synsets with only one word.
        */
        let verbFrames : NSArray? = sense ? sense!.verbFrames : synset.senses.count == 1 ? (synset.senses.firstObject as DubsarModelsSense).verbFrames : nil
        if verbFrames && verbFrames!.count > 0 {
            let frames = verbFrames as [AnyObject]
            for verbFrame in frames as [NSString] {
                y = addSample(verbFrame, atY: y, background: isPreview ? UIColor.clearColor() : AppConfiguration.highlightColor, font: font)
                DMTRACE("Added \(verbFrame) at \(y)")
            }
        }

        if !labels.isEmpty {
            var lastLabel = labels[labels.count - 1]
            var constraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: lastLabel, attribute: .Bottom, multiplier: 1.0, constant: SynsetSampleView.margin)
            addConstraint(constraint)
            myConstraints.append(constraint)
        }

        frame.size.height = y
        DMTRACE("sample view height: \(bounds.size.height)")

        super.layoutSubviews()
    }

    private func addSample(sample: NSString!, atY y: CGFloat, background: UIColor!, font: UIFont!) -> CGFloat {
        let margin = SynsetSampleView.margin
        let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin, bounds.size.height)
        let textSize = sample.sizeOfTextWithConstrainedSize(constrainedSize, font: font)

        var previousLabel: UILabel?
        if labels.count > 0 {
            previousLabel = labels[labels.count - 1]
        }

        if !layoutMode {
            let label = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, textSize.height))
            label.font = font
            label.lineBreakMode = .ByWordWrapping
            label.numberOfLines = 0
            label.text = sample
            label.textColor = AppConfiguration.foregroundColor
            label.backgroundColor = background
            label.setTranslatesAutoresizingMaskIntoConstraints(false)
            label.textAlignment = .Left

            labels += label
            addSubview(label)

            var constraint = NSLayoutConstraint(item: label, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: margin)
            addConstraint(constraint)
            myConstraints.append(constraint)

            constraint = NSLayoutConstraint(item: label, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: -margin)
            addConstraint(constraint)
            myConstraints.append(constraint)

            if previousLabel {
                constraint = NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: previousLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
            }
            else {
                constraint = NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: margin)
            }
            addConstraint(constraint)
            myConstraints.append(constraint)
        }

        return y + margin + textSize.height
    }

}
