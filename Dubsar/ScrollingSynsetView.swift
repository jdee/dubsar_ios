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
        headerView.sense = sense
        sampleView.sense = sense
        pointerView.sense = sense
        reset()
        setNeedsLayout()
    }
    }

    let headerView : SynsetHeaderView
    let sampleView : SynsetSampleView
    let pointerView : SynsetPointerView

    var hasReset : Bool = false

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
        sampleView = SynsetSampleView(synset: synset, frame: CGRectZero)
        pointerView = SynsetPointerView(synset: synset, frame: CGRectZero)
        super.init(frame: frame)

        headerView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        sampleView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        pointerView.autoresizingMask = .FlexibleHeight | .FlexibleWidth

        bounces = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = true

        addSubview(headerView)
        addSubview(sampleView)
        addSubview(pointerView)
    }

    override func layoutSubviews() {
        // NSLog("contentOffset: (%f, %f)", contentOffset.x, contentOffset.y)
        if synset.complete {
            // NSLog("Entered ScrollingSynsetView.layoutSubviews()")

            if hasReset {
                // these automatically adjust their heights in layoutSubviews()
                headerView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height)
                headerView.layoutSubviews()

                sampleView.frame = CGRectMake(0, headerView.bounds.size.height, bounds.size.width, bounds.size.height)
                sampleView.layoutSubviews()

                pointerView.frame = CGRectMake(0, headerView.bounds.size.height + sampleView.bounds.size.height, bounds.size.width, bounds.size.height)
            }
            // vertical screen bounds in the pointerView's coordinate system
            pointerView.scrollViewTop = contentOffset.y - pointerView.frame.origin.y
            pointerView.scrollViewBottom = pointerView.scrollViewTop + bounds.size.height
            pointerView.layoutSubviews()

            let totalSize = CGSizeMake(bounds.size.width, headerView.bounds.size.height + sampleView.bounds.size.height + pointerView.bounds.size.height)
            contentSize = totalSize

            // NSLog("Set scrolling content size to %f x %f. header ht: %f, sample ht: %f, pointer ht: %f", totalSize.width, totalSize.height, headerView.bounds.size.height, sampleView.bounds.size.height, pointerView.bounds.size.height)

            hasReset = false
        }

        super.layoutSubviews()
    }

    func reset() {
        hasReset = true
        pointerView.reset()
    }

}
