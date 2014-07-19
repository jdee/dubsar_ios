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

    var isEmpty : Bool {
    get {
        return synset.samples.count == 0
    }
    }

    var labels : NSMutableArray

    init(synset: DubsarModelsSynset!, frame: CGRect, preview: Bool) {
        self.synset = synset
        labels = NSMutableArray()
        isPreview = preview
        super.init(frame: frame)
        backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0)
    }

    override func layoutSubviews() {
        // NSLog("Entered SynsetSampleView.layoutSubviews()")
        for label : AnyObject in labels {
            if let l = label as? UILabel {
                label.removeFromSuperview()
            }
        }
        labels.removeAllObjects()

        if synset.complete {
            var y = SynsetSampleView.margin
            for sample : AnyObject in synset.samples as NSArray {
                if let text = sample as? String {
                    y = addSample(text, atY: y, background: UIColor.clearColor())
                    // NSLog("Added %@ at %f", text, y)
                }
            }

            if let s = sense {
                for verbFrame : AnyObject in s.verbFrames as NSArray {
                    if let text = verbFrame as? String {
                        y = addSample(text, atY: y, background: isPreview ? UIColor.clearColor() : UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0))
                        // NSLog("Added %@ at %f", text, y)
                    }
                }
            }

            frame.size.height = y
            // NSLog("sample view height: %f", bounds.size.height)
        }

        super.layoutSubviews()
    }

    func addSample(sample: NSString!, atY y: CGFloat, background: UIColor!) -> CGFloat {
        let margin = SynsetSampleView.margin
        let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin, bounds.size.height)
        let bodyFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let italicFontDescriptor = bodyFont.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitItalic)
        let italicFont = UIFont(descriptor: italicFontDescriptor, size: 0)
        let font = isPreview ? italicFont : bodyFont
        let textSize = sample.sizeOfTextWithConstrainedSize(constrainedSize, font: font)

        let label = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, textSize.height))
        label.font = font
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.text = sample
        label.backgroundColor = background

        labels.addObject(label)
        addSubview(label)

        return y + margin + textSize.height
    }

}
