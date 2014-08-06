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

class SynonymButtonPair {
    class var margin : CGFloat {
        get {
            return 2
        }
    }

    var selectionButton : UIButton!
    var navigationButton : NavButton!

    var sense: DubsarModelsSense!

    weak var view: SynsetHeaderView?

    var width : CGFloat, height : CGFloat

    init(sense: DubsarModelsSense!, view: SynsetHeaderView!) {
        self.sense = sense
        self.view = view

        selectionButton = UIButton()
        navigationButton = NavButton()

        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleBody)

        selectionButton.enabled = !sense.loading
        navigationButton.enabled = selectionButton.enabled

        // configure selection button
        selectionButton.titleLabel.font = font
        selectionButton.frame.size = (sense.name as NSString).sizeWithAttributes([NSFontAttributeName: font])
        selectionButton.frame.size.width += 2 * SynonymButtonPair.margin
        selectionButton.frame.size.height += 2 * SynonymButtonPair.margin

        if !selectionButton.enabled {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: AppConfiguration.activityIndicatorViewStyle)
            spinner.startAnimating()
            spinner.frame = selectionButton.bounds
            selectionButton.setTitle(" ", forState: .Normal)
            selectionButton.addSubview(spinner)
        }
        else {
            selectionButton.setTitle(sense.name, forState: .Normal)
        }

        width = selectionButton.frame.size.width + selectionButton.frame.size.height // nav. button is a square of the same height; no margin between them
        height = selectionButton.frame.size.height

        selectionButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        selectionButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        selectionButton.setTitleColor(AppConfiguration.alternateBackgroundColor, forState: .Disabled)

        selectionButton.addTarget(self, action: "synonymSelected:", forControlEvents: .TouchUpInside)
        view.addSubview(selectionButton)

        // configure navigation button.

        navigationButton.addTarget(self, action: "synonymNavigated:", forControlEvents: .TouchUpInside)
        navigationButton.frame = CGRectMake(0, 0, height, height)
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
            v.buttonPair(self, selectedSense: v.sense)
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
    var sense : DubsarModelsSense? // optional and variable; represents word context

    let glossLabel : UILabel
    let lexnameLabel : UILabel
    let extraTextLabel : UILabel

    var synonymButtons : [SynonymButtonPair] = []

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
        extraTextLabel = UILabel()

        super.init(frame: frame)

        build()
    }

    override func layoutSubviews() {
        // DMLOG("Entered SynsetHeaderView.layoutSubviews()")
        if synset.complete {
            let margin = SynsetHeaderView.margin
            var constrainedSize = bounds.size
            constrainedSize.width -= 2 * margin

            let headlineFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)

            // Gloss label
            let glossSize = synset.glossSizeWithConstrainedSize(constrainedSize, font: headlineFont)

            glossLabel.frame = CGRectMake(margin, margin, constrainedSize.width, glossSize.height)
            glossLabel.text = synset.gloss
            glossLabel.font = headlineFont
            glossLabel.textColor = AppConfiguration.foregroundColor
            glossLabel.invalidateIntrinsicContentSize()

            // Lexname label
            var lexnameText = "<\(synset.lexname)>" as NSString

            let lexnameSize = lexnameText.sizeWithAttributes([NSFontAttributeName: headlineFont])

            lexnameLabel.frame = CGRectMake(margin, 2 * margin + glossSize.height, lexnameSize.width, lexnameSize.height)
            lexnameLabel.text = lexnameText
            lexnameLabel.font = headlineFont
            lexnameLabel.textColor = AppConfiguration.foregroundColor
            lexnameLabel.invalidateIntrinsicContentSize()

            var extraText = "" as NSString
            if sense && !sense!.marker.isEmpty {
                extraText = "\(extraText) (\(sense!.marker))"
            }
            else if synset.senses.count == 1 {
                let firstSense = synset.senses.firstObject as DubsarModelsSense
                if !firstSense.marker.isEmpty {
                    extraText = "\(extraText) (\(firstSense.marker))"
                }
            }

            if sense && sense!.freqCnt > 0 {
                extraText = "\(extraText) freq. cnt. \(sense!.freqCnt)"
            }
            else if !sense && synset.freqCnt > 0 {
                extraText = "\(extraText) freq. cnt. \(synset.freqCnt)"
            }

            if extraText.length > 0 {
                let extraTextSize = extraText.sizeWithAttributes([NSFontAttributeName: headlineFont])
                extraTextLabel.frame = CGRectMake(2 * margin + lexnameSize.width, 2 * margin + glossSize.height, extraTextSize.width, extraTextSize.height)
                extraTextLabel.text = extraText
                extraTextLabel.font = headlineFont
                extraTextLabel.textAlignment = .Center
                extraTextLabel.textColor = AppConfiguration.foregroundColor
                extraTextLabel.invalidateIntrinsicContentSize()
                addSubview(extraTextLabel)

                if sense || synset.senses.count == 1{
                    extraTextLabel.backgroundColor = AppConfiguration.highlightColor
                }
                else {
                    extraTextLabel.backgroundColor = UIColor.clearColor()
                }
            }
            else {
                extraTextLabel.removeFromSuperview()
            }

            frame.size.height = setupSynonymButtons()
            // DMLOG("header view height: %f", bounds.size.height)
        }

        super.layoutSubviews()
    }

    func buttonPair(buttonPair: SynonymButtonPair!, selectedSense sense: DubsarModelsSense!) {
        setNeedsLayout()
        delegate?.synsetHeaderView(self, selectedSense: sense)
    }

    func buttonPair(buttonPair: SynonymButtonPair!, navigatedToSense sense: DubsarModelsSense!) {
        delegate?.synsetHeaderView(self, navigatedToSense: sense)
    }

    private func build() {
        // DMLOG("Constructing SynsetHeaderView with %d synonyms (synset ID %d: %@:)", synset.senses.count, synset._id, synset.synonymsAsString, synset.gloss)

        autoresizingMask = .FlexibleHeight | .FlexibleWidth

        glossLabel.lineBreakMode = .ByWordWrapping
        glossLabel.numberOfLines = 0
        glossLabel.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        addSubview(glossLabel)

        lexnameLabel.lineBreakMode = .ByWordWrapping
        lexnameLabel.numberOfLines = 0
        lexnameLabel.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        addSubview(lexnameLabel)

        extraTextLabel.lineBreakMode = .ByWordWrapping
        extraTextLabel.numberOfLines = 0
        extraTextLabel.autoresizingMask = .FlexibleHeight | .FlexibleWidth
    }

    private func setupSynonymButtons() -> CGFloat {
        for buttonPair in synonymButtons {
            buttonPair.selectionButton.removeFromSuperview()
            buttonPair.navigationButton.removeFromSuperview()
        }

        synonymButtons = []

        let margin = SynsetHeaderView.margin
        let constrainedWidth = bounds.size.width - 2 * margin
        var x : CGFloat = margin, y : CGFloat = lexnameLabel.frame.size.height + lexnameLabel.frame.origin.y + margin
        var height : CGFloat = 0

        for object: AnyObject in synset.senses as NSArray {
            if let synonym = object as? DubsarModelsSense {
                let buttonPair = SynonymButtonPair(sense: synonym, view: self)
                if (sense && sense!._id == synonym._id) || synset.senses.count == 1 { // set it to disabled when synset.senses.count == 1?
                    buttonPair.selectionButton.selected = true
                    buttonPair.selectionButton.backgroundColor = AppConfiguration.highlightColor
                }
                synonymButtons += buttonPair

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
    private func resetSelection() {
        for buttonPair in synonymButtons {
            buttonPair.selectionButton.selected = false
            buttonPair.selectionButton.backgroundColor = UIColor.clearColor()
        }
        delegate?.synsetHeaderView(self, selectedSense: sense)
    }

}
