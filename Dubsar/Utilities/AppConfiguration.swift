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

struct AppConfiguration {

    static let themeKey = "DubsarTheme"

    static let nameKey = "name"
    static let fontKey = "font"
    static let backgroundKey = "background"
    static let alternateBackgroundKey = "alternateBackground"
    static let highlightKey = "highlight"
    static let alternateHighlightKey = "alternateHighlight"
    static let foregroundKey = "foreground"
    static let highlightedForegroundKey = "highlightedForeground"

    static let themes = [
        [ nameKey : "A", fontKey : "Palatino", backgroundKey : UIColor(red: 1.0, green: 0.98, blue: 0.941, alpha: 1.0),
            alternateBackgroundKey : UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0),
            highlightKey : UIColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0),
            alternateHighlightKey : UIColor(red: 0.824, green: 0.706, blue: 0.549, alpha: 1.0),
            foregroundKey : UIColor.darkTextColor(), highlightedForegroundKey : UIColor.blueColor() ],
        [ nameKey : "B", fontKey : "Avenir Next", backgroundKey : UIColor(red: 0.941, green: 1.000, blue: 0.941, alpha: 1.0),
            alternateBackgroundKey : UIColor(red: 0.686, green: 0.933, blue: 0.933, alpha: 1.0),
            highlightKey : UIColor(red: 1.0, green: 0.980, blue: 0.804, alpha: 1.0),
            alternateHighlightKey : UIColor(red: 0.518, green: 0.439, blue: 1.0, alpha: 1.0),
            foregroundKey : UIColor.darkTextColor(), highlightedForegroundKey : UIColor.greenColor() ],
        [ nameKey : "C", fontKey : "Menlo", backgroundKey : UIColor(red: 0.192, green: 0.310, blue: 0.310, alpha: 1.0),
            alternateBackgroundKey : UIColor(red: 0.412, green: 0.412, blue: 0.412, alpha: 1.0),
            highlightKey : UIColor(red: 0.420, green: 0.557, blue: 0.137, alpha: 1.0),
            alternateHighlightKey : UIColor(red: 0.698, green: 0.133, blue: 0.133, alpha: 1.0),
            foregroundKey : UIColor(red: 0.878, green: 1.0, blue: 1.0, alpha: 1.0),
            highlightedForegroundKey : UIColor.whiteColor() ]
    ]

    static var themeSetting: Int? {
        get {
            let setting = NSUserDefaults.standardUserDefaults().integerForKey(themeKey)
            // NSLog("Theme setting is %d", setting)
            return setting
        }
    }

    static var themeName: String? {
        get {
            if let index = themeSetting {
                let theme = themes[index] as [String: AnyObject]
                return theme[nameKey] as? NSString
            }
            return nil
        }
    }

    static func setThemeSetting(newTheme: Int!) {
        NSUserDefaults.standardUserDefaults().setInteger(newTheme, forKey: themeKey)
    }

    static var fontSetting: String? {
        get {
            let setting = themeSetting
            if let index = setting {
                let theme = themes[index] as [String: AnyObject]
                return theme[fontKey] as? NSString
            }
            return nil
        }
    }

    static func preferredFontDescriptorWithTextStyle(style: String!, italic: Bool=false) -> UIFontDescriptor! {
        let fontDesc = UIFontDescriptor.preferredFontDescriptorWithTextStyle(style) // just for the pointSize

        var name = fontSetting

        // NSLog("font setting is %@", name!)

        if !name {
            name = "Arial"
        }

        if style == UIFontTextStyleHeadline {
            name = "\(name!) Bold"
        }
        if italic {
            name = "\(name!) Italic"
        }

        // NSLog("Returning descriptor for font %@, size %f", name!, fontDesc.pointSize)
        return UIFontDescriptor(name: name, size: fontDesc.pointSize)
    }

    static func preferredFontForTextStyle(style: String!, italic: Bool=false) -> UIFont! {
        let fontDesc = preferredFontDescriptorWithTextStyle(style, italic: italic)
        let font = UIFont(descriptor: fontDesc, size: 0.0)
        // NSLog("Returning font from family %@, name %@", font.familyName, font.fontName)
        return font
    }

    static var backgroundColor: UIColor? {
        get {
            return getColor(backgroundKey)
        }
    }

    static var alternateBackgroundColor: UIColor {
        get {
            return getColor(alternateBackgroundKey)
        }
    }

    static var highlightColor: UIColor {
        get {
            return getColor(highlightKey)
        }
    }

    static var alternateHighlightColor: UIColor {
        get {
            return getColor(alternateHighlightKey)
        }
    }

    static var foregroundColor: UIColor {
        get {
            return getColor(foregroundKey)
        }
    }

    static var highlightedForegroundColor: UIColor {
        get {
            return getColor(highlightedForegroundKey)
        }
    }

    private static func getColor(key: String) -> UIColor! {
        let setting = themeSetting
        if let index = setting {
            let theme = themes[index] as [String: AnyObject]
            return theme[key] as? UIColor
        }

        let theme = themes[0] as [String: AnyObject]
        return theme[key] as? UIColor
    }
}
