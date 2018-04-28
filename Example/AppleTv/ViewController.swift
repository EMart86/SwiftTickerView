//
//  ViewController.swift
//  SwiftTickerView
//
//  Created by eberl_ma@gmx.at on 08/15/2017.
//  Copyright (c) 2017 eberl_ma@gmx.at. All rights reserved.
//

import UIKit
import SwiftTickerView

class ViewController: UIViewController {
    fileprivate let labelIdentifier = "TextMessage"
    @IBOutlet weak var tickerView: SwiftTickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tickerView.contentProvider = TickerProvider()
        tickerView.viewProvider = self
        tickerView.separator = "+++"
        tickerView.registerNodeView(UILabel.self, for: labelIdentifier)
        tickerView.direction = .horizontalRightToLeft
        tickerView.tickerDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tickerView.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tickerView.stop()
    }
}

extension ViewController: SwiftTickerDelegate {
    func tickerView(willResume ticker: SwiftTickerView) {}
    func tickerView(willStart ticker: SwiftTickerView) {}
    func tickerView(willStop ticker: SwiftTickerView) {}
    func tickerView(didPress view: UIView, content: Any?) {}
}

extension ViewController: SwiftTickerViewProvider {
    func tickerView(_ tickerView: SwiftTickerView, prepareSeparator separator: UIView) {
        if let separator = separator as? UILabel {
            separator.textColor = .white
        }
    }

    func tickerView(_ tickerView: SwiftTickerView, viewFor: Any) -> (UIView, reuseIdentifier: String?) {
        if let text = viewFor as? String,
            let label = tickerView.dequeReusableNodeView(for: labelIdentifier) as? UILabel {
            label.text = text
            label.sizeToFit()
            label.textColor = .white
            return (label, reuseIdentifier: labelIdentifier)
        }
        return (UIView(), reuseIdentifier: nil)
    }
}
