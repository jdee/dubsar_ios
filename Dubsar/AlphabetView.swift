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

class AlphabetView: UIView {

    class var margin : CGFloat {
        get {
            return 2
        }
    }

    var font : UIFont! {
    get {
        return getFont()
    }
    }

    var buttons: [UIButton] = []
    weak var viewController: MainViewController?

    init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func layoutSubviews() {
        let horizontal = frame.size.width > frame.size.height

        let fontToUse = font // avoid computing twice
        let letterHeight = ("Q" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).height // Q has a small tail
        let letterWidth = ("W" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).width // W for Wide Load
        let margin = AlphabetView.margin

        for button in buttons {
            button.removeFromSuperview()
        }
        buttons = []

        var position = margin

        // C (1972):
        // for (char letter='A'; letter <= 'Z'; ++ letter) {

        // Ruby (1995):
        // [A..Z].each { |letter|

        // drum roll, please

        // Swift (2014):
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" // Hope I didn't mistype that. And never accidentally modify it.
        assert(countElements(alphabet) == 26) // better check, and make one line into three :|
        for letter in alphabet {
            var x: CGFloat = 0, y: CGFloat = 0
            if horizontal {
                x = position
                y = margin

                position += letterWidth
            }
            else {
                x = margin
                y = position

                position += letterHeight
            }
            position += margin

            let button = UIButton(frame: CGRectMake(x, y, letterWidth, letterHeight))
            button.titleLabel.font = font
            button.setTitle(String(letter), forState: .Normal)
            button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            button.setTitleColor(UIColor.blueColor(), forState: .Highlighted)
            button.addTarget(self, action: "letterPressed:", forControlEvents: .TouchUpInside)

            buttons += button
            addSubview(button)

        }

        if horizontal {
            let height = letterHeight + 2*margin
            let delta = frame.size.height - height
            frame.size.height = height
            frame.origin.y += delta
        }
        else {
            let width = letterWidth + 2*margin
            let delta = frame.size.width - width
            frame.size.width = width
            frame.origin.x += delta
        }

        super.layoutSubviews()
    }

    @IBAction
    func letterPressed(sender: UIButton!) {
        viewController?.alphabetView(self, selectedLetter: sender.titleForState(.Normal))
    }

    private func getFont() -> UIFont! {
        let horizontal = frame.size.width > frame.size.height
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)

        // nothing to do with dynamic type, just whatever fits the form factor
        // fortunately, there are only three relevant device sizes, in points:
        // 320 x 480, 320 x 568, 768 x 1024.
        // these are all the point sizes required to fit them in portrait and landscape.
        let sizes: [CGFloat] = [ 36, 24, 18, 14, 12, 10 ]

        var fontSize: CGFloat = 0
        var fontToUse: UIFont!
        for fontSize in sizes {
            fontToUse = UIFont(descriptor: fontDescriptor, size: fontSize)
            let letterHeight = ("Q" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).height // Q has a small tail
            let letterWidth = ("W" as NSString).sizeWithAttributes([NSFontAttributeName: fontToUse]).width // W for Wide Load
            let margin = AlphabetView.margin

            if horizontal {
                if 27 * margin + 26 * letterWidth <= bounds.size.width {
                    // NSLog("using %f point font", fontSize)
                    break
                }
            }
            else {
                if 27 * margin + 26 * letterHeight <= bounds.size.height {
                    // NSLog("using %f point font", fontSize)
                    break
                }
            }
        }

        return fontToUse
   }

}
