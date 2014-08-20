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

class GradientView: UIView {

    var firstColor: UIColor
    var secondColor: UIColor
    var startPoint: CGPoint
    var endPoint: CGPoint

    init(frame: CGRect, firstColor: UIColor!, secondColor: UIColor!, startPoint: CGPoint, endPoint: CGPoint) {
        self.firstColor = firstColor
        self.secondColor = secondColor
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        firstColor = UIColor.clearColor()
        secondColor = UIColor.clearColor()
        startPoint = CGPointZero
        endPoint = CGPointZero
        super.init(coder: aDecoder)
    }

    override func drawRect(rect: CGRect)
    {
        CGHelper.paintGradientFirstColor(firstColor, secondColor: secondColor, bounds: rect, startPoint: startPoint, endPoint: endPoint)
    }
}
