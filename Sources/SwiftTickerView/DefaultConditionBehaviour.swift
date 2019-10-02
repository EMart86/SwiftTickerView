//
//  Default.swift
//  SwiftTickerView-iOS
//
//  Created by Martin Eberl on 02.03.19.
//

import UIKit

public class DefaultConditionBehaviour: Condition {
    weak var nodeView: UIView?
    var condition: ((UIView, SwiftTickerView, DefaultConditionBehaviour) -> Bool)
    
    init(condition: @escaping ((UIView, SwiftTickerView, DefaultConditionBehaviour) -> Bool)) {
        self.condition = condition
    }
    
    public func meets(nodeView: UIView, tickerView: SwiftTickerView) -> Bool {
        return condition(nodeView, tickerView, self)
    }
}
