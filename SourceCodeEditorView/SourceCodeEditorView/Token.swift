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

	init(name: String, type: TokenType, pattern: String) {
		self.name = name
		self.type = type
		self.regex = try! NSRegularExpression(pattern: pattern)
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
			return UIColor.green
		case .function:
			return UIColor.blue
		}
	}
}

