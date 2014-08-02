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

class OpenSenseTableViewCell: SenseTableViewCell {
    var insertHeightLimit : CGFloat

    class var openIdentifier : String {
        get {
            return "opensense"
        }
    }

    init(sense: DubsarModelsSense!, frame: CGRect, maxHeightOfAdditions: CGFloat) {
        insertHeightLimit = maxHeightOfAdditions
        super.init(sense: sense, frame: frame, identifier: OpenSenseTableViewCell.openIdentifier)
    }

    override func rebuild() {
        super.rebuild()

        backgroundColor = backgroundLabel.backgroundColor

        let borderWidth = SenseTableViewCell.borderWidth
        let margin = SenseTableViewCell.margin
        let accessoryWidth = SenseTableViewCell.accessoryWidth

        let constrainedSize = CGSizeMake(frame.size.width-2*borderWidth-2*margin-SenseTableViewCell.accessoryWidth, frame.size.height)

        var y = bounds.size.height

        let sampleView = SynsetSampleView(synset: sense.synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, bounds.size.height), preview: true)
        sampleView.sense = sense
        backgroundLabel.addSubview(sampleView)
        sampleView.layoutSubviews()

        sampleView.backgroundColor = UIColor.clearColor()

        var available = insertHeightLimit
        if available > 0 {
            // NSLog("available = %f", available)
            if sampleView.bounds.size.height > available {
                // NSLog("sampleView size of %f truncated", sampleView.bounds.size.height)
                sampleView.frame.size.height = available
            }
            available -= sampleView.bounds.size.height
            // NSLog("available reduced to %f", available)
            if available <= 0 {
                // used up all our space. don't insert the pointer view
                frame.size.height += sampleView.bounds.size.height
                view!.frame.size.height = bounds.size.height
                // NSLog("No pointer view. sample view height is %f. frame height is now %f", sampleView.bounds.size.height, bounds.size.height)
                addGradientToBottomOfView(view)
                return
            }
        }

        frame.size.height += sampleView.bounds.size.height
        y = bounds.size.height

        // NSLog("sample view height is %f. frame height is now %f (remaining insertHeightLimit: %f)", Double(sampleView.bounds.size.height), Double(frame.size.height), Double(available))

        let pointerView = SynsetPointerView(synset: sense.synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, bounds.size.height), preview: true)
        pointerView.sense = sense
        pointerView.scrollViewTop = 0
        pointerView.scrollViewBottom = available
        pointerView.backgroundColor = UIColor.clearColor()
        backgroundLabel.addSubview(pointerView)
        pointerView.layoutSubviews()

        var truncated = false

        if available > 0 {
            // NSLog("available = %f", available)
            if pointerView.bounds.size.height > available {
                // NSLog("pointerView size of %f truncated", pointerView.bounds.size.height)
                pointerView.frame.size.height = available
                truncated = true
            }
        }

        frame.size.height += pointerView.bounds.size.height
        view!.frame.size.height = bounds.size.height

        // NSLog("pointer view height is %f. frame height is now %f", Double(pointerView.bounds.size.height), Double(frame.size.height))

        if truncated {
            addGradientToBottomOfView(view)
        }
    }

    private func addGradientToBottomOfView(aView: UIView!) {
        let topColor = backgroundColor;
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        topColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let bottomColor = UIColor(hue: hue, saturation: saturation, brightness: 0.3 * brightness, alpha: alpha)

        let gradientHeight: CGFloat = 20
        let gradientView = GradientView(frame: CGRectMake(0, aView.bounds.size.height - gradientHeight, aView.bounds.width, gradientHeight), firstColor: topColor, secondColor: bottomColor, startPoint: CGPointMake(0, 0), endPoint: CGPointMake(0, gradientHeight))
        gradientView.opaque = false
        gradientView.alpha = 0.4
        gradientView.autoresizingMask = .FlexibleWidth | .FlexibleTopMargin

        // NSLog("Added gradient at %f", Double(gradientView.frame.origin.y))
        aView.addSubview(gradientView)
    }
}
