//
//  LayoutManager.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

extension UIColor {

	func brightness(_ value: CGFloat) -> UIColor {
		var hue = CGFloat.zero
		var saturation = CGFloat.zero
		var brightness = CGFloat.zero
		var alpha = CGFloat.zero
		if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
			return UIColor(hue: hue, saturation: saturation, brightness: brightness * value, alpha: alpha)
		} else {
			return .black
		}
	}

}

final class LayoutManager: NSLayoutManager, NSLayoutManagerDelegate {

	var highlightLine: Bool
	var showInvisibles: Bool
	var selectedRange: NSRange

	private var textAreaWidth: CGFloat
	private var gutterWidth: CGFloat
	private var verticalMargin: CGFloat
	private var lineHeight: CGFloat
	private var lineNumberAttribute: [NSAttributedString.Key: Any]
	private var invisiblesAttribute: [NSAttributedString.Key: Any]
	private var lineHighlightColor: UIColor

	private var lastParaLocation: Int
	private var lastParaNumber: Int

	private let invisibles: [String: NSRegularExpression] = [
		"\u{21B5}": try! NSRegularExpression(pattern: "[\r\n]", options: []),
		"\u{226B}": try! NSRegularExpression(pattern: "\t", options: []),
		"\u{22C5}": try! NSRegularExpression(pattern: "\u{0020}", options: []),
		"\u{25A1}": try! NSRegularExpression(pattern: "\u{3000}", options: []),
	]

	// MARK: - Initialize

	override init() {
		self.highlightLine = true
		self.showInvisibles = true
		self.selectedRange = NSRange()
		self.textAreaWidth = 100.0
		self.gutterWidth = 40.0
		self.verticalMargin = 4.0
		self.lineHeight = UIFont.systemFont(ofSize: UIFont.systemFontSize).lineHeight
		self.lineNumberAttribute = [NSAttributedString.Key: Any]()
		self.invisiblesAttribute = [NSAttributedString.Key: Any]()
		self.lineHighlightColor = UIColor.lightGray
		self.lastParaLocation = 0
		self.lastParaNumber = 0
		super.init()
		self.delegate = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Override

	override func processEditing(for textStorage: NSTextStorage,
			edited editMask: NSTextStorage.EditActions,
			range newCharRange: NSRange,
			changeInLength delta: Int,
			invalidatedRange invalidatedCharRange: NSRange) {
		super.processEditing(
			for: textStorage, edited:editMask, range: newCharRange, changeInLength: delta, invalidatedRange: invalidatedCharRange)
		if invalidatedCharRange.location < lastParaLocation {
			lastParaLocation = 0
			lastParaNumber = 0
		}
	}

	override func setLineFragmentRect(_ fragmentRect: CGRect, forGlyphRange glyphRange: NSRange, usedRect: CGRect) {
		var fragmentRect = fragmentRect
		fragmentRect.size.height = self.lineHeight
		var usedRect = usedRect
		usedRect.size.height = self.lineHeight
		super.setLineFragmentRect(fragmentRect, forGlyphRange: glyphRange, usedRect: usedRect)
	}

	override func setExtraLineFragmentRect(_ fragmentRect: CGRect, usedRect: CGRect, textContainer container: NSTextContainer) {
		var fragmentRect = fragmentRect
		fragmentRect.size.height = self.lineHeight
		var usedRect = usedRect
		usedRect.size.height = self.lineHeight
		super.setExtraLineFragmentRect(fragmentRect, usedRect: usedRect, textContainer: container)
	}

	// MARK: - Delegate

	func layoutManager(_ layoutManager: NSLayoutManager,
			shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
			lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
			baselineOffset: UnsafeMutablePointer<CGFloat>,
			in textContainer: NSTextContainer,
			forGlyphRange glyphRange: NSRange) -> Bool {
		baselineOffset.pointee = lineHeight * 0.808
		return true
	}

	// MARK: - Draw background

	override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
		guard let textStorage = textStorage as? TextStorage,
				let cgContext = UIGraphicsGetCurrentContext() else {
			fatalError()
		}

		super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

		enumerateLineFragments(forGlyphRange: glyphsToShow) {
			[unowned self, unowned textStorage] (_, usedRect, textContainer, glyphRange, _) in

			let charRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
			let paraRange = (textStorage.string as NSString).paragraphRange(for: charRange)

			if self.highlightLine && NSLocationInRange(self.selectedRange.location, paraRange) {
				self.drawSelectedLine(rect: usedRect, cgContext: cgContext)
			}

			if charRange.location == paraRange.location {
				let paragraphNumber = self.paragraphNumber(range: charRange, text: textStorage.string as NSString)
				self.drawLineNumber(origin: usedRect.origin, lineNumber: paragraphNumber + 1)
			}
		}

		if showInvisibles {
			drawInvisibleCharacters(range: glyphsToShow, textStorage: textStorage)
		}
	}

