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

/*
 * Wow, is Xcode6 a little green! Beta2 will not accept Swift array types like
 * [SynonymButtonPair] (or [String]). But Beta3 has the all-product-headers.yaml
 * problem when building the framework module. There's a workaround for that, but
 * the app crashes when trying to register for push. So we use an NSMutableArray
 * for now, but that requires using a class instead of a struct. :|
 */
class SynonymButtonPair {
    class var margin : CGFloat {
        get {
            return 2
        }
    }

    var selectionButton : UIButton!
    var navigationButton : UIButton!

    var sense: DubsarModelsSense!

    weak var view: SynsetHeaderView?

    var width : CGFloat, height : CGFloat

    init(sense: DubsarModelsSense!, view: SynsetHeaderView!) {
        self.sense = sense
        self.view = view

        selectionButton = UIButton()
        navigationButton = UIButton()

        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        // configure selection button
        selectionButton.titleLabel.font = font
        selectionButton.frame.size = (sense.name as NSString).sizeOfTextWithFont(font)
        selectionButton.frame.size.width += 2 * SynonymButtonPair.margin
        selectionButton.frame.size.height += 2 * SynonymButtonPair.margin

        width = selectionButton.frame.size.width + selectionButton.frame.size.height // nav. button is a square of the same height; no margin between them
        height = selectionButton.frame.size.height

        selectionButton.setTitle(sense.name, forState: .Normal)
        selectionButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        selectionButton.setTitleColor(UIColor.blueColor(), forState: .Highlighted)
        selectionButton.setTitleColor(UIColor.blueColor(), forState: .Selected)
        selectionButton.addTarget(self, action: "synonymSelected:", forControlEvents: .TouchUpInside)
        view.addSubview(selectionButton)

        // configure navigation button.
        let image = NavButtonImage.imageWithSize(CGSizeMake(height, height))
        navigationButton.setImage(image, forState: .Normal)
        navigationButton.addTarget(self, action: "synonymNavigated:", forControlEvents: .TouchUpInside)
        navigationButton.frame.size.width = height
        navigationButton.frame.size.height = height
        view.addSubview(navigationButton)
    }

    // Apparently in Swift you can't make programmatic action assignments without these annotations.
    @IBAction
    func synonymSelected(sender: UIButton!) {
        if let v = view {
            if v.synset.senses.count == 1 {
                return
            }

            if !v.sense || v.sense!._id != sense._id {
                v.sense = sense
            }
            else {
                v.sense = nil // resets all to unselected
            }
        }
    }

    @IBAction
    func synonymNavigated(sender: UIButton!) {
        view?.buttonPair(self, navigatedToSense: sense)
    }
}

class SynsetHeaderView: UIView {

    class var margin : CGFloat {
        get {
            return 8
        }
    }

    let synset : DubsarModelsSynset
    var sense : DubsarModelsSense? { // optional and variable; represents word context
    didSet {
        setNeedsLayout()
    }
    }

    let glossLabel : UILabel
    let lexnameLabel : UILabel

    let synonymButtons : NSMutableArray

    weak var delegate : SynsetViewController?

    /*
     * The frame argument represents the space to which the view is constrained, or more accurately, the
     * text in the view is assumed constrained to frame.size.width. The view may adjust its height
     * as appropriate.
     */
    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset

        glossLabel = UILabel()
        lexnameLabel = UILabel()

        synonymButtons = NSMutableArray()

        super.init(frame: frame)

