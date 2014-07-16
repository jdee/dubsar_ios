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

    weak var view: SynsetHeaderView!

    init(sense: DubsarModelsSense!, view: SynsetHeaderView!) {
        self.sense = sense
        self.view = view

        selectionButton = UIButton()
        navigationButton = UIButton()

        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        // configure selection button
        selectionButton.titleLabel.font = font
        selectionButton.frame.size = (sense.word.name as NSString).sizeOfTextWithFont(font)
        selectionButton.frame.size.width += 2 * SynonymButtonPair.margin
        selectionButton.frame.size.height += 2 * SynonymButtonPair.margin
        selectionButton.setTitle(sense.word.name, forState: .Normal)
        selectionButton.addTarget(self, action: "selected:", forControlEvents: .TouchUpInside)
        view.addSubview(selectionButton)

        navigationButton.addTarget(self, action: "navigated:", forControlEvents: .TouchUpInside)
        view.addSubview(navigationButton)
    }

    func selected(sender: UIButton!) {
        // might consider toggling this state
        view.sense = sense
        sender.selected = true
    }

    func navigated(sender: UIButton!) {
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
        resetSelection()
    }
    }

    let glossLabel : UILabel
    let lexnameLabel : UILabel

    let synonymButtons : NSMutableArray

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
        autoresizingMask = .FlexibleHeight | .FlexibleWidth

        glossLabel.lineBreakMode = .ByWordWrapping
        glossLabel.numberOfLines = 0
        glossLabel.autoresizingMask = .FlexibleBottomMargin | .FlexibleHeight | .FlexibleWidth
        addSubview(glossLabel)

        lexnameLabel.lineBreakMode = .ByWordWrapping
        lexnameLabel.numberOfLines = 0
        lexnameLabel.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        addSubview(lexnameLabel)
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

            let lexnameSize = lexnameText.sizeOfTextWithConstrainedSize(constrainedSize, font: headlineFont)

            lexnameLabel.frame = CGRectMake(margin, 2 * margin + glossSize.height, constrainedSize.width, lexnameSize.height)
            lexnameLabel.text = lexnameText
            lexnameLabel.font = headlineFont
            lexnameLabel.invalidateIntrinsicContentSize()
        }

        super.layoutSubviews()
    }

    func setupSynonymButtons() {
        for idiotShit: AnyObject in synonymButtons {
            if let buttonPair = idiotShit as? SynonymButtonPair {
                buttonPair.selectionButton.removeFromSuperview()
                buttonPair.navigationButton.removeFromSuperview()
            }
        }

        synset.senses.removeAllObjects()

        for moronicCrap: AnyObject in synset.senses as NSArray {
            if let synonym = moronicCrap as? DubsarModelsSense {
                synonymButtons.addObject(SynonymButtonPair(sense: synonym, view: self))
            }
        }

    }

    func resetSelection() {
        setNeedsLayout()
        for fuckYou : AnyObject in synset.senses as NSArray {
            if let buttonPair = fuckYou as? SynonymButtonPair {
                buttonPair.selectionButton.selected = false
            }
        }
    }

}
