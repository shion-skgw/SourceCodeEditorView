//
//  ViewController.swift
//  SourceCodeEditorView
//
//  Created by Shion on 2020/05/09.
//  Copyright © 2020 Shion. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private(set) weak var sourceCodeViewController: SourceCodeViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        let sourceCodeViewController = SourceCodeViewController()
        addChild(sourceCodeViewController)
        view.addSubview(sourceCodeViewController.view)
        sourceCodeViewController.didMove(toParent: self)
        self.sourceCodeViewController = sourceCodeViewController
    }

    override func viewDidLayoutSubviews() {
        sourceCodeViewController.view.frame = view.safeAreaLayoutGuide.layoutFrame
    }

}