        build()
    }

    func build() {
        NSLog("Constructing SynsetHeaderView with %d synonyms", synset.senses.count)

        autoresizingMask = .FlexibleHeight | .FlexibleWidth

        glossLabel.lineBreakMode = .ByWordWrapping
        glossLabel.numberOfLines = 0
        glossLabel.autoresizingMask = .FlexibleBottomMargin | .FlexibleHeight | .FlexibleWidth
        addSubview(glossLabel)

        lexnameLabel.lineBreakMode = .ByWordWrapping
        lexnameLabel.numberOfLines = 0
        lexnameLabel.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        addSubview(lexnameLabel)

        layoutSubviews()
    }

    override func layoutSubviews() {
        if synset.complete {
            let margin = SynsetHeaderView.margin
            var constrainedSize = bounds.size
            constrainedSize.width -= 2 * margin

            let headlineFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)

            // Gloss label
            let glossSize = synset.glossSizeWithConstrainedSize(constrainedSize, font: headlineFont)

            glossLabel.frame = CGRectMake(margin, margin, constrainedSize.width, glossSize.height)
            glossLabel.text = synset.gloss
            glossLabel.font = headlineFont
            glossLabel.invalidateIntrinsicContentSize()

            // Lexname label
            var lexnameText = "<\(synset.lexname)>" as NSString
            if sense && !sense!.marker.isEmpty {
                lexnameText = "\(lexnameText) (\(sense!.marker))"
            }
            if sense && sense!.freqCnt > 0 {
                lexnameText = "\(lexnameText) freq. cnt. \(sense!.freqCnt)"
            }
            else if !sense && synset.freqCnt > 0 {
                lexnameText = "\(lexnameText) freq. cnt. \(synset.freqCnt)"
            }

            let lexnameSize = lexnameText.sizeOfTextWithConstrainedSize(constrainedSize, font: headlineFont)

            lexnameLabel.frame = CGRectMake(margin, 2 * margin + glossSize.height, constrainedSize.width, lexnameSize.height)
            lexnameLabel.text = lexnameText
            lexnameLabel.font = headlineFont
            lexnameLabel.invalidateIntrinsicContentSize()

            let height = setupSynonymButtons()
            frame.size.height = height
        }

        super.layoutSubviews()
    }

    func setupSynonymButtons() -> CGFloat {
        for object: AnyObject in synonymButtons {
            if let buttonPair = object as? SynonymButtonPair {
                buttonPair.selectionButton.removeFromSuperview()
                buttonPair.navigationButton.removeFromSuperview()
            }
        }

        synonymButtons.removeAllObjects()

        let margin = SynsetHeaderView.margin
        let constrainedWidth = bounds.size.width - 2 * margin
        var x : CGFloat = margin, y : CGFloat = lexnameLabel.frame.size.height + lexnameLabel.frame.origin.y + margin
        var height : CGFloat = 0

        NSLog("Synset ID %d (%@). Adding buttons for %d synonyms", synset._id, synset.gloss, synset.senses.count)

        for object: AnyObject in synset.senses as NSArray {
            if let synonym = object as? DubsarModelsSense {
                let buttonPair = SynonymButtonPair(sense: synonym, view: self)
                if sense && sense!._id == synonym._id && synset.senses.count > 1 {
                    buttonPair.selectionButton.selected = true
                }
                synonymButtons.addObject(buttonPair)

                assert(height <= 0 || height == buttonPair.navigationButton.frame.size.height) // assume they're all the same height with the same font
                height = buttonPair.height // the two buttons are the same height

                if buttonPair.width + x > constrainedWidth {
                    // wrap
                    y += height + margin
                    x = margin
                }

                buttonPair.selectionButton.frame.origin.x = x
                buttonPair.selectionButton.frame.origin.y = y
                buttonPair.navigationButton.frame.origin.x = x + buttonPair.selectionButton.frame.size.width
                buttonPair.navigationButton.frame.origin.y = y
                x += buttonPair.width
            }
        }

        return y + height + margin
    }

    /*
     * Invocation of the delegate?.synsetHeaderView(...) calls below crashes with a bad access error (bad address). The delegate needs to be a weak ref.
     * here to avoid a loop. But we don't need to use this view with any other VC, so just make it a concrete weak ref. instead of a @class_protocol.
     * Could also stuff the delegate methods into the base VC class.
     */
    func resetSelection() {
        for object : AnyObject in synonymButtons {
            if let buttonPair = object as? SynonymButtonPair {
                buttonPair.selectionButton.selected = false
            }
        }
        delegate?.synsetHeaderView(self, selectedSense: sense)
    }

    func buttonPair(buttonPair: SynonymButtonPair!, navigatedToSense sense: DubsarModelsSense!) {
        delegate?.synsetHeaderView(self, navigatedToSense: sense)
    }

}
