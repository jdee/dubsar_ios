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

class FAQViewController: BaseViewController, UIWebViewDelegate {

    class var identifier : String {
        get {
            return "FAQ"
        }
    }

    @IBOutlet var faqWebView : UIWebView!

    let url = "https://m.dubsar-dictionary.com/ios_faq_v200"

    private var ready = false

    override func viewDidLoad() {
        super.viewDidLoad()
        displayMessage("loading...")
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.sharedApplication().stopUsingNetwork()
    }

    @IBAction func done(sender: UIBarButtonItem!) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func webViewDidFinishLoad(webView: UIWebView!) {
        if !ready {
            ready = true

            let request = NSURLRequest(URL: NSURL(string: url))

            webView.loadRequest(request)
            return
        }
    }

    func webViewDidStartLoad(webView: UIWebView!) {
        UIApplication.sharedApplication().startUsingNetwork()
    }

    func webView(webView: UIWebView!, didFailLoadWithError error: NSError!) {
        let errorMessage = error.localizedDescription
        displayMessage(errorMessage)
        NSLog("error loading FAQ: %@", errorMessage)
    }

    func displayMessage(text: String) {
        var html = String(format: "<html><body style=\"background-color: #e0e0ff;\"><h1 style=\"color: #1c94c4; text-align: center; margin-top: 2ex; font: bold 24pt Trebuchet MS\">%@</h1></body></html>", text)
        faqWebView.loadHTMLString(html, baseURL: nil)
    }

    override func setupToolbar() {
        addHomeButton()
        super.setupToolbar()
    }
}
