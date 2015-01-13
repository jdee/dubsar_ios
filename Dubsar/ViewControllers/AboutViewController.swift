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

    @IBOutlet var scroller: UIScrollView!
    var bannerLabel : UILabel!
    var versionLabel : UILabel!
    var modelsVersionLabel : UILabel!
    var databaseVersionLabel : UILabel!
    var copyrightLabel : UILabel!
    var lastCheckLabel : UILabel!
    var updateButton: UIButton!
    var iTunesButton: UIButton!
    var privacyButton: UIButton!
    var supportLabel: UILabel!
    var supportEmailButton: UIButton!
    var supportURLButton: UIButton!

    private var paragraphLabels = [UILabel]()

    private var checking = false

    private let paragraphs = [
        "iOS Knob Control v. \(IKC_VERSION_STRING) © 2014 by the author",
        "WordNet® 3.1 © 2011 The Trustees of Princeton University",
        "WordNet® is available under the WordNet 3.0 License",
        "Minizip © 1998-2010 Gilles Vollant" ]

    override func viewDidLoad() {
        super.viewDidLoad()

        bannerLabel = UILabel(frame: CGRectZero)
        bannerLabel.text = "Dubsar for iOS"
        bannerLabel.textAlignment = .Center
        bannerLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(bannerLabel)

        versionLabel = UILabel(frame: CGRectZero)
        versionLabel.text = "Version \(NSBundle.mainBundle().objectForInfoDictionaryKey(String(kCFBundleVersionKey))!)"
        versionLabel.textAlignment = .Center
        versionLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(versionLabel)

        let dubsarModelsVersionString = String(format: "%.2f", 0.01 * floor(DubsarModelsVersionNumber * 100))
        modelsVersionLabel = UILabel(frame: CGRectZero)
        modelsVersionLabel.text = "DubsarModels Version \(dubsarModelsVersionString)"
        modelsVersionLabel.textAlignment = .Center
        modelsVersionLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(modelsVersionLabel)

        databaseVersionLabel = UILabel(frame: CGRectZero)
        databaseVersionLabel.textAlignment = .Center
        databaseVersionLabel.numberOfLines = 0
        databaseVersionLabel.lineBreakMode = .ByWordWrapping
        databaseVersionLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(databaseVersionLabel)

        lastCheckLabel = UILabel(frame: CGRectZero)
        lastCheckLabel.textAlignment = .Center
        lastCheckLabel.numberOfLines = 0
        lastCheckLabel.lineBreakMode = .ByWordWrapping
        lastCheckLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(lastCheckLabel)

        copyrightLabel = UILabel(frame: CGRectZero)
        copyrightLabel.text = "Copyright © 2014 Jimmy Dee"
        copyrightLabel.textAlignment = .Center
        copyrightLabel.numberOfLines = 0
        copyrightLabel.lineBreakMode = .ByWordWrapping
        copyrightLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(copyrightLabel)

        updateButton = UIButton(frame: CGRectZero)
        updateButton.addTarget(self, action: "checkForUpdate:", forControlEvents: .TouchUpInside)
        updateButton.autoresizingMask = .FlexibleWidth
        updateButton.layer.cornerRadius = 4
        scroller.addSubview(updateButton)

        iTunesButton = UIButton(frame: CGRectZero)
        iTunesButton.setTitle("View in App Store", forState: .Normal)
        iTunesButton.addTarget(self, action: "viewInAppStore:", forControlEvents: .TouchUpInside)
        iTunesButton.autoresizingMask = .FlexibleWidth
        iTunesButton.layer.cornerRadius = 4
        scroller.addSubview(iTunesButton)

        privacyButton = UIButton(frame: CGRectZero)
        privacyButton.setTitle("Privacy Statement", forState: .Normal)
        privacyButton.addTarget(self, action: "viewPrivacyStatement:", forControlEvents: .TouchUpInside)
        privacyButton.autoresizingMask = .FlexibleWidth
        privacyButton.layer.cornerRadius = 4
        scroller.addSubview(privacyButton)

        supportLabel = UILabel(frame: CGRectZero)
        supportLabel.text = "For support:"
        supportLabel.textAlignment = .Center
        supportLabel.numberOfLines = 0
        supportLabel.lineBreakMode = .ByWordWrapping
        supportLabel.autoresizingMask = .FlexibleWidth
        scroller.addSubview(supportLabel)

        supportEmailButton = UIButton(frame: CGRectZero)
        supportEmailButton.setTitle("support@dubsar.info", forState: .Normal)
        supportEmailButton.titleLabel!.textAlignment = .Center
        supportEmailButton.titleLabel!.adjustsFontSizeToFitWidth = true
        supportEmailButton.autoresizingMask = .FlexibleWidth
        supportEmailButton.addTarget(self, action: "sendSupportEmail:", forControlEvents: .TouchUpInside)
        supportEmailButton.layer.cornerRadius = 4
        scroller.addSubview(supportEmailButton)

        supportURLButton = UIButton(frame: CGRectZero)
        supportURLButton.setTitle("https://dubsar.info/m_support", forState: .Normal)
        supportURLButton.titleLabel!.textAlignment = .Center
        supportURLButton.titleLabel!.adjustsFontSizeToFitWidth = true
        supportURLButton.autoresizingMask = .FlexibleWidth
        supportURLButton.addTarget(self, action: "visitSupportURL:", forControlEvents: .TouchUpInside)
        supportURLButton.layer.cornerRadius = 4
        scroller.addSubview(supportURLButton)
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
            var timestamp: NSString = mtime.substringWithRange(range)
            timestamp = timestamp.stringByReplacingOccurrencesOfString("T", withString: " ", options: nil, range: range)

            dbVersionString = "\(download.name)\n\(timestamp) UTC"
        }
        else {
            dbVersionString = "(no current download)"
        }

        databaseVersionLabel.text = "Installed database version:\n\(dbVersionString)"

        super.viewWillAppear(animated)
    }

    override func adjustLayout() {
        DMTRACE("In About::adjustLayout(), view bounds \(view.bounds.size.width) x \(view.bounds.size.height)")
        scroller.frame = view.bounds

        let databaseManager = AppDelegate.instance.databaseManager
        if !AppConfiguration.offlineSetting {
            updateButton.enabled = false
            updateButton.setTitle("(offline use disabled)", forState: .Normal)
        }
        else if databaseManager.updateCheckInProgress {
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

        let buttonFudge: CGFloat = 12

        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let attrs: [ NSObject: AnyObject ]! = [NSFontAttributeName: font]
        let hmargin : CGFloat = 20
        let vmargin : CGFloat = 8
        var constrainedSize = view.bounds.size
        var y = vmargin
        constrainedSize.width -= 2 * hmargin

        var textSize = (bannerLabel.text as NSString?)!.sizeWithAttributes(attrs)
        bannerLabel.font = font
        bannerLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        textSize = (copyrightLabel.text as NSString?)!.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
        copyrightLabel.font = font
        copyrightLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        textSize = (versionLabel.text as NSString?)!.sizeWithAttributes(attrs)
        versionLabel.font = font
        versionLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        textSize = (modelsVersionLabel.text as NSString?)!.sizeWithAttributes(attrs)
        modelsVersionLabel.font = font
        modelsVersionLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        textSize = (databaseVersionLabel.text as NSString?)!.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
        databaseVersionLabel.font = font
        databaseVersionLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        let lastCheck = NSDate(timeIntervalSince1970: NSTimeInterval(AppConfiguration.lastUpdateCheckTime))
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle

        lastCheckLabel.text = AppConfiguration.offlineSetting ? "Last checked \(formatter.stringFromDate(lastCheck))" : ""
        textSize = (lastCheckLabel.text as NSString?)!.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
        lastCheckLabel.font = font
        lastCheckLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        textSize = (updateButton.titleForState(.Normal) as NSString?)!.sizeWithAttributes(attrs)
        updateButton.titleLabel!.font = font
        updateButton.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height + buttonFudge)

        y += textSize.height + vmargin + buttonFudge

        textSize = (iTunesButton.currentTitle as NSString?)!.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
        iTunesButton.titleLabel!.font = font
        iTunesButton.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height + buttonFudge)

        y += textSize.height + vmargin + buttonFudge
        
        textSize = (privacyButton.currentTitle as NSString?)!.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
        privacyButton.titleLabel!.font = font
        privacyButton.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height + buttonFudge)

        y += textSize.height + vmargin + buttonFudge

        textSize = (supportLabel.text as NSString?)!.sizeOfTextWithConstrainedSize(constrainedSize, font: font)
        supportLabel.font = font
        supportLabel.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height)

        y += textSize.height + vmargin

        textSize = (supportEmailButton.currentTitle as NSString?)!.sizeWithAttributes([NSFontAttributeName: font])
        supportEmailButton.titleLabel!.font = font
        supportEmailButton.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height + buttonFudge)

        y += textSize.height + vmargin + buttonFudge

        textSize = (supportURLButton.currentTitle as NSString?)!.sizeWithAttributes([NSFontAttributeName: font])
        supportURLButton.titleLabel!.font = font
        supportURLButton.frame = CGRectMake(hmargin, y, constrainedSize.width, textSize.height + buttonFudge)

        bannerLabel.textColor = AppConfiguration.foregroundColor
        versionLabel.textColor = AppConfiguration.foregroundColor
        modelsVersionLabel.textColor = AppConfiguration.foregroundColor
        databaseVersionLabel.textColor = AppConfiguration.foregroundColor
        lastCheckLabel.textColor = AppConfiguration.foregroundColor
        copyrightLabel.textColor = AppConfiguration.foregroundColor

        updateButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        updateButton.setTitleColor(AppConfiguration.alternateBackgroundColor, forState: .Disabled)
        updateButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        updateButton.backgroundColor = AppConfiguration.highlightColor

        iTunesButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        iTunesButton.backgroundColor = AppConfiguration.highlightColor
        iTunesButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)

        privacyButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        privacyButton.backgroundColor = AppConfiguration.highlightColor
        privacyButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)

        supportLabel.textColor = AppConfiguration.foregroundColor

        supportEmailButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        supportEmailButton.backgroundColor = AppConfiguration.highlightColor
        supportEmailButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)
        
        supportURLButton.setTitleColor(AppConfiguration.foregroundColor, forState: .Normal)
        supportURLButton.backgroundColor = AppConfiguration.highlightColor
        supportURLButton.setTitleColor(AppConfiguration.highlightedForegroundColor, forState: .Highlighted)

        // The shadows don't resize as well if we provide shadow paths.

        updateButton.layer.borderWidth = 1
        updateButton.layer.borderColor = AppConfiguration.foregroundColor.CGColor
        updateButton.layer.shadowOpacity = 1
        updateButton.layer.shadowOffset = CGSizeMake(0, 3)
        // updateButton.layer.shadowPath = UIBezierPath(roundedRect: updateButton.bounds, cornerRadius: updateButton.layer.cornerRadius).CGPath

        iTunesButton.layer.borderWidth = 1
        iTunesButton.layer.borderColor = AppConfiguration.foregroundColor.CGColor
        iTunesButton.layer.shadowOpacity = 1
        iTunesButton.layer.shadowOffset = CGSizeMake(0, 3)
        // iTunesButton.layer.shadowPath = UIBezierPath(roundedRect: iTunesButton.bounds, cornerRadius: iTunesButton.layer.cornerRadius).CGPath

        privacyButton.layer.borderWidth = 1
        privacyButton.layer.borderColor = AppConfiguration.foregroundColor.CGColor
        privacyButton.layer.shadowOpacity = 1
        privacyButton.layer.shadowOffset = CGSizeMake(0, 3)
        // privacyButton = UIBezierPath(roundedRect: privacyButton.bounds, cornerRadius: privacyButton.layer.cornerRadius).CGPath

        supportEmailButton.layer.borderWidth = 1
        supportEmailButton.layer.borderColor = AppConfiguration.foregroundColor.CGColor
        supportEmailButton.layer.shadowOpacity = 1
        supportEmailButton.layer.shadowOffset = CGSizeMake(0, 3)
        // supportEmailButton.layer.shadowPath = UIBezierPath(roundedRect: supportEmailButton.bounds, cornerRadius: supportEmailButton.layer.cornerRadius).CGPath

        supportURLButton.layer.borderWidth = 1
        supportURLButton.layer.borderColor = AppConfiguration.foregroundColor.CGColor
        supportURLButton.layer.shadowOpacity = 1
        supportURLButton.layer.shadowOffset = CGSizeMake(0, 3)
        // supportURLButton.layer.shadowPath = UIBezierPath(roundedRect: supportURLButton.bounds, cornerRadius: supportURLButton.layer.cornerRadius).CGPath

        var headlineFontDesc = AppConfiguration.preferredFontDescriptorWithTextStyle(UIFontTextStyleHeadline)
        var bodyFontDesc = AppConfiguration.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)

        layoutParagraphs(UIFont(descriptor: bodyFontDesc, size: headlineFontDesc.pointSize))

        let lastLabel = paragraphLabels[paragraphLabels.count - 1]

        y = lastLabel.frame.origin.y + lastLabel.bounds.size.height + vmargin

        scroller.contentSize = CGSizeMake(view.bounds.size.width, y)
        super.adjustLayout()
    }

    @IBAction func checkForUpdate(sender: UIButton!) {
        sender.enabled = false
        checking = true
        AppDelegate.instance.checkForUpdate()
        adjustLayout()
    }

    @IBAction func viewInAppStore(sender: UIButton!) {
        UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/us/app/dubsar/id453868483?mt=8")!)
    }

    @IBAction func sendSupportEmail(sender: UIButton!) {
        UIApplication.sharedApplication().openURL(NSURL(string: "mailto:support@dubsar.info")!)
    }

    @IBAction func visitSupportURL(sender: UIButton!) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://dubsar.info/m_support")!)
    }

    @IBAction func viewPrivacyStatement(sender: UIButton!) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://dubsar.info/m_privacy")!)
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
        var lastLabel : UIView!
        if paragraphLabels.isEmpty {
            lastLabel = supportURLButton
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

        paragraphLabels.append(newLabel)
        scroller.addSubview(newLabel)
    }
}
