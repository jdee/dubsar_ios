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

    var synset : DubsarModelsSynset!
    var sense : DubsarModelsSense? {
    didSet {
        setNeedsLayout()
    }
    }

    var headerView : SynsetHeaderView
    var sampleView : SynsetSampleView

    var viewController : SynsetViewController!

    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset
        headerView = SynsetHeaderView(synset: synset, frame: CGRectZero)
        sampleView = SynsetSampleView(synset: synset, frame: CGRectZero)
        super.init(frame: frame)

        headerView.frame = bounds
        headerView.delegate = viewController
        sampleView.frame = CGRectMake(0, headerView.bounds.size.height, bounds.size.width, bounds.size.height)

        bounces = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = true

        addSubview(headerView)
        addSubview(sampleView)
    }

    override func layoutSubviews() {
        if synset.complete {
            headerView.sense = sense
            sampleView.sense = sense

            headerView.layoutSubviews()
            sampleView.layoutSubviews()

            sampleView.frame.origin.y = headerView.bounds.size.height

            contentSize = CGSizeMake(headerView.bounds.size.width, headerView.bounds.size.height + sampleView.bounds.size.height)
        }

        super.layoutSubviews()
    }

}
