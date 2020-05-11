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

private let INVISIBLES: [String: NSRegularExpression] = [
	"\u{21B5}": try! NSRegularExpression(pattern: "[\r\n]", options: []),
	"\u{226B}": try! NSRegularExpression(pattern: "\t", options: []),
	"\u{22C5}": try! NSRegularExpression(pattern: "\u{0020}", options: []),
	"\u{25A1}": try! NSRegularExpression(pattern: "\u{3000}", options: []),
]

final class LayoutManager: NSLayoutManager {

	var showInvisibles: Bool

	private var gutterWidth: CGFloat
	private var verticalMargin: CGFloat
	private var lineHeight: CGFloat
	private var invisiblesAttribute: [NSAttributedString.Key: Any]

	// MARK: - Initialize

	override init() {
		self.showInvisibles = true
		self.gutterWidth = 40.0
		self.verticalMargin = 4.0
		self.lineHeight = UIFont.systemFont.lineHeight
		self.invisiblesAttribute = [NSAttributedString.Key: Any]()
		super.init()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Draw background

	override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
		super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
		if showInvisibles {
			drawInvisibleCharacters(range: glyphsToShow)
		}
	}

	private func drawInvisibleCharacters(range: NSRange) {
		guard let text = textStorage?.string else {
			return
		}

		for invisible in INVISIBLES {
			let charSize = invisible.key.size(withAttributes: invisiblesAttribute)

			invisible.value.enumerateMatches(in: text, options: [], range: range) {
				[unowned self, invisible, charSize] (result, _, _) in
				guard let range = result?.range else {
					return
				}

				let index = NSMaxRange(range) - 1
				let rect = lineFragmentRect(forGlyphAt: index, effectiveRange: nil)
				var point = location(forGlyphAt: index)
				point.x += rect.origin.x + self.gutterWidth
				point.y = rect.origin.y + self.verticalMargin + (self.lineHeight / 2.0 - charSize.height / 2.0)
				invisible.key.draw(at: point, withAttributes: self.invisiblesAttribute)
			}
		}
	}

	// MARK: - Setter

	func set(font: UIFont) {
		self.lineHeight = font.lineHeight
		self.invisiblesAttribute[.font] = font
	}

	func set(backgroundColor: UIColor) {
		self.invisiblesAttribute[.foregroundColor] = backgroundColor.brightness(0.5)
	}

	func set(gutterWidth: CGFloat, verticalMargin: CGFloat) {
		self.gutterWidth = gutterWidth
		self.verticalMargin = verticalMargin
	}

}
