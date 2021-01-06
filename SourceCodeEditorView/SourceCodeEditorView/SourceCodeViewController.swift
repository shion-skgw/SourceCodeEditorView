//
//  SourceCodeViewController.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2021/01/06.
//  Copyright © 2021 Shion. All rights reserved.
//

import UIKit

final class SourceCodeViewController: UIViewController {

    /* Font definition */
    let font = UIFont.monospacedSystemFont(ofSize: 16.0, weight: .medium)
    let fontColor = UIColor.darkText
    let invisiblesFontColor = UIColor.gray

    /* Background definition */
    let backgroundColor = UIColor.secondarySystemBackground
    let lineHighlightColor = UIColor.lightGray

    /* Gutter definition */
    let gutterWidth = CGFloat(40.0)
    let gutterColor = UIColor.tertiarySystemBackground
    let gutterEdgeColor = UIColor.gray
    let lineNumberColor = UIColor.lightGray

    /* Other */
    let verticalMargin = CGFloat(4.0)

    override func loadView() {
        /* TextContainer */
        let textContainer = NSTextContainer()

        /* LayoutManager */
        let layoutManager = LayoutManager()
        layoutManager.lineHeight = font.lineHeight
        layoutManager.showInvisibles = true
        layoutManager.gutterWidth = gutterWidth
        layoutManager.verticalMargin = verticalMargin
        layoutManager.invisiblesAttribute = [
            .font: font,
            .foregroundColor: invisiblesFontColor
        ]
        layoutManager.addTextContainer(textContainer)

        /* TextStorage */
        let textStorage = TextStorage()
        textStorage.tokens = [
            Token(type: .keyword, pattern: "return"),
            Token(type: .keyword, pattern: "func"),
            Token(type: .function, pattern: "String"),
            Token(type: .comment, pattern: "//.*"),
            Token(type: .comment, pattern: "/\\*[\\s\\S]*?\\*/", isMultipleLines: true),
        ]
        textStorage.textAttribute = [
            .font: font,
            .foregroundColor: fontColor
        ]
        textStorage.addLayoutManager(layoutManager)

        /* SourceCodeView */
        let sourceCodeView = SourceCodeView(frame: .zero, textContainer: textContainer)

        // UITextView param
        sourceCodeView.font = font
        sourceCodeView.textColor = fontColor
        sourceCodeView.backgroundColor = backgroundColor
        sourceCodeView.textContainerInset.top = verticalMargin
        sourceCodeView.textContainerInset.bottom = verticalMargin
        sourceCodeView.textContainerInset.left = gutterWidth

        // SourceCodeView param
        sourceCodeView.gutterColor = gutterColor.cgColor
        sourceCodeView.gutterEdgeColor = gutterEdgeColor.cgColor
        sourceCodeView.lineHighlight = true
        sourceCodeView.lineHighlightColor = lineHighlightColor.cgColor
        sourceCodeView.lineNumberAttribute = [
            .font: UIFont(name: font.fontName, size: font.pointSize * 0.8)!,
            .foregroundColor: lineNumberColor
        ]
        self.view = sourceCodeView
    }

}
