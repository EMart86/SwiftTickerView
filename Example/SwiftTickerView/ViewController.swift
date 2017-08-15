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
    
    @IBOutlet weak var tickerView: SwiftTickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tickerView.provider = TickerProvider()
        tickerView.separator = "+++"
        tickerView.direction = .horizontalRightToLeft
        tickerView.tickerDelegate = self
        tickerView.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: SwiftTickerDelegate {
    func tickerView(willResume ticker: SwiftTickerView) {}
    func tickerView(willStart ticker: SwiftTickerView) {}
    func tickerView(willStop ticker: SwiftTickerView) {}
    
    func tickerView(_ tickerView: SwiftTickerView, viewFor: Any) -> UIView {
        var frame = tickerView.frame
        frame.size.width = 50
        frame.size.height -= 16
        
        let view = UIView(frame: frame)
        view.backgroundColor = .blue
        return view
    }
}
