/*
Dubsar Dictionary Project
Copyright (C) 2010-15 Jimmy Dee

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

    init(sense: DubsarModelsSense!, frame: CGRect, maxHeightOfAdditions: CGFloat, identifier: String = OpenSenseTableViewCell.openIdentifier) {
        insertHeightLimit = maxHeightOfAdditions
        super.init(sense: sense, frame: frame, identifier: identifier)
    }

    required init(coder aDecoder: NSCoder) {
        insertHeightLimit = 0
        super.init(coder: aDecoder)
    }

    override func rebuild() {
        super.rebuild()

        var y = bounds.size.height

        DMTRACE("Height of sense header \(y)")

        if (synset != nil && !synset!.complete) || (synset == nil && !sense.complete) {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
            view!.addSubview(spinner)
            spinner.startAnimating()
            spinner.frame = CGRectMake(2.0, y + 2.0, 40.0, 40.0)

            frame.size.height += 44
            view!.frame.size.height = bounds.size.height

            return
        }

        let lastSubview = (view!.subviews as NSArray).lastObject as UIView

        let accessoryWidth = SenseTableViewCell.accessoryWidth

        let sampleView = SynsetSampleView(synset: synset != nil ? synset : sense.synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, UIScreen.mainScreen().bounds.size.height), preview: true)
        sampleView.sense = sense
        sampleView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view!.addSubview(sampleView)
        sampleView.layoutSubviews()

        sampleView.backgroundColor = UIColor.clearColor()
        sampleView.layer.borderColor = UIColor.greenColor().CGColor
        sampleView.layer.borderWidth = 0

        var constraint = NSLayoutConstraint(item: sampleView, attribute: .Top, relatedBy: .Equal, toItem: lastSubview, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: sampleView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: sampleView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -accessoryWidth)
        view!.addConstraint(constraint)

        var available = insertHeightLimit
        if available > 0 {
            DMTRACE("available = \(available)")
            if sampleView.bounds.size.height > available {
                DMTRACE("sampleView size of \(sampleView.bounds.size.height) truncated")
                sampleView.frame.size.height = available
            }
            available -= sampleView.bounds.size.height
            DMTRACE("available reduced to \(available)")
            if available <= 0 {
                // used up all our space. don't insert the pointer view
                frame.size.height += sampleView.bounds.size.height
                view!.frame.size.height = bounds.size.height
                DMTRACE("No pointer view. sample view height is \(sampleView.bounds.size.height). frame height is now \(bounds.size.height)")
                addGradientToBottomOfView(view)
                return
            }
        }

        frame.size.height += sampleView.bounds.size.height
        view!.frame.size.height = bounds.size.height

        let numberOfSections = synset != nil ? synset!.numberOfSections : sense.numberOfSections
        if numberOfSections == 0 {
            return
        }

        y = bounds.size.height

        DMTRACE("sample view height is \(sampleView.bounds.size.height). frame height is now \(frame.size.height) (remaining insertHeightLimit: \(available))")

        let pointerView = SynsetPointerView(synset: synset != nil ? synset : sense.synset, frame: CGRectMake(0, y, bounds.size.width - accessoryWidth, UIScreen.mainScreen().bounds.size.height), preview: true)
        pointerView.sense = sense
        pointerView.scrollViewTop = 0
        pointerView.scrollViewBottom = available
        pointerView.backgroundColor = UIColor.clearColor()
        pointerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        pointerView.layer.borderColor = UIColor.yellowColor().CGColor
        pointerView.layer.borderWidth = 0
        view!.addSubview(pointerView)
        pointerView.layoutSubviews()

        constraint = NSLayoutConstraint(item: pointerView, attribute: .Top, relatedBy: .Equal, toItem: sampleView, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: pointerView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        view!.addConstraint(constraint)
        constraint = NSLayoutConstraint(item: pointerView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: -accessoryWidth)
        view!.addConstraint(constraint)

        var truncated = false

        if available > 0 {
            DMTRACE("available = \(available)")
            if pointerView.bounds.size.height > available {
                DMTRACE("pointerView size of \(pointerView.bounds.size.height) truncated")
                pointerView.frame.size.height = available
                truncated = true
            }
        }

        frame.size.height += pointerView.bounds.size.height
        view!.frame.size.height = bounds.size.height

        DMTRACE("pointer view frame is (\(pointerView.frame.origin.x), \(pointerView.frame.origin.y)) \(pointerView.bounds.size.width) x \(pointerView.bounds.size.height). frame height is now \(frame.size.height)")

        if truncated {
            addGradientToBottomOfView(view)
        }
    }

    func removeView() -> UIView! {
        var constraint = NSLayoutConstraint(item: view!, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
        contentView.removeConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Leading, relatedBy: .Equal, toItem: contentView, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        contentView.removeConstraint(constraint)
        constraint = NSLayoutConstraint(item: view!, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        contentView.removeConstraint(constraint)
        constraint = NSLayoutConstraint(item: contentView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        contentView.removeConstraint(constraint)

        contentView.removeConstraints(contentView.constraints())

        view!.removeFromSuperview()
        view!.setTranslatesAutoresizingMaskIntoConstraints(false)
        view!.clipsToBounds = true
        return view
    }

    private func addGradientToBottomOfView(aView: UIView!) {
        let topColor = UIColor.clearColor()
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        topColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // let bottomColor = UIColor(hue: hue, saturation: saturation, brightness: brightness > 0.5 ? 0.3 * brightness : 2.0 * brightness, alpha: alpha)
        let bottomColor = UIColor.blackColor()

        let gradientHeight: CGFloat = 8
        let gradientView = GradientView(frame: CGRectMake(0, aView.bounds.size.height - gradientHeight, aView.bounds.width, gradientHeight), firstColor: topColor, secondColor: bottomColor, startPoint: CGPointMake(0, 0), endPoint: CGPointMake(0, gradientHeight))
        gradientView.opaque = false
        gradientView.alpha = 0.333
        gradientView.autoresizingMask = .FlexibleWidth | .FlexibleTopMargin

        DMTRACE("Added gradient at \(gradientView.frame.origin.y)")
        aView.addSubview(gradientView)
    }
}
