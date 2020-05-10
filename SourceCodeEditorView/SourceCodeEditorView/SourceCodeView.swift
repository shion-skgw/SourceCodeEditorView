//
//  SourceCodeView.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/10.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

final class SourceCodeView: UITextView {

	private var gutterWidth: CGFloat!
	private var verticalMargin: CGFloat!

	private var gutterColor: CGColor!
	private var gutterEdgeColor: CGColor!
	private var lineHighlightColor: CGColor!

	private let _textContainer: NSTextContainer
	private let _layoutManager: LayoutManager
	private let _textStorage: TextStorage

	override var textContainer: NSTextContainer {
		return _textContainer
	}
	override var layoutManager: NSLayoutManager {
		return _layoutManager
	}
	override var textStorage: NSTextStorage {
		return _textStorage
	}

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		fatalError()
	}

	required init?(coder: NSCoder) {
		// TextContainer
		let textContainer = NSTextContainer()
		self._textContainer = textContainer

		// LayoutManager
		let layoutManager = LayoutManager()
		layoutManager.addTextContainer(textContainer)
		self._layoutManager = layoutManager

		// TextStorage
		let textStorage = TextStorage()
		textStorage.addLayoutManager(layoutManager)
		self._textStorage = textStorage

		super.init(frame: CGRect(x: 10, y: 20, width: 200, height: 400), textContainer: textContainer)
		self.autocapitalizationType = .none
		self.autocorrectionType = .no
		self.contentMode = .redraw

		common()
	}

	func common() {
		// Config
		let font = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
		set(font: font, fontColor: UIColor.black)
		set(backgroundColor: UIColor.white.brightness(0.9))
		set(gutterWidth: 40.0, verticalMargin: 4.0)
		set(textAreaWidth: self._textContainer.size.width)
		set(tabWidth: 4)
		let tokens: [Token] = [
			Token(name: "func", type: .keyword, pattern: "func"),
			Token(name: "comment", type: .comment, pattern: "/\\*[\\s\\S]*?\\*/"),
		]
		set(tokens: tokens)
	}

	override func draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()!
		let height = max(bounds.height, self.contentSize.height) + 200

		// Draw gutter
		context.setFillColor(gutterColor)
		let gutterRect = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: gutterWidth, height: height)
		context.fill(gutterRect)

		// Draw gutter edge
		context.setFillColor(gutterEdgeColor)
		let gutterEdgeRect = CGRect(x: gutterWidth, y: bounds.origin.y - 0.5, width: 0.5, height: height)
		context.fill(gutterEdgeRect)

		// Draw select line
		let a = self._layoutManager.boundingRect(forGlyphRange: (self._textStorage.string as NSString).lineRange(for: selectedRange), in: _textContainer)
		let x: CGFloat = gutterWidth + 2.0
		let y: CGFloat = verticalMargin + a.origin.y - 1.0
		let width = _textContainer.size.width - 4.0
		let _height = (a.origin.x == 0.0 ? font!.lineHeight : a.height) + 2.0
		let re = CGRect(x: x, y: y, width: width, height: _height)
		context.setFillColor(lineHighlightColor)
		context.fill(re)

		super.draw(rect)
	}

	override var selectedTextRange: UITextRange? {
		didSet {
			self._layoutManager.selectedRange = selectedRange
			self.setNeedsDisplay()
		}
	}

	override func insertText(_ text: String) {
		self.setNeedsDisplay()
		super.insertText(text)
	}

	override func deleteBackward() {
		self.setNeedsDisplay()
		super.deleteBackward()
	}

	func set(font: UIFont, fontColor: UIColor) {
		self.font = font
		self.textColor = fontColor
		self._textStorage.set(font: font, color: fontColor)
		self._layoutManager.set(font: font)
	}

	func set(backgroundColor: UIColor) {
		self.backgroundColor = backgroundColor
		self.lineHighlightColor = backgroundColor.brightness(0.7).cgColor
		self.gutterColor = backgroundColor.brightness(0.9).cgColor
		self.gutterEdgeColor = backgroundColor.brightness(0.7).cgColor
		self._layoutManager.set(backgroundColor: backgroundColor)
	}

	func set(gutterWidth: CGFloat, verticalMargin: CGFloat) {
		self.textContainerInset = UIEdgeInsets(top: verticalMargin, left: gutterWidth, bottom: verticalMargin, right: 0)
		self.gutterWidth = gutterWidth
		self.verticalMargin = verticalMargin
		self._layoutManager.set(gutterWidth: gutterWidth, verticalMargin: verticalMargin)
	}

	func set(tabWidth: Int) {
		self._textStorage.set(tabWidth: tabWidth)
	}

	func set(tokens: [Token]) {
		self._textStorage.set(tokens: tokens)
	}

	func set(textAreaWidth: CGFloat) {
		self._layoutManager.set(textAreaWidth: textAreaWidth)
	}

}
