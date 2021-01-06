//
//  SourceCodeView.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/10.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

final class SourceCodeView: UITextView {

    var gutterColor: CGColor = UIColor.white.cgColor
    var gutterEdgeColor: CGColor = UIColor.white.cgColor
    var lineHighlight: Bool = false
    var lineHighlightColor: CGColor = UIColor.white.cgColor
    var lineNumberAttribute: [NSAttributedString.Key: Any] = [:]

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.autocapitalizationType = .none
        self.autocorrectionType = .no
        self.contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

}


// MARK: - Draw

extension SourceCodeView {

    override func draw(_ rect: CGRect) {
        let cgContext = UIGraphicsGetCurrentContext()!
        drawGutter(cgContext)
        drawLineNumber()
        if lineHighlight {
            drawLineHighlight(cgContext)
        }
        super.draw(rect)
    }

    private func drawGutter(_ cgContext: CGContext) {
        let height = max(bounds.height, contentSize.height)

        let gutterRect = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: textContainerInset.left, height: height)
        cgContext.setFillColor(gutterColor)
        cgContext.fill(gutterRect)

        let gutterEdgeRect = CGRect(x: textContainerInset.left, y: bounds.origin.y - 0.5, width: 0.5, height: height)
        cgContext.setFillColor(gutterEdgeColor)
        cgContext.fill(gutterEdgeRect)
    }

    private func drawLineNumber() {
        let nsString = text as NSString

        var lineNumber = 1
        var currentLineRange = nsString.lineRange(for: NSMakeRange(0, 0))
        var currentLineRect = boundingRect(currentLineRange)

        while true {
            drawLineNumber(lineNumber, currentLineRect)
            if text.range.upperBound <= currentLineRange.upperBound {
                break
            }
            lineNumber += 1
            currentLineRange = nsString.lineRange(for: NSMakeRange(currentLineRange.upperBound, 0))
            currentLineRect = boundingRect(currentLineRange)
        }

        if text.hasSuffix("\n") {
            currentLineRect.origin.y += currentLineRect.size.height
            drawLineNumber(lineNumber + 1, currentLineRect)
        }
    }

    private func drawLineNumber(_ lineNumber: Int, _ usedRect: CGRect) {
        let number = NSAttributedString(string: "\(lineNumber)", attributes: lineNumberAttribute)
        let size = number.size()
        let x = textContainerInset.left - size.width - 4.0
        let y = textContainerInset.top + usedRect.origin.y + (font!.lineHeight - size.height) / 2.0
        number.draw(at: CGPoint(x: x, y: y))
    }

    private func drawLineHighlight(_ cgContext: CGContext) {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        var lineRect = boundingRect(lineRange)
        lineRect.origin.x = textContainerInset.left + 2.0
        lineRect.origin.y += textContainerInset.top - 1.0
        lineRect.size.width = textContainer.size.width - 4.0
        lineRect.size.height += 2.0
        cgContext.setFillColor(lineHighlightColor)
        cgContext.fill(lineRect)
    }

    private func boundingRect(_ range: NSRange) -> CGRect {
        var rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)

        // X, height adjustment of line break-only lines.
        rect.origin.x = textContainer.lineFragmentPadding
        if rect.size.width == textContainer.size.width - textContainer.lineFragmentPadding {
            rect.size.height -= font!.lineHeight
        }
        return rect
    }

}
