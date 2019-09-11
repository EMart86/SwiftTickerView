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
    private let superContent = [["A", "B", "C"],
                           ["D", "E", "F"],
                           ["G", "H", "I"],
                           ["J", "K", "L"],
                           ["M", "N", "O"],
                           ["P", "Q", "R"],
                           ["S", "T", "U"],
                           ["V", "W", "X"],
                           ["Y", "Z"]]
    private var content: [String]
    private var contentIndex = 0
    private var index = 0
    
    init() {
        content = superContent[contentIndex]
    }
    
    var hasContent = true
    var nextObject: Any {
        if index >= content.count {
            index = 0
        }
        let next = content[index]
        index += 1
        return next
    }
    
    func updateContent() {
        if !superContent.indices.contains(contentIndex) {
            index = 0
            contentIndex = 0
        }
        let next = superContent[contentIndex]
        contentIndex += 1
        index = 0
        content = next
    }
}
