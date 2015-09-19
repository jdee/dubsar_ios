/*
Dubsar Dictionary Project
Copyright (C) 2010-15 Jimmy Dee

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

    // MARK: User default keys from settings bundle
    static let themeKey = "DubsarTheme"
    static let offlineKey = "DubsarOffline"
    static let autoUpdateKey = "DubsarAutoUpdate"
    static let autoCorrectKey = "DubsarAutoCorrect"
    static let lastUpdateCheckTimeKey = "DubsarLastUpdateCheckTime"
    static let secureBookmarksKey = "DubsarSecureBookmarks"

    // MARK: Dev key(s)
    static let productionKey = "DubsarProduction"

    // MARK: Keys into the theme dictionaries below
    static let nameKey = "name"
    static let fontKey = "font"
    static let backgroundKey = "background"
    static let alternateBackgroundKey = "alternateBackground"
    static let highlightKey = "highlight"
    static let alternateHighlightKey = "alternateHighlight"
    static let foregroundKey = "foreground"
    static let highlightedForegroundKey = "highlightedForeground"
    static let barKey = "bar"
    static let activityKey = "activity"
    static let twitterColorKey = "twitterColor"

    static let defaultOfflineSetting = true
    static let defaultThemeSetting = 1

    // MARK: Dictionaries defining the available themes.
    static let themes = [
        [ nameKey : "Scribe", fontKey : "Palatino",
            backgroundKey : UIColor(red: 1.0, green: 0.98, blue: 0.941, alpha: 1.0),
            alternateBackgroundKey : UIColor(red: 0.855, green: 0.647, blue: 0.125, alpha: 1.0),
            highlightKey : UIColor(red: 0.529, green: 0.808, blue: 0.980, alpha: 1.0),
            alternateHighlightKey : UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0),
            foregroundKey : UIColor(red: 0.363, green: 0.181, blue: 0.050, alpha: 1.0),
            highlightedForegroundKey : UIColor(red: 0.580, green: 0.0, blue: 0.827, alpha: 1.0),
            barKey: "light", activityKey : "gray", twitterColorKey: "blue" ],
        [ nameKey : "Tigris", fontKey : "Avenir Next",
            backgroundKey : UIColor(red: 0.941, green: 1.000, blue: 0.941, alpha: 1.0),
            alternateBackgroundKey : UIColor(red: 0.686, green: 0.933, blue: 0.933, alpha: 1.0),
            highlightKey : UIColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0),
            alternateHighlightKey : UIColor(red: 0.518, green: 0.439, blue: 1.0, alpha: 1.0),
            foregroundKey : UIColor.darkTextColor(),
            highlightedForegroundKey : UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),
            barKey: "light", activityKey : "gray", twitterColorKey: "blue" ],
        [ nameKey : "Augury", fontKey : "Menlo",
            backgroundKey : UIColor(red: 0.192, green: 0.310, blue: 0.310, alpha: 1.0),
            alternateBackgroundKey : UIColor(red: 0.412, green: 0.412, blue: 0.412, alpha: 1.0),
            highlightKey : UIColor(red: 0.420, green: 0.557, blue: 0.137, alpha: 1.0),
            alternateHighlightKey : UIColor(red: 0.741, green: 0.718, blue: 0.420, alpha: 1.0),
            foregroundKey : UIColor(red: 0.878, green: 1.0, blue: 1.0, alpha: 1.0),
            highlightedForegroundKey : UIColor(red: 0.0, green: 1.000, blue: 1.000, alpha: 1.0),
            barKey: "dark", activityKey : "white", twitterColorKey: "white" ]
    ]

    // MARK: Wrappers around  NSUserDefaults
    static var themeSetting: Int {
        get {
        if NSUserDefaults.standardUserDefaults().objectForKey(themeKey) == nil {
        NSUserDefaults.standardUserDefaults().setInteger(defaultThemeSetting, forKey: themeKey)
        }
        return NSUserDefaults.standardUserDefaults().integerForKey(themeKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: themeKey)
        }
    }

    static var offlineSetting: Bool {
        get {
        if NSUserDefaults.standardUserDefaults().objectForKey(offlineKey) == nil {
        NSUserDefaults.standardUserDefaults().setBool(defaultOfflineSetting, forKey: offlineKey)
        }

        return NSUserDefaults.standardUserDefaults().boolForKey(offlineKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: offlineKey)
        }
    }

    static var productionSetting: Bool {
        get {
        #if DEBUG
        return NSUserDefaults.standardUserDefaults().boolForKey(productionKey)
        #else
        return true
        #endif
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: productionKey)
        }
    }

    static var autoUpdateSetting: Bool {
        get {
        return NSUserDefaults.standardUserDefaults().boolForKey(autoUpdateKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: autoUpdateKey)
        }
    }

    static var autoCorrectSetting: Bool {
        get {
        return NSUserDefaults.standardUserDefaults().boolForKey(autoCorrectKey)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: autoCorrectKey)
        }
    }

    static var secureBookmarksSetting: Bool {
        get {
        #if DEBUG
        return NSUserDefaults.standardUserDefaults().boolForKey(secureBookmarksKey)
        #else
        return false
        #endif
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: secureBookmarksKey)
        }
    }

    static var lastUpdateCheckTime: time_t {
        get {
            return NSUserDefaults.standardUserDefaults().integerForKey(lastUpdateCheckTimeKey)
        }
    }

    static func updateLastUpdateCheckTime() {
        var now: time_t = 0;
        time(&now);
        NSUserDefaults.standardUserDefaults().setInteger(now, forKey: lastUpdateCheckTimeKey)
    }

    // MARK: Derived conveniences
    static var themeName: String? {
        get {
            let setting: NSString? = getThemeProperty(nameKey)
            return setting as? String
        }
    }

    static var fontSetting: String? {
        get {
            let setting: NSString? = getThemeProperty(fontKey)
            return setting as? String
        }
    }

    static var barStyle: UIBarStyle {
        get {
            let style: NSString = getThemeProperty(barKey)
            if style == "dark" {
                return .Black
            }
            return .Default
        }
    }

    static var activityIndicatorViewStyle: UIActivityIndicatorViewStyle {
        get {
            let style: NSString = getThemeProperty(activityKey)
            if style == "gray" {
                return .Gray
            }
            return .White
        }
    }
    
    static var twitterColor: String {
        get {
            return getThemeProperty(twitterColorKey) as NSString as String
        }
    }

    static var rootURL: NSURL {
        get {
            let production = productionSetting
            return NSURL(string: production ? DUBSAR_PRODUCTION_ROOT_URL : DUBSAR_DEVELOPMENT_ROOT_URL)!
        }
    }

    // MARK: Font and font descriptor retrieval
    static func preferredFontDescriptorWithTextStyle(style: String!, italic: Bool=false) -> UIFontDescriptor! {
        let fontDesc = UIFontDescriptor.preferredFontDescriptorWithTextStyle(style) // just for the pointSize

        var name = fontSetting

        // DMLOG("font setting is %@", name!)

        if name == nil {
            name = "Arial"
        }

        if style == UIFontTextStyleHeadline {
            name = "\(name!) Bold"
        }
        if italic {
            name = "\(name!) Italic"
        }

        // DMLOG("Returning descriptor for font %@, size %f", name!, fontDesc.pointSize)
        return UIFontDescriptor(name: name!, size: fontDesc.pointSize)
    }

    static func preferredFontForTextStyle(style: String!, italic: Bool=false) -> UIFont! {
        let fontDesc = preferredFontDescriptorWithTextStyle(style, italic: italic)
        let font = UIFont(descriptor: fontDesc, size: 0.0)
        // DMLOG("Returning font from family %@, name %@", font.familyName, font.fontName)
        return font
    }

    // MARK: Color scheme (derived props)
    static var backgroundColor: UIColor {
        get {
            return getThemeProperty(backgroundKey)
        }
    }

    static var alternateBackgroundColor: UIColor {
        get {
            return getThemeProperty(alternateBackgroundKey)
        }
    }

    static var highlightColor: UIColor {
        get {
            return getThemeProperty(highlightKey)
        }
    }

    static var alternateHighlightColor: UIColor {
        get {
            return getThemeProperty(alternateHighlightKey)
        }
    }

    static var foregroundColor: UIColor {
        get {
            return getThemeProperty(foregroundKey)
        }
    }

    static var highlightedForegroundColor: UIColor {
        get {
            return getThemeProperty(highlightedForegroundKey)
        }
    }

    // MARK: DRYness
    private static func getThemeProperty<T: AnyObject>(key: String) -> T! {
        let index = themeSetting
        let theme = themes[index] as [String: AnyObject]
        return theme[key] as? T
    }
    
}
