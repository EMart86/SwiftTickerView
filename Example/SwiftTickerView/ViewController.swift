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
    private let tickerContentProvider = TickerProvider()
    @IBOutlet weak var tickerView: SwiftTickerView!

    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        setupTickerView(tickerView, dataSet: ["A", "B", "C"])
        
        tickerView.contentProvider = tickerContentProvider
        tickerView.viewProvider = self
        tickerView.separator = "+++"
        tickerView.render = Renderer.leftToRight
        tickerView.render = Renderer.bottomToTopStopAtCenter(holdForSeconds: -1)
//        tickerView.render = Renderer(initials: [SwiftTickerItemDecorators.prepareAtLeftInnerBorder(),
//                                                SwiftTickerItemDecorators.alignItemsAboveEachOther(),
//                                                SwiftTickerItemDecorators.centerVertical()],
//                                     updates: [SwiftTickerItemDecorators.updateY(+)],
//                                     shouldAddNewNode: { current, _, offset in
//                                        current.frame.minY > offset
//        }, shouldRemoveNode: { current, tickerView in
//            current.frame.minY > tickerView.frame.maxY
//        })
//        tickerView.render = Renderer.bottomToTop.customize(with: SwiftTickerItemDecorators.prepareAtLeftInnerBorder())*/
//        tickerView.add(decorator: .ignoreFirstSeparator)
        tickerView.registerNodeView(UILabel.self, for: labelIdentifier)
        tickerView.tickerDelegate = self
        tickerView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tickerView.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tickerView.stop()
    }

    @IBAction func onValueChange(_ sender: Any) {
        tickerView.pixelPerSecond = CGFloat(slider.value)
    }
    
    @IBAction func onButtonClicked() {
        tickerContentProvider.updateContent()
    }
    
    @IBAction func updateContentAndReload(_ sender: Any) {
        tickerContentProvider.updateContent()
        tickerView.reloadData()
    }
    
    func setupTickerView(_ tickerView: SwiftTickerView, dataSet: [String]) {
        tickerView.contentProvider = tickerContentProvider
        tickerView.viewProvider = self
        tickerView.separator = "..."
        tickerView.add(decorator: .ignoreFirstSeparator)
        tickerView.distanceBetweenNodes = 10
        tickerView.render = Renderer.rightToLeft
        tickerView.registerNodeView(UILabel.self, for: labelIdentifier)
        tickerView.tickerDelegate = self
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
