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
        selectionButton.titleLabel!.font = font
        selectionButton.titleLabel!.adjustsFontSizeToFitWidth = true
        selectionButton.frame.size = (sense.name as NSString).sizeWithAttributes([NSFontAttributeName: font])
        selectionButton.frame.size.width += 2 * SynonymButtonPair.margin
        selectionButton.frame.size.height += 2 * SynonymButtonPair.margin

        height = selectionButton.bounds.size.height

        if selectionButton.bounds.size.width > view!.bounds.size.width - height {
            selectionButton.frame.size.width = view!.bounds.size.width - height
        }

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

        selectionButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        selectionButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        selectionButton.setTitleColor(AppConfiguration.alternateBackgroundColor, forState: .Disabled)

        selectionButton.addTarget(self, action: "synonymSelected:", forControlEvents: .TouchUpInside)
        view.synonymView.addSubview(selectionButton)

        // configure navigation button.

        navigationButton.addTarget(self, action: "synonymNavigated:", forControlEvents: .TouchUpInside)
        navigationButton.frame = CGRectMake(0, 0, height, height)
        view.synonymView.addSubview(navigationButton)
    }

    // Apparently in Swift you can't make programmatic action assignments without these annotations.
    @IBAction
    func synonymSelected(sender: UIButton!) {
        if let v = view {
            if v.synset.senses.count == 1 {
                return
            }

            if v.sense == nil || v.sense!._id != sense._id {
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
    let synonymView: UIView

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
        synonymView = UIView()

        super.init(frame: frame)

        build()
    }

    required init(coder aDecoder: NSCoder) {
        synset = DubsarModelsSynset()
        glossLabel = UILabel()
        lexnameLabel = UILabel()
        extraTextLabel = UILabel()
        synonymView = UIView()
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        DMTRACE("Entered SynsetHeaderView.layoutSubviews(). Size: \(bounds.size.width) x \(bounds.size.height)")
        assert(bounds.size.width == superview!.bounds.size.width)
        // assert(bounds.size.width == UIScreen.mainScreen().bounds.size.width)

        if synset.complete {
            let margin = SynsetHeaderView.margin
            var constrainedSize = bounds.size
            constrainedSize.width -= 2 * margin

            DMTRACE("Constrained width: \(constrainedSize.width)")

            let headlineFont = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)

            // Gloss label
            let glossSize = synset.glossSizeWithConstrainedSize(constrainedSize, font: headlineFont)

            glossLabel.frame = CGRectMake(margin, margin, constrainedSize.width, glossSize.height)
            glossLabel.text = synset.gloss
            glossLabel.font = headlineFont
            glossLabel.numberOfLines = 0
            glossLabel.lineBreakMode = .ByWordWrapping
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
            if sense != nil && !sense!.marker.isEmpty {
                extraText = "\(extraText) (\(sense!.marker))"
            }
            else if synset.senses.count == 1 {
                let firstSense = synset.senses.firstObject as DubsarModelsSense
                if !firstSense.marker.isEmpty {
                    extraText = "\(extraText) (\(firstSense.marker))"
                }
            }

            if sense != nil && sense!.freqCnt > 0 {
                extraText = "\(extraText) freq. cnt. \(sense!.freqCnt)"
            }
            else if sense == nil && synset.freqCnt > 0 {
                extraText = "\(extraText) freq. cnt. \(synset.freqCnt)"
            }

            let extraTextSize = extraText.sizeWithAttributes([NSFontAttributeName: headlineFont])

            /*
             * In case the lexnameLabel and extraTextLabel are too wide to fit next to each other on the screen,
             * shrink the text on the extraTextLabel. It could alternately go onto a separate line.
             */
            extraTextLabel.frame = CGRectMake(2 * margin + lexnameSize.width, 2 * margin + glossSize.height, min(extraTextSize.width, bounds.size.width - lexnameLabel.bounds.size.width-2*margin), extraTextSize.height)
            extraTextLabel.text = extraText
            extraTextLabel.font = headlineFont
            extraTextLabel.textAlignment = .Center
            extraTextLabel.adjustsFontSizeToFitWidth = true
            extraTextLabel.textColor = AppConfiguration.foregroundColor
            extraTextLabel.invalidateIntrinsicContentSize()

            if sense != nil || synset.senses.count == 1 {
                extraTextLabel.backgroundColor = AppConfiguration.highlightColor
            }
            else {
                extraTextLabel.backgroundColor = UIColor.clearColor()
            }

            frame.size.height = extraTextLabel.frame.origin.y + extraTextLabel.bounds.size.height + setupSynonymButtons()
            DMTRACE("header view size: \(bounds.size.width) x \(bounds.size.height)")
            invalidateIntrinsicContentSize()
        }

        super.layoutSubviews()
    }

    override func setNeedsLayout() {
        super.setNeedsLayout()
    }

    override func intrinsicContentSize() -> CGSize {
        return bounds.size
    }

    func buttonPair(buttonPair: SynonymButtonPair!, selectedSense sense: DubsarModelsSense!) {
        setNeedsLayout()
        delegate?.synsetHeaderView(self, selectedSense: sense)
    }

    func buttonPair(buttonPair: SynonymButtonPair!, navigatedToSense sense: DubsarModelsSense!) {
        delegate?.synsetHeaderView(self, navigatedToSense: sense)
    }

    private func build() {
        DMTRACE("Constructing SynsetHeaderView with \(synset.senses.count) synonyms (synset ID \(synset._id): \(synset.gloss)). \(synset.synonymsAsString)")

        glossLabel.lineBreakMode = .ByWordWrapping
        glossLabel.numberOfLines = 0
        glossLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(glossLabel)

        lexnameLabel.lineBreakMode = .ByWordWrapping
        lexnameLabel.numberOfLines = 0
        lexnameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(lexnameLabel)

        extraTextLabel.lineBreakMode = .ByWordWrapping
        extraTextLabel.numberOfLines = 0
        extraTextLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(extraTextLabel)

        synonymView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(synonymView)

        let margin = SynsetHeaderView.margin
        var constraint: NSLayoutConstraint

        constraint = NSLayoutConstraint(item: glossLabel, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: glossLabel, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: glossLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: -margin)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: lexnameLabel, attribute: .Top, relatedBy: .Equal, toItem: glossLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: lexnameLabel, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: lexnameLabel, attribute: .Trailing, relatedBy: .Equal, toItem: extraTextLabel, attribute: .Leading, multiplier: 1.0, constant: -margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: extraTextLabel, attribute: .Top, relatedBy: .Equal, toItem: lexnameLabel, attribute: .Top, multiplier: 1.0, constant: 0.0)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: synonymView, attribute: .Top, relatedBy: .Equal, toItem: lexnameLabel, attribute: .Bottom, multiplier: 1.0, constant: margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: synonymView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1.0, constant: margin)
        addConstraint(constraint)
        constraint = NSLayoutConstraint(item: synonymView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: -margin)
        addConstraint(constraint)

        constraint = NSLayoutConstraint(item: synonymView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: -margin)
        addConstraint(constraint)
    }

    private func setupSynonymButtons() -> CGFloat {
        for buttonPair in synonymButtons {
            buttonPair.selectionButton.removeFromSuperview()
            buttonPair.navigationButton.removeFromSuperview()
        }

        synonymButtons = []

        let margin = SynsetHeaderView.margin
        let constrainedWidth = bounds.size.width - 2 * margin
        var x : CGFloat = 0, y = margin
        var height : CGFloat = 0

        for object: AnyObject in synset.senses as NSArray {
            if let synonym = object as? DubsarModelsSense {
                let buttonPair = SynonymButtonPair(sense: synonym, view: self)
                if (sense != nil && sense!._id == synonym._id) || synset.senses.count == 1 { // set it to disabled when synset.senses.count == 1?
                    buttonPair.selectionButton.selected = true
                    buttonPair.selectionButton.backgroundColor = AppConfiguration.highlightColor
                }
                synonymButtons.append(buttonPair)

                assert(height <= 0 || height == buttonPair.navigationButton.frame.size.height) // assume they're all the same height with the same font
                height = buttonPair.height // the two buttons are the same height

                if buttonPair.width + x > constrainedWidth {
                    // wrap
                    y += height + margin
                    x = 0
                }

                buttonPair.selectionButton.frame.origin.x = x
                buttonPair.selectionButton.frame.origin.y = y
                buttonPair.navigationButton.frame.origin.x = x + buttonPair.selectionButton.frame.size.width
                buttonPair.navigationButton.frame.origin.y = y
                x += buttonPair.width
            }
        }

        synonymView.frame = CGRectMake(0, extraTextLabel.frame.origin.y+extraTextLabel.bounds.size.height, bounds.size.width, y + height + 2 * margin)

        return synonymView.bounds.size.height
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
