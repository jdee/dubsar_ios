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

class DownloadProgressTableViewCell: UITableViewCell {

    class var identifier: String {
        get {
            return "download"
        }
    }

    var downloadLabel: UILabel
    var downloadProgress: UIProgressView
    var unzipLabel: UILabel
    var unzipProgress: UIProgressView
    var cancelButton: UIButton
    var gradientView: GradientView

    init() {
        downloadLabel = UILabel(frame: CGRectZero)
        downloadProgress = UIProgressView(progressViewStyle: .Bar)
        unzipLabel = UILabel(frame: CGRectZero)
        unzipProgress = UIProgressView(progressViewStyle: .Bar)
        cancelButton = UIButton(frame: CGRectZero)
        gradientView = GradientView(frame: CGRectZero, firstColor: AppConfiguration.backgroundColor, secondColor: AppConfiguration.highlightColor, startPoint: CGPointMake(0, 0), endPoint: CGPointMake(0, 1))

        super.init(style: .Default, reuseIdentifier: DownloadProgressTableViewCell.identifier)

        selectionStyle = .None

        gradientView.autoresizingMask = .FlexibleHeight | .FlexibleWidth | .FlexibleBottomMargin | .FlexibleRightMargin

        downloadLabel.text = "Download: requesting..."
        downloadLabel.lineBreakMode = .ByWordWrapping
        downloadLabel.numberOfLines = 0
        unzipLabel.text = "Unzip"
        unzipLabel.lineBreakMode = .ByWordWrapping
        unzipLabel.numberOfLines = 0
        cancelButton.setTitle("Cancel", forState: .Normal)

        contentView.addSubview(gradientView)
        contentView.addSubview(downloadLabel)
        contentView.addSubview(downloadProgress)
        contentView.addSubview(unzipLabel)
        contentView.addSubview(unzipProgress)
        contentView.addSubview(cancelButton)
    }

    func rebuild() {
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleSubheadline, italic: false)
        downloadLabel.font = font
        unzipLabel.font = font
        cancelButton.titleLabel.font = font

        let foregroundColor = AppConfiguration.foregroundColor
        downloadLabel.textColor = foregroundColor
        unzipLabel.textColor = foregroundColor
        cancelButton.setTitleColor(foregroundColor, forState: .Normal)

        let alternateBackgroundColor = AppConfiguration.alternateBackgroundColor
        let alternateHighlightColor = AppConfiguration.alternateHighlightColor

        downloadProgress.trackTintColor = alternateBackgroundColor
        downloadProgress.progressTintColor = alternateHighlightColor
        unzipProgress.trackTintColor = alternateBackgroundColor
        unzipProgress.progressTintColor = alternateHighlightColor

        let margin: CGFloat = 8
        let constrainedWidth = bounds.size.width - 2 * margin

        let downloadTextSize = (downloadLabel.text as NSString).sizeOfTextWithConstrainedSize(CGSizeMake(constrainedWidth, bounds.size.height), font: font)
        downloadLabel.frame = CGRectMake(margin, margin, constrainedWidth, downloadTextSize.height)

        downloadProgress.frame = CGRectMake(margin, 2 * margin + downloadTextSize.height, constrainedWidth, downloadProgress.bounds.size.height)

        let unzipTextSize = (unzipLabel.text as NSString).sizeOfTextWithConstrainedSize(CGSizeMake(constrainedWidth, bounds.size.height), font: font)
        unzipLabel.frame = CGRectMake(margin, 3 * margin + downloadTextSize.height + downloadProgress.bounds.size.height, constrainedWidth, unzipTextSize.height)

        unzipProgress.frame = CGRectMake(margin, 4 * margin + downloadTextSize.height + downloadProgress.bounds.size.height + unzipTextSize.height, constrainedWidth, unzipProgress.bounds.size.height)

        var cancelTitle: NSString
        if AppDelegate.instance.databaseManager.downloadInProgress {
            cancelTitle = "Cancel"
        }
        else {
            cancelTitle = "Close"
        }
        cancelButton.setTitle(cancelTitle, forState: .Normal)

        let cancelSize = cancelTitle.sizeWithAttributes([NSFontAttributeName: font])
        cancelButton.frame = CGRectMake(margin, 5 * margin + downloadTextSize.height + downloadProgress.bounds.size.height + unzipTextSize.height + unzipProgress.bounds.size.height, constrainedWidth, cancelSize.height)

        textLabel.hidden = true

        frame.size.height = cancelButton.frame.origin.y + cancelButton.bounds.size.height + margin

        contentView.frame = bounds

        fillBackground()
    }

    func fillBackground() {
        // contentView.backgroundColor = AppConfiguration.highlightColor

        gradientView.firstColor = AppConfiguration.backgroundColor
        gradientView.secondColor = AppConfiguration.highlightColor
        gradientView.endPoint = CGPointMake(0, bounds.size.height)
        gradientView.frame = bounds
        gradientView.setNeedsDisplay()
    }
}
