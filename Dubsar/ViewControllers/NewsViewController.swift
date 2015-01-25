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

class NewsViewController: BaseViewController, UIWebViewDelegate {

    class var identifier : String {
        get {
            return "News"
        }
    }

    @IBOutlet var newsWebView : UIWebView!

    let url = "https://dubsar.info/ios_news_v200"

    private var ready = false
    private var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        displayMessage("loading...")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if loading {
            UIApplication.sharedApplication().stopUsingNetwork()
        }
    }

    @IBAction func done(sender: UIBarButtonItem!) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func webViewDidFinishLoad(webView: UIWebView!) {
        if !ready {
            ready = true

            let request = NSURLRequest(URL: NSURL(string: url)!)

            webView.loadRequest(request)
            UIApplication.sharedApplication().startUsingNetwork()
            return
        }

        UIApplication.sharedApplication().stopUsingNetwork()
        loading = false
    }

    func webViewDidStartLoad(webView: UIWebView!) {
        loading = true
    }

    func webView(webView: UIWebView!, didFailLoadWithError error: NSError!) {
        let errorMessage = error.localizedDescription
        displayMessage(errorMessage)
        DMERROR("error loading news: \(errorMessage)")
        UIApplication.sharedApplication().stopUsingNetwork()
        loading = false
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            let application = UIApplication.sharedApplication()
            if application.canOpenURL(request.URL) {
                application.openURL(request.URL)
            }
            // This is why I use dubsar:/// URLs, like file:/// URLs, without a host.
            else if request.URL.scheme! == "twitter" && request.URL.host! == "user" && request.URL.query!.hasPrefix("id=") {
                let webUrl = NSURL(string: "https://twitter.com/intent/follow?user_\(request.URL.query!)")
                application.openURL(webUrl!)
            }
            return false
        }
        return true
    }

    func displayMessage(text: String) {
        let background = AppConfiguration.backgroundColor
        let foreground = AppConfiguration.foregroundColor
        let font = AppConfiguration.preferredFontForTextStyle(UIFontTextStyleHeadline, italic: false)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        background.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let bgCss = String(format: "%02x%02x%02x", Int(red*255), Int(green*255), Int(blue*255))

        foreground.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let fgCss = String(format: "%02x%02x%02x", Int(red*255), Int(green*255), Int(blue*255))

        DMTRACE("Presenting news loading view with bg #\(bgCss), fg #\(fgCss)")

        var html = String(format: "<html><body style=\"background-color: #\(bgCss);\"><h1 style=\"color: #\(fgCss); text-align: center; margin-top: 2ex; font: bold \(Int(font.pointSize))pt \(font.familyName)\">%@</h1></body></html>", text)
        newsWebView.loadHTMLString(html, baseURL: nil)
    }
}
