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

import UIKit

class GlobButton: UIButton {
    var globExpression: String!
}

class AlphabetView: UIView {

    class var margin : CGFloat {
        get {
            return 2
        }
    }

    class var buttonConfig : [(String,String)] {
        get {
            return [ ("AB", "[ABab]*"),
                     ("CD", "[CDcd]*"),
                     ("EF", "[EFef]*"),
                     ("GH", "[GHgh]*"),
                     ("IJ", "[IJij]*"),
                     ("KL", "[KLkl]*"),
                     ("MN", "[MNmn]*"),
                     ("OP", "[OPop]*"),
                     ("QR", "[QRqr]*"),
                     ("ST", "[STst]*"),
                     ("UV", "[UVuv]*"),
                     ("WX", "[WXwx]*"),
                     ("YZ", "[YZyz]*"),
                     ("...", "[^A-Za-z]*") ]
        }
    }

    //*
    var font : UIFont! {
    get {
        return getFont()
    }
    }
    // */

    var buttons: [GlobButton] = []
    weak var viewController: MainViewController?

    init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        let horizontal = frame.size.width > frame.size.height

        let fontToUse = getFont() // avoid computing more than once
        let viewSize = viewSizeAtFontSize(fontToUse.pointSize)

        let letterHeight = ("Q" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).height // Q has a small tail
        let letterWidth = ("W" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).width // W for Wide Load
        let margin = AlphabetView.margin

        for button in buttons {
            button.removeFromSuperview()
        }
        buttons = []

        var position = margin
        if horizontal {
            position = 0.5 * (bounds.size.width - viewSize)
        }

        let buttonConfig = AlphabetView.buttonConfig

        for (label, globExpression) in buttonConfig {
            var x: CGFloat = 0, y: CGFloat = 0
            if horizontal {
                x = position
                y = margin

                position += 2 * letterWidth
            }
            else {
                x = margin
                y = position

                position += letterHeight
            }
            position += margin

            let button = GlobButton(frame: CGRectMake(x, y, 2 * letterWidth, letterHeight))
            button.globExpression = globExpression
            button.titleLabel.font = fontToUse
            button.setTitle(String(label), forState: .Normal)
            button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            button.setTitleColor(UIColor.blueColor(), forState: .Highlighted)
            button.addTarget(self, action: "buttonPressed:", forControlEvents: .TouchUpInside)

            buttons += button
            addSubview(button)
        }

        if horizontal {
            let height = letterHeight + 2 * margin
            let delta = frame.size.height - height
            frame.size.height = height
            frame.origin.y += delta
        }
        else {
            let width = 2 * letterWidth + 2 * margin
            let delta = frame.size.width - width
            frame.size.width = width
            frame.origin.x += delta
        }

        super.layoutSubviews()
    }

    @IBAction
    func buttonPressed(sender: GlobButton!) {
        viewController?.alphabetView(self, selectedButton: sender)
    }

    private func getFont() -> UIFont! {
        let horizontal = frame.size.width > frame.size.height
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        let headlineFontSize = fontDescriptor.pointSize
        // NSLog("Headline font size is %f", Float(headlineFontSize))

        // whatever fits the form factor, but never larger than the current headline font
        // fortunately, there are only three relevant device sizes, in points:
        // 320 x 480, 320 x 568, 768 x 1024.
        // 14 is the smallest available headline size, and it fits all screens in any orientation
        // 23 is the largest ordinary headline size.
        // TODO: Support extra-large accessibility fonts.
        let sizes: [CGFloat] = [ 48, 36, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14 ]

        var fontToUse: UIFont!
        for fontSize in sizes {
            if fontSize > headlineFontSize {
                continue
            }

            let viewSize = viewSizeAtFontSize(fontSize)

            if (horizontal && viewSize < bounds.size.width) || (!horizontal && viewSize < bounds.size.height) {
                return UIFont(descriptor: fontDescriptor, size: fontSize)
            }
        }

        return UIFont(descriptor: fontDescriptor, size: 0.0) // shouldn't really get here, but use the headline font size
    }

    private func viewSizeAtFontSize(fontSize: CGFloat) -> CGFloat {
        let horizontal = frame.size.width > frame.size.height
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        let fontToUse = UIFont(descriptor: fontDescriptor, size: fontSize)
        let margin = AlphabetView.margin
        let labelCount = CGFloat(AlphabetView.buttonConfig.count)
        let letterHeight = ("Q" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).height // Q has a small tail
        let letterWidth = ("W" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).width // W for Wide Load

        if horizontal {
            return (labelCount + 1) * margin + 2 * labelCount * letterWidth
        }
        return (labelCount + 1) * margin + labelCount * letterHeight
    }

}
