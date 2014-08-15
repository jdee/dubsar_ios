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
    @IBOutlet var databaseVersionLabel : UILabel!
    @IBOutlet var copyrightLabel : UILabel!
    @IBOutlet var updateButton: UIButton!

    private var paragraphLabels = [UILabel]()

    private var checking = false

    private let paragraphs = [
        "iOS Knob Control v. \(IKC_VERSION_STRING) © 2014 by the author",
        "WordNet® 3.1 © 2011 The Trustees of Princeton University",
        "WordNet® is available under the WordNet 3.0 License",
        "Minizip © 1998-2010 Gilles Vollant" ]

    override func viewDidLoad() {
        super.viewDidLoad()

        versionLabel.text = "Version \(NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey)))"

        let dubsarModelsVersionString = String(format: "%.2f", 0.01 * floor(DubsarModelsVersionNumber * 100))
        modelsVersionLabel.text = "DubsarModels Version \(dubsarModelsVersionString)"

        adjustLayout()
    }

    override func viewWillAppear(animated: Bool) {
        let current: DubsarModelsDownload? = AppDelegate.instance.databaseManager.currentDownload
        var dbVersionString: String

        if !AppConfiguration.offlineSetting {
            dbVersionString = "(offline use disabled)"
        }
        else if let download = current {
            let range = NSRange(location: 0, length: 19)
            let mtime = download.properties["mtime"] as NSString
            var timestamp = mtime.substringWithRange(range) as NSString
            timestamp = timestamp.stringByReplacingOccurrencesOfString("T", withString: " ", options: nil, range: NSRange(location: 0, length: 19)) as NSString

            dbVersionString = "\(download.name)\n\(timestamp) UTC"
        }
        else {
            dbVersionString = "(no current download)"
        }

        databaseVersionLabel.text = "Installed database version:\n\(dbVersionString)"
        databaseVersionLabel.invalidateIntrinsicContentSize()
        
        super.viewWillAppear(animated)
    }

    override func adjustLayout() {
        let databaseManager = AppDelegate.instance.databaseManager
        if databaseManager.updateCheckInProgress {
            updateButton.enabled = false
            updateButton.setTitle("Checking for update", forState: .Normal)
        }
        else if databaseManager.downloadInProgress {
            updateButton.enabled = false
            updateButton.setTitle("Download in progress", forState: .Normal)
        }
        else {
            updateButton.enabled = true
            if checking {
                checking = false
                if databaseManager.databaseUpdated {
                    updateButton.setTitle("Database updated", forState: .Normal)
                }
                else {
                    updateButton.setTitle("Up to date", forState: .Normal)
                }
            }
            else {
                updateButton.setTitle("Check for update", forState: .Normal)
            }
        }

        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        bannerLabel.font = font
        versionLabel.font = font
        modelsVersionLabel.font = font
        databaseVersionLabel.font = font
        copyrightLabel.font = font
        updateButton.titleLabel.font = font

        bannerLabel.textColor = AppConfiguration.foregroundColor
        versionLabel.textColor = AppConfiguration.foregroundColor
        modelsVersionLabel.textColor = AppConfiguration.foregroundColor
        databaseVersionLabel.textColor = AppConfiguration.foregroundColor
        copyrightLabel.textColor = AppConfiguration.foregroundColor
        updateButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        updateButton.setTitleColor(AppConfiguration.alternateBackgroundColor, forState: .Disabled)
        updateButton.backgroundColor = AppConfiguration.highlightColor

        var headlineFontDesc = AppConfiguration.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        var bodyFontDesc = AppConfiguration.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)

        layoutParagraphs(UIFont(descriptor: bodyFontDesc, size: headlineFontDesc.pointSize))
        super.adjustLayout()
    }

    @IBAction func checkForUpdate(sender: UIButton!) {
        sender.enabled = false
        checking = true
        AppDelegate.instance.checkForUpdate()
        adjustLayout()
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
