//
//  TextStorage.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit.NSTextStorage

extension UIFont {
	static var systemFont: UIFont {
		return UIFont.systemFont(ofSize: UIFont.systemFontSize)
	}
}

final class TextStorage: NSTextStorage {

	private var attributedString: NSMutableAttributedString
	private var tokens: [Token]
	private var normalTextAttribute: [NSAttributedString.Key: Any]

	override var string: String {
		return attributedString.string
	}

	// MARK: - Initialize

	override init() {
		self.attributedString = NSMutableAttributedString()
		self.tokens = [Token]()
		self.normalTextAttribute = [NSAttributedString.Key: Any]()
		super.init()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Override

	override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
		return attributedString.attributes(at: location, effectiveRange: range)
	}

	override func replaceCharacters(in range: NSRange, with str: String) {
		beginEditing()
		attributedString.replaceCharacters(in: range, with: str)
		edited([.editedCharacters, .editedAttributes], range: range, changeInLength: str.count - range.length)
		endEditing()
	}

	override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
		beginEditing()
		attributedString.setAttributes(attrs, range: range)
		edited(.editedAttributes, range: range, changeInLength: 0)
		endEditing()
	}

	override func processEditing() {
		let lineRange = (string as NSString).lineRange(for: editedRange)
		setAttributes(normalTextAttribute, range: lineRange)
		applyTokenStyle(range: lineRange)
		super.processEditing()
	}

	// MARK: - Syntax highlight

	private func applyTokenStyle(range: NSRange) {
		let fullRange = NSMakeRange(0, string.count)

		for token in tokens {
			token.regex.enumerateMatches(in: string, options: [], range: token.isMultipleLines ? fullRange : range) {
				[unowned self, token] (result, _, _) in
				guard let range = result?.range else {
					return
				}
				var attribute = self.normalTextAttribute
				attribute[.foregroundColor] = token.type.color
				addAttributes(attribute, range: range)
			}
		}
	}

	// MARK: - Setter

	func set(font: UIFont, color: UIColor) {
		self.normalTextAttribute[.font] = font
		self.normalTextAttribute[.foregroundColor] = color
		update()
	}

	func set(tabWidth: Int) {
		let paragraphStyle = normalTextAttribute[.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
		paragraphStyle.tabStops?.removeAll()
		let font = normalTextAttribute[.font] as? UIFont ?? UIFont.systemFont
		let baseTabWidth = " ".size(withAttributes: [ .font: font ]).width * CGFloat(tabWidth)
		for i in 1...50 {
			let textTab = NSTextTab(textAlignment: .left, location: baseTabWidth * CGFloat(i))
			paragraphStyle.addTabStop(textTab)
		}
		self.normalTextAttribute[.paragraphStyle] = paragraphStyle
		update()
	}

	func set(tokens: [Token]) {
		self.tokens = tokens
		update()
	}

	private func update() {
		let fullRange = NSMakeRange(0, string.count)
		setAttributes(normalTextAttribute, range: fullRange)
		applyTokenStyle(range: fullRange)
	}

}
