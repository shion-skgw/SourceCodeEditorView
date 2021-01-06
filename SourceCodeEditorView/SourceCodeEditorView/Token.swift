//
//  Token.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

struct Token {
    let regex: NSRegularExpression
    let isMultipleLines: Bool
    let textAttribute: [NSAttributedString.Key: Any]

    init(type: TokenType, pattern: String, isMultipleLines: Bool = false) {
        self.regex = try! NSRegularExpression(pattern: pattern)
        self.isMultipleLines = isMultipleLines
        self.textAttribute = [.foregroundColor: type.color]
    }
}

enum TokenType {
    case keyword
    case comment
    case function

    var color: UIColor {
        switch self {
        case .keyword:
            return UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0)
        case .comment:
            return UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        case .function:
            return UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
        }
    }
}

