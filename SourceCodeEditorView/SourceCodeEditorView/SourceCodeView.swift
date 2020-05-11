//
//  SourceCodeView.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/10.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

final class SourceCodeView: UITextView {

	private var highlightLine = true
	private var lineHeight = UIFont.systemFont.lineHeight
	private var gutterWidth = CGFloat(40.0)
	private var verticalMargin = CGFloat(4.0)
	private var gutterColor = UIColor.lightGray.cgColor
	private var gutterEdgeColor = UIColor.lightGray.cgColor
	private var lineHighlightColor = UIColor.lightGray.cgColor

	private var lineNumberAttribute: [NSAttributedString.Key: Any] = [:]

	private let codeTextContainer: NSTextContainer
	private let codeLayoutManager: LayoutManager
	private let codeTextStorage: TextStorage

	override var textContainer: NSTextContainer {
		return codeTextContainer
	}
	override var layoutManager: NSLayoutManager {
		return codeLayoutManager
	}
	override var textStorage: NSTextStorage {
		return codeTextStorage
	}

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		fatalError()
	}

	required init?(coder: NSCoder) {
		// TextContainer
		let textContainer = NSTextContainer()

		// LayoutManager
		let layoutManager = LayoutManager()
		layoutManager.usesFontLeading = false
		layoutManager.addTextContainer(textContainer)

		// TextStorage
		let textStorage = TextStorage()
		textStorage.addLayoutManager(layoutManager)

		// Initialize
		self.codeTextContainer = textContainer
		self.codeLayoutManager = layoutManager
		self.codeTextStorage = textStorage
//		super.init(coder: coder)
		super.init(frame: CGRect(x: 10, y: 30, width: 300, height: 300), textContainer: textContainer)
		configure()
	}

	private func configure() {
		// View config
		self.autocapitalizationType = .none
		self.autocorrectionType = .no
		self.contentMode = .redraw
		self.textContainerInset = UIEdgeInsets(top: 4, left: 40, bottom: 4, right: 0)

		// Editor config
		let font = UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)
		let fontColor = UIColor.black
		let backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1)
		let tokens = [
			Token(name: "return", type: .keyword, pattern: "return"),
			Token(name: "func", type: .keyword, pattern: "func"),
			Token(name: "String", type: .function, pattern: "String"),
			Token(name: "comment", type: .comment, pattern: "//.*"),
			Token(name: "comment", type: .comment, pattern: "/\\*[\\s\\S]*?\\*/", isMultipleLines: true),
		]
		set(font: font, fontColor: fontColor)
		set(backgroundColor: backgroundColor)
		set(tokens: tokens)
		set(tabWidth: 4)
		set(gutterWidth: 40.0, verticalMargin: 4.0)
	}

	override var selectedTextRange: UITextRange? {
		didSet {
			setNeedsDisplay()
		}
	}

	override func insertText(_ text: String) {
		setNeedsDisplay()
		super.insertText(text)
	}

	override func deleteBackward() {
		setNeedsDisplay()
		super.deleteBackward()
	}

	func set(font: UIFont, fontColor: UIColor) {
		self.font = font
		self.textColor = fontColor
		self.lineHeight = font.lineHeight
		self.lineNumberAttribute[.font] = font.withSize(floor(font.pointSize * 0.8))
		self.codeLayoutManager.set(font: font)
		self.codeTextStorage.set(font: font, color: fontColor)
	}

	func set(backgroundColor: UIColor) {
		self.backgroundColor = backgroundColor
		self.lineNumberAttribute[.foregroundColor] = backgroundColor.brightness(0.3)
		self.gutterColor = backgroundColor.brightness(0.8).cgColor
		self.gutterEdgeColor = backgroundColor.brightness(0.3).cgColor
		self.codeLayoutManager.set(backgroundColor: backgroundColor)
	}

	func set(gutterWidth: CGFloat, verticalMargin: CGFloat) {
		self.textContainerInset = UIEdgeInsets(top: verticalMargin, left: gutterWidth, bottom: verticalMargin, right: 0)
		self.gutterWidth = gutterWidth
		self.verticalMargin = verticalMargin
		self.codeLayoutManager.set(gutterWidth: gutterWidth, verticalMargin: verticalMargin)
	}

	func set(tabWidth: Int) {
		self.codeTextStorage.set(tabWidth: tabWidth)
	}

	func set(tokens: [Token]) {
		self.codeTextStorage.set(tokens: tokens)
	}

}

// MARK: - Draw

extension SourceCodeView {

	override func draw(_ rect: CGRect) {
		guard let cgContext = UIGraphicsGetCurrentContext() else {
			fatalError()
		}

		// Draw gutter
		drawGutter(cgContext: cgContext)

		// Draw line number
		drawLineNumber()

		// Draw line highlight
		if highlightLine {
			drawLineHighlight(cgContext: cgContext)
		}

		super.draw(rect)
	}

	private func drawGutter(cgContext: CGContext) {
		let height = max(bounds.height, contentSize.height)

		// Draw gutter
		let gutterRect = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: gutterWidth, height: height)
		cgContext.setFillColor(gutterColor)
		cgContext.fill(gutterRect)

		// Draw gutter edge
		let gutterEdgeRect = CGRect(x: gutterWidth, y: bounds.origin.y - 0.5, width: 0.5, height: height)
		cgContext.setFillColor(gutterEdgeColor)
		cgContext.fill(gutterEdgeRect)
	}

	private func drawLineNumber() {
		enumerateLine() {
			[unowned self] (lineNum, usedRect, _) in
			let number = "\(lineNum)"
			let size = number.size(withAttributes: self.lineNumberAttribute)
			let x = self.gutterWidth - size.width - 4.0
			let y = self.verticalMargin + usedRect.origin.y + (self.lineHeight / 2.0 - size.height / 2.0)
			let rect = CGRect(x: x, y: y, width: size.width, height: size.height)
			number.draw(in: rect, withAttributes: self.lineNumberAttribute)
		}
	}

	private func drawLineHighlight(cgContext: CGContext) {
		let lineRange = (textStorage.string as NSString).lineRange(for: selectedRange)
		var rect = boundingRect(forGlyphRange: lineRange)
		rect.origin.x = gutterWidth + 2.0
		rect.origin.y += verticalMargin - 1.0
		rect.size.width = textContainer.size.width - 4.0
		rect.size.height += 2.0
		cgContext.setFillColor(lineHighlightColor)
		cgContext.fill(rect)
	}

	private func enumerateLine(using block: @escaping (Int, CGRect, UnsafeMutablePointer<Bool>) -> Void) {
		let text = textStorage.string as NSString
		var lineNumber = 1
		var currentRange = text.lineRange(for: NSMakeRange(0, 0))
		var stop = false

		while !stop {
			let index = NSMaxRange(currentRange)
			var usedRect = boundingRect(forGlyphRange: currentRange)
			block(lineNumber, usedRect, &stop)
			if text.length == 0 {
				return
			} else if text.length == index {
				if text.substring(with: NSMakeRange(index - 1, 1)) == "\n" {
					usedRect.origin.y += usedRect.size.height
					block(lineNumber + 1, usedRect, &stop)
				}
				return
			}
			currentRange = text.lineRange(for: NSMakeRange(index, 0))
			lineNumber += 1
		}
	}

	private func boundingRect(forGlyphRange range: NSRange) -> CGRect {
		var rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)

		// X, height adjustment of line break-only lines.
		rect.origin.x = textContainer.lineFragmentPadding
		if rect.size.width == textContainer.size.width - textContainer.lineFragmentPadding {
			rect.size.height -= lineHeight
		}
		return rect
	}

}
