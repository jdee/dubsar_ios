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

class ScrollingSynsetView: UIScrollView {

    let synset : DubsarModelsSynset
    var sense : DubsarModelsSense? {
    didSet {
        if sense == nil && synset.senses.count == 1 {
            let firstSense = synset.senses.firstObject as DubsarModelsSense
            headerView.sense = firstSense
            sampleView.sense = firstSense
            pointerView.sense = firstSense
        }
        else {
            headerView.sense = sense
            sampleView.sense = sense
            pointerView.sense = sense
        }
        reset()
        setNeedsLayout()
    }
    }

    let headerView : SynsetHeaderView
    let sampleView : SynsetSampleView
    let pointerView : SynsetPointerView

    private var hasReset : Bool = true
    private var hasPointers = false

    var viewController : SynsetViewController! {
    didSet {
        // these views have navigation options
        headerView.delegate = viewController
        pointerView.viewController = viewController
    }
    }

    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset
        headerView = SynsetHeaderView(synset: synset, frame: CGRectZero)
        sampleView = SynsetSampleView(synset: synset, frame: CGRectZero, preview: false)
        pointerView = SynsetPointerView(synset: synset, frame: CGRectZero, preview: false)
        super.init(frame: frame)

        //*
        headerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        sampleView.setTranslatesAutoresizingMaskIntoConstraints(false)
        pointerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        // */

        bounces = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = true

        addSubview(headerView)
        addSubview(sampleView)
        addSubview(pointerView)

        //*
        var constraint: NSLayoutConstraint
        constraint = NSLayoutConstraint(item: headerView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: headerView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: headerView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: headerView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: sampleView, attribute: .Top, relatedBy: .Equal, toItem: headerView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: sampleView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: sampleView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: sampleView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: pointerView, attribute: .Top, relatedBy: .Equal, toItem: sampleView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: pointerView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: pointerView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: pointerView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: pointerView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)
        // */
    }

    required init(coder aDecoder: NSCoder) {
        synset = DubsarModelsSynset()
        headerView = SynsetHeaderView(synset: synset, frame: CGRectZero)
        sampleView = SynsetSampleView(synset: synset, frame: CGRectZero, preview: true)
        pointerView = SynsetPointerView(synset: synset, frame: CGRectZero)
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        backgroundColor = AppConfiguration.backgroundColor

        DMTRACE("contentOffset: (\(contentOffset.x), \(contentOffset.y))")
        if synset.complete {
            DMTRACE("Entered ScrollingSynsetView.layoutSubviews(). size: \(bounds.size.width) x \(bounds.size.height)")

            if hasReset {
                hasReset = false

                let firstSense = synset.senses.firstObject as DubsarModelsSense
                hasPointers = (sense != nil && sense!.complete && sense!.numberOfSections > 0) || (sense == nil && firstSense.complete && firstSense.numberOfSections > 0) || synset.numberOfSections > 0

                // these automatically adjust their heights in layoutSubviews()
                headerView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height)
                DMTRACE("Header view size: \(bounds.size.width) x \(bounds.size.height)")
                headerView.layoutSubviews()

                sampleView.frame = CGRectMake(0, headerView.bounds.size.height, bounds.size.width, bounds.size.height)
                sampleView.layoutSubviews()

                if hasPointers {
                    pointerView.frame = CGRectMake(0, headerView.bounds.size.height + sampleView.bounds.size.height, bounds.size.width, bounds.size.height)
                }
            }

            if hasPointers {
                // vertical screen bounds in the pointerView's coordinate system
                let originY = sampleView.frame.origin.y + sampleView.bounds.size.height
                DMTRACE("originY: \(originY), bounds.size.height: \(bounds.size.height)")
                pointerView.scrollViewTop = contentOffset.y - originY
                pointerView.scrollViewBottom = pointerView.scrollViewTop + bounds.size.height
                pointerView.layoutSubviews()

                /*
                contentSize = CGSizeMake(bounds.size.width, headerView.bounds.size.height + sampleView.bounds.size.height + pointerView.bounds.size.height)
            }
            else {
                contentSize = CGSizeMake(bounds.size.width, headerView.bounds.size.height + sampleView.bounds.size.height)
                // */
            }

            DMTRACE("header size: \(headerView.bounds.size.width) x \(headerView.bounds.size.height), sample size: \(sampleView.bounds.size.width) x \(sampleView.bounds.size.height), pointer size: \(pointerView.bounds.size.width) x \(pointerView.bounds.size.height)")

            invalidateIntrinsicContentSize()
        }

        super.layoutSubviews()
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(sampleView.intrinsicContentSize().width, headerView.intrinsicContentSize().height + sampleView.intrinsicContentSize().height + pointerView.intrinsicContentSize().height)
    }

    func reset() {
        hasReset = true
        pointerView.reset()
        setNeedsLayout()
    }

}
