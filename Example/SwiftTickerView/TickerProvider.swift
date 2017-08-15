//
//  TickerProvider.swift
//  SwiftTickerView
//
//  Created by Martin Eberl on 15.08.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import SwiftTickerView

final class TickerProvider: SwiftTickerProviderProtocol {
    private var content = ["A", "B", "C"]
    private var index = 0
    
    
    var hasContent = true
    var next: Any {
        if index >= self.content.count {
            index = 0
        }
        let next = self.content[index]
        index += 1
        return next
    }
}
