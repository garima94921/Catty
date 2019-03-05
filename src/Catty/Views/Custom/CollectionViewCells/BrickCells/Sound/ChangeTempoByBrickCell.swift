/**
 *  Copyright (C) 2010-2019 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

import Foundation

@objc(ChangeTempoByBrickCell) class ChangeTempoByBrickCell: BrickCell {

    public var firstTextLabel: UILabel?
    public var tempoTextField: UITextField?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        BrickShapeFactory.drawSquareBrickShape(withFill: UIColor.soundBrickViolet(), stroke: UIColor.soundBrickStroke(), height: CGFloat(smallBrick), width: Util.screenWidth())
    }

    override static func cellHeight() -> CGFloat {
        return CGFloat(kBrickHeight1h)
    }

    override func hookUpSubViews(_ inlineViewSubViews: [Any]!) {
        self.firstTextLabel = inlineViewSubViews[0] as? UILabel
        self.tempoTextField = inlineViewSubViews[1] as? UITextField
    }
}
