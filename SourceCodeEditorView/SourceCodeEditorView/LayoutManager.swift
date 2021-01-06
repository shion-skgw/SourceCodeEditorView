//
//  LayoutManager.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit.NSLayoutManager

final class LayoutManager: NSLayoutManager {

    private static let invisibles: [String: NSRegularExpression] = [
        "\u{21B5}": try! NSRegularExpression(pattern: "\n", options: []),       // "↵" New line
        "\u{226B}": try! NSRegularExpression(pattern: "\t", options: []),       // "≫" Tab
        "\u{22C5}": try! NSRegularExpression(pattern: "\u{0020}", options: []), // "⋅" Space
        "\u{25A1}": try! NSRegularExpression(pattern: "\u{3000}", options: []), // "□" Full space
    ]

    var lineHeight: CGFloat = CGFloat.zero
    var showInvisibles: Bool = false
    var gutterWidth: CGFloat = CGFloat.zero
    var verticalMargin: CGFloat = CGFloat.zero
    var invisiblesAttribute: [NSAttributedString.Key: Any] = [:]

    override init() {
        super.init()
        self.usesFontLeading = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard showInvisibles, let text = textStorage?.string else {
            return
        }

        for invisible in LayoutManager.invisibles {
            let char = invisible.key
            let charSize = char.size(withAttributes: invisiblesAttribute)

            invisible.value.enumerateMatches(in: text, options: [], range: glyphsToShow) {
                [weak self, char, charSize] (result, _, _) in
                guard let range = result?.range, let self = self else {
                    return
                }

                let position = range.upperBound - 1
                let rect = lineFragmentRect(forGlyphAt: position, effectiveRange: nil)
                var point = location(forGlyphAt: position)
                point.x += rect.origin.x + self.gutterWidth
                point.y = rect.origin.y + self.verticalMargin + (self.lineHeight - charSize.height) / 2.0
                char.draw(at: point, withAttributes: self.invisiblesAttribute)
            }
        }
    }

    override func boundingRect(forGlyphRange glyphRange: NSRange, in container: NSTextContainer) -> CGRect {
        var rect = super.boundingRect(forGlyphRange: glyphRange, in: container)

        // X, height adjustment of line break-only lines.
        rect.origin.x = container.lineFragmentPadding
        if rect.size.width == container.size.width - container.lineFragmentPadding {
            rect.size.height -= lineHeight
        }
        return rect
    }

}
