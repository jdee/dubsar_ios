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

class AboutViewController: BaseViewController {

    class var identifier : String {
        get {
            return "About"
        }
    }

    @IBOutlet var bannerLabel : UILabel!
    @IBOutlet var versionLabel : UILabel!
    @IBOutlet var modelsVersionLabel : UILabel!
    @IBOutlet var copyrightLabel : UILabel!
    @IBOutlet var doneButton : UIButton!

    private var paragraphLabels = [UILabel]()

    private let paragraphs = [
        "WordNet® 3.1 © 2011 The Trustees of Princeton University",
        "WordNet® is available under the WordNet 3.0 License" ]

    override func viewDidLoad() {
        super.viewDidLoad()

        versionLabel.text = "Version \(NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)))"

        let dubsarModelsVersionString = String(format: "%.2f", 0.01 * floor(DubsarModelsVersionNumber * 100))
        modelsVersionLabel.text = "DubsarModels Version \(dubsarModelsVersionString)"

        adjustLayout()
    }

    override func adjustLayout() {
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        bannerLabel.font = font
        versionLabel.font = font
        modelsVersionLabel.font = font
        copyrightLabel.font = font

        bannerLabel.textColor = AppConfiguration.foregroundColor
        versionLabel.textColor = AppConfiguration.foregroundColor
        modelsVersionLabel.textColor = AppConfiguration.foregroundColor
        copyrightLabel.textColor = AppConfiguration.foregroundColor

        var headlineFontDesc = AppConfiguration.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        var bodyFontDesc = AppConfiguration.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)

        layoutParagraphs(UIFont(descriptor: bodyFontDesc, size: headlineFontDesc.pointSize))
        super.adjustLayout()
    }

    // should be able to do this in the storyboard...
    @IBAction func done(sender: UIButton!) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    private func layoutParagraphs(font: UIFont!) {
        for label in paragraphLabels {
            label.removeFromSuperview()
        }
        paragraphLabels = []

        for paragraph in paragraphs {
            addParagraph(paragraph, font: font)
        }
    }

    private func addParagraph(text: NSString, font: UIFont!) {
        let margin : CGFloat = 20
        var constrainedSize = view.bounds.size
        constrainedSize.width -= 2 * margin

        let textSize = text.sizeOfTextWithConstrainedSize(constrainedSize, font: font)

        var y : CGFloat = 0
        var lastLabel : UILabel!
        if paragraphLabels.isEmpty {
            lastLabel = copyrightLabel
        }
        else {
            lastLabel = paragraphLabels[paragraphLabels.count - 1]
        }

        y = lastLabel.frame.origin.y + lastLabel.bounds.size.height + margin

        let newLabel = UILabel(frame: CGRectMake(margin, y, constrainedSize.width, textSize.height))
        newLabel.text = text
        newLabel.font = font
        newLabel.numberOfLines = 0
        newLabel.lineBreakMode = .ByWordWrapping
        newLabel.textAlignment = .Center
        newLabel.textColor = AppConfiguration.foregroundColor
        newLabel.autoresizingMask = .FlexibleWidth | .FlexibleHeight

        paragraphLabels += newLabel
        view.addSubview(newLabel)
    }
}
