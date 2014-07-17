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
            return 4
        }
    }

    var synset : DubsarModelsSynset
    var sense : DubsarModelsSense?

    var isEmpty : Bool {
    get {
        return synset.samples.count == 0
    }
    }

    var labels : NSMutableArray

    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset
        labels = NSMutableArray()
        super.init(frame: frame)

        layoutSubviews()
    }

    override func layoutSubviews() {
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
                    y = addSample(text, atY: y)
                }
            }

            if let s = sense {
                for verbFrame : AnyObject in s.verbFrames as NSArray {
                    if let text = verbFrame as? String {
                        y = addSample(text, atY: y)
                    }
                }
            }

            frame.size.height = y
        }


        super.layoutSubviews()
    }

    func addSample(sample: NSString!, atY y: CGFloat) -> CGFloat {
        let margin = SynsetSampleView.margin
        let constrainedSize = CGSizeMake(bounds.size.width - 2 * margin, bounds.size.height)
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let textSize = sample.sizeOfTextWithConstrainedSize(constrainedSize, font: font)

        let label = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, textSize.height))
        label.font = font
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.text = sample
        label.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        label.invalidateIntrinsicContentSize()

        labels.addObject(label)
        addSubview(label)

        return y + margin + textSize.height
    }

}
