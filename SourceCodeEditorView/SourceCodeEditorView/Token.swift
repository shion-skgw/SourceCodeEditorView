//
//  Token.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

struct Token {
	let name: String
	let type: TokenType
	let regex: NSRegularExpression
	let isMultipleLines: Bool

	init(name: String, type: TokenType, pattern: String, isMultipleLines: Bool = false) {
		self.name = name
		self.type = type
		self.regex = try! NSRegularExpression(pattern: pattern)
		self.isMultipleLines = isMultipleLines
	}
}

enum TokenType {
	case keyword
	case comment
	case function

	var color: UIColor {
		switch self {
		case .keyword:
			return UIColor.purple
		case .comment:
			return UIColor.green.brightness(0.5)
		case .function:
			return UIColor.blue.brightness(0.7)
		}
	}
}

