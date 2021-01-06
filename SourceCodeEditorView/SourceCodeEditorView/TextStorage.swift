//
//  TextStorage.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit.NSTextStorage

final class TextStorage: NSTextStorage {

    private let content: NSMutableAttributedString
    var tokens: [Token]
    var textAttribute: [NSAttributedString.Key: Any] {
        didSet {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.tabStops?.removeAll()
            let baseTabWidth = " ".size(withAttributes: self.textAttribute).width * 4.0
            for i in 1 ... 100 {
                let textTab = NSTextTab(textAlignment: .left, location: baseTabWidth * CGFloat(i))
                paragraphStyle.addTabStop(textTab)
            }
            self.textAttribute[.paragraphStyle] = paragraphStyle
        }
    }

    override var string: String {
        return content.string
    }

    override init() {
        self.content = NSMutableAttributedString()
        self.tokens = []
        self.textAttribute = [:]
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return content.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        content.replaceCharacters(in: range, with: str)
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: str.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        content.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func processEditing() {
        let lineRange = (string as NSString).lineRange(for: editedRange)
        setAttributes(textAttribute, range: lineRange)
        applySyntaxHighlight(lineRange)
        super.processEditing()
    }

    private func applySyntaxHighlight(_ range: NSRange) {
        for token in tokens {
            token.regex.enumerateMatches(in: string, options: [], range: token.isMultipleLines ? string.range : range) {
                [weak self, token] (result, _, _) in
                guard let range = result?.range, let self = self else {
                    return
                }
                self.content.addAttributes(token.textAttribute, range: range)
            }
        }
    }

}

extension String {
    var range: NSRange {
        NSMakeRange(0, utf16.count)
    }
}
