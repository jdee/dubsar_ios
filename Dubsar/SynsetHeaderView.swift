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

class SynsetHeaderView: UIView, UITableViewDataSource, UITableViewDelegate {

    class var margin : CGFloat {
        get {
            return 8
        }
    }

    let synset : DubsarModelsSynset
    var sense : DubsarModelsSense? // optional and variable; represents word context

    var glossLabel : UILabel?
    var lexnameLabel : UILabel?
    var synonymTableView : UITableView?

    init(synset: DubsarModelsSynset!, frame: CGRect) {
        self.synset = synset
        super.init(frame: frame)

        build()
    }

    override func setNeedsLayout() {
        build()
        super.setNeedsLayout()
    }

    func build() {
        if !synset.complete {
            return
        }

        let margin = SynsetHeaderView.margin
        var constrainedSize = bounds.size
        constrainedSize.width -= 2 * margin

        let headlineFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)

        // Gloss label
        let glossSize = synset.glossSizeWithConstrainedSize(constrainedSize, font: headlineFont)

        glossLabel?.removeFromSuperview()
        glossLabel = UILabel(frame: CGRectMake(margin, margin, constrainedSize.width, glossSize.height))
        glossLabel!.font = headlineFont
        glossLabel!.lineBreakMode = .ByWordWrapping
        glossLabel!.numberOfLines = 0
        glossLabel!.text = synset.gloss
        addSubview(glossLabel)

        // Lexname label
        let lexnameText = "<\(synset.lexname)>" as NSString
        let lexnameSize = lexnameText.sizeOfTextWithConstrainedSize(constrainedSize, font: headlineFont)

        lexnameLabel?.removeFromSuperview()
        lexnameLabel = UILabel(frame: CGRectMake(margin, 2 * margin + glossSize.height, constrainedSize.width, lexnameSize.height))
        lexnameLabel!.font = headlineFont
        lexnameLabel!.lineBreakMode = .ByWordWrapping
        lexnameLabel!.numberOfLines = 0
        lexnameLabel!.text = lexnameText
        addSubview(lexnameLabel)

        bounds.size.height = glossSize.height + lexnameSize.height + 3 * margin

        // synonymTableView = UITableView(frame: <#CGRect#>, style: .Plain)
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection: Int) -> Int {
        return synset.complete ? synset.senses.count : 1
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath: NSIndexPath!) -> UITableViewCell! {
        return nil
    }
}