	private func paragraphNumber(range: NSRange, text: NSString) -> Int {
		if range.location == lastParaLocation {
			return lastParaNumber

		} else if range.location < lastParaLocation {
			let target = NSRange(location: range.location, length: lastParaLocation - range.location)
			var paraNumber = lastParaNumber
			text.enumerateSubstrings(in: target, options: [.byParagraphs, .substringNotRequired, .reverse]) {
				(_, _, enclosingRange, stop) in
				if enclosingRange.location <= range.location {
					stop.pointee = true
				}
				paraNumber -= 1
			}
			lastParaLocation = range.location
			lastParaNumber = paraNumber
			return paraNumber

		} else {
			let target = NSRange(location: lastParaLocation, length: range.location - lastParaLocation)
			var paraNumber = lastParaNumber
			text.enumerateSubstrings(in: target, options: [.byParagraphs, .substringNotRequired]) {
				(_, _, enclosingRange, stop) in
				if enclosingRange.location >= range.location {
					stop.pointee = true
				}
				paraNumber += 1
			}
			lastParaLocation = range.location
			lastParaNumber = paraNumber
			return paraNumber
		}
	}

	private func drawLineNumber(origin: CGPoint, lineNumber: Int) {
		let lineNumber = "\(lineNumber)"
		let size = lineNumber.size(withAttributes: lineNumberAttribute)
		let x = gutterWidth - size.width - 4.0
		let y = (lineHeight - size.height) / 2.0 + origin.y + verticalMargin
		let rect = CGRect(x: x, y: y, width: size.width, height: size.height)
		lineNumber.draw(in: rect, withAttributes: lineNumberAttribute)
	}

	private func drawSelectedLine(rect: CGRect, cgContext: CGContext) {
		// text
		let x = gutterWidth + 2.0
		let y = rect.origin.y + verticalMargin - 0.5
		let width = textAreaWidth - 4.0
		let height = rect.size.height + 1
		let rect = CGRect(x: x, y: y, width: width, height: height)
		cgContext.setFillColor(lineHighlightColor.cgColor)
		cgContext.fill(rect)
	}

	private func drawInvisibleCharacters(range: NSRange, textStorage: TextStorage) {
		invisibles.forEach() {
			(invisible) in
			invisible.value.enumerateMatches(in: textStorage.string, options: [], range: range) {
				[unowned self] (result, _, _) in
				guard let range = result?.range else {
					return
				}
				let index = NSMaxRange(range) - 1
				var glyphPoint = self.location(forGlyphAt: index)
				let glyphRect = self.lineFragmentRect(forGlyphAt: index, effectiveRange: nil)
				glyphPoint.x += glyphRect.origin.x + self.gutterWidth
//				glyphPoint.y = glyphRect.origin.y + (self.lineHeight * 0.797872340425532 / 2.0)
				glyphPoint.y = glyphRect.origin.y + (self.lineHeight * 0.404 / 2.0)
				invisible.key.draw(at: glyphPoint, withAttributes: self.invisiblesAttribute)
			}
		}
	}

	// MARK: - Setter

	func set(font: UIFont) {
		// Set line height
		self.lineHeight = font.lineHeight

		// Set invisibles font
		self.invisiblesAttribute[.font] = font

		// Set line number font
		let lineNumberSize = CGFloat(floor(font.pointSize * 0.9))
		self.lineNumberAttribute[.font] = font.withSize(lineNumberSize)
	}

	func set(backgroundColor: UIColor) {
		// Set selected line color
		self.lineHighlightColor = backgroundColor.brightness(0.7)

		// Set invisibles font color
		self.invisiblesAttribute[.foregroundColor] = backgroundColor.brightness(0.6)

		// Set line number color
		self.lineNumberAttribute[.foregroundColor] = backgroundColor.brightness(0.4)
	}

	func set(gutterWidth: CGFloat, verticalMargin: CGFloat) {
		self.gutterWidth = gutterWidth
		self.verticalMargin = verticalMargin
	}

	func set(textAreaWidth: CGFloat) {
		self.textAreaWidth = textAreaWidth
	}

}
