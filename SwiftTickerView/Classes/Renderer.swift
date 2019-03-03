import UIKit

open class Renderer: SwiftTickerContentRenderer {
    public typealias ShouldAddNewNode = ((UIView, SwiftTickerView, CGFloat) -> Bool)
    public typealias ShouldRemoveNode = ((UIView, SwiftTickerView) -> Bool)
    
    /**
     Add inital render decorator for customizing the initial position of the node content
     
     - Parameter initial: Must conform to the InitialRenderer and SwiftTickerItemDecorator protocol
     */
    open func customize(with initial: SwiftTickerItemDecorator & InitialRenderer) -> Renderer {
        initials.append(initial)
        return self
    }
    
    /**
     Add update render decorator for customizing the updated position of the node content
     
     - Parameter update: Must conform to the UpdateRenderer and SwiftTickerItemDecorator protocol
     */
    open func customize(with update: SwiftTickerItemDecorator & UpdateRenderer) -> Renderer {
        updates.append(update)
        return self
    }
    
    /**
     Add condition decorator for customizing the condition to do something at a certain point
     
     - Parameter condition: A tuple with the first iteme being a closure that indicates the condition and a second item beind a closure that indicates the action
     */
    open func customize(with condition: (condition: Condition, then: Action)) -> Renderer {
        when = when ?? []
        when?.append(condition)
        return self
    }
    
    /**
     Renders the content from right to left and centered vertically in the ticker view, starting at the right border.
     */
    public static var rightToLeft = Renderer(initials: [SwiftTickerItemDecorators.alignItemsLeftToEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtRightOuterBorder(),
                                                        SwiftTickerItemDecorators.centerVertical()],
                                             updates: [SwiftTickerItemDecorators.updateX(-)],
                                             shouldAddNewNode: { current, tickerView, offset in
                                                if current.frame.maxX == -CGFloat.infinity {
                                                    return false
                                                }
                                                return tickerView.frame.width - current.frame.maxX > offset
    }, shouldRemoveNode: { current, _ in
        current.frame.maxX < 0
    })
    
    /**
     Renders the content from left to right and centered vertically in the ticker view, starting at the left border.
     */
    public static var leftToRight = Renderer(initials: [SwiftTickerItemDecorators.alignItemsRightToEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtLeftOuterBorder(),
                                                        SwiftTickerItemDecorators.centerVertical()],
                                             updates: [SwiftTickerItemDecorators.updateX(+)],
                                             shouldAddNewNode: { current, _, offset in
                                                current.frame.minX > offset
    }, shouldRemoveNode: { current, tickerView in
        current.frame.minX > tickerView.frame.maxX
    })
    
    /**
     Renders the content bottom to top and centered horizontally in the ticker view, starting at the bottom border.
     */
    public static var bottomToTop = Renderer(initials: [SwiftTickerItemDecorators.alignItemsBelowEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtBottomOuterBorder(),
                                                        SwiftTickerItemDecorators.centerHorizontal()],
                                             updates: [SwiftTickerItemDecorators.updateY(-)],
                                             shouldAddNewNode: { current, tickerView, offset in
                                                tickerView.frame.height - current.frame.maxY > offset
    }, shouldRemoveNode: { current, _ in
        current.frame.maxY < 0
    })
    
    /**
     Renders the content top to bottom and centered horizontally in the ticker view, starting at the top border.
     */
    public static var topToBottom = Renderer(initials: [SwiftTickerItemDecorators.centerHorizontal(),
                                                        SwiftTickerItemDecorators.alignItemsAboveEachOther(),
                                                        SwiftTickerItemDecorators.prepareAtTopOuterBorder()],
                                             updates: [SwiftTickerItemDecorators.updateY(+)],
                                             shouldAddNewNode: { current, _, offset in
                                                current.frame.minY > offset
    }, shouldRemoveNode: { current, tickerView in
        current.frame.minY > tickerView.frame.maxY
    })
    
    private class CustomTimer {
        private var block: ((Timer) -> Void)? = nil
        private weak var timer: Timer?
        
        func schedule(with interval: TimeInterval, repeats: Bool, block: @escaping ((Timer) -> Void)) {
            if #available(iOS 10.0, tvOS 10.0, *) {
                Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
            } else {
                self.block = block
                timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: repeats)
            }
        }
        
        @objc private func timerFired(_ sender: Any) {
            guard let timer = timer else {
                return
            }
            block?(timer)
        }
    }
    
    /**
     Renders the content bottom to top with the first item startin out of the bounds and moving each item up.
     When the current item reaches the center, it stops for given ammounts of seconds. Thereafter it continues.
     This behaviour is ment to be used on modern news tickers
     
     - Parameter holdForSeconds: use this option to let the user see the ticker node when centered in the view for ammount of seconds. Value has to be positive
     */
    public static func bottomToTopStopAtCenter(holdForSeconds seconds: TimeInterval) -> Renderer {
        return Renderer(initials: [SwiftTickerItemDecorators.prepareAtBottomOuterBorder(force: true),
                                   SwiftTickerItemDecorators.prepareAtLeftInnerBorder()],
                        updates: [SwiftTickerItemDecorators.updateY(-)],
                        when: [(
                            condition: DefaultConditionBehaviour(condition: { node, tickerView, behaviour in
                                func isInVerticalCenter(node: UIView, tickerView: SwiftTickerView, allowedOffset: CGFloat = 5) -> Bool {
                                    let tickerCenter = tickerView.bounds.midY
                                    let nodeCenter = node.frame.minY + node.frame.height / 2
                                    return abs(tickerCenter - nodeCenter) < 5
                                }
                                
                                guard behaviour.nodeView != node else {
                                    if !isInVerticalCenter(node: node, tickerView: tickerView) {
                                        behaviour.nodeView = nil
                                    }
                                    return false
                                }
                                if isInVerticalCenter(node: node, tickerView: tickerView) {
                                    behaviour.nodeView = node
                                    return true
                                }
                                behaviour.nodeView = nil
                                return false
                            }),
                            then: { _, tickerView in
                                tickerView.stop()
                                CustomTimer().schedule(with: max(0, seconds), repeats: false, block: { _ in
                                    tickerView.start()
                                })
                                return .return
                            }
                            )],
                        shouldAddNewNode: { current, _, _ in
                            current.frame.maxY < 0
        }, shouldRemoveNode: { current, tickerView in
            current.frame.maxY < 0
        })
    }
    
    private var initials: [InitialRenderer & SwiftTickerItemDecorator]
    private var updates: [UpdateRenderer & SwiftTickerItemDecorator]
    private var when: [(condition: Condition, then: Action)]?
    private let shouldAddNewNode: ShouldAddNewNode
    private let shouldRemoveNode: ShouldRemoveNode
    private var last: UIView?
    
    /**
     Renderer constructor
     
     - Parameter initials: An array of InitialRenderer and SwiftTickerItemDecorator for defining the start position of each ticker node view
     - Parameter updates: An array of UpdateRenderer and SwiftTickerItemDecorator for defining the updated position of each ticker node view
     - Parameter shouldAddNewNode: Closure if a new node view should be added
     - Parameter shouldRemoveNode: Closure if a given new node view should be removed
     */
    public init(initials: [InitialRenderer & SwiftTickerItemDecorator],
                updates: [UpdateRenderer & SwiftTickerItemDecorator],
                when: [(condition: Condition, then: Action)]? = nil,
                shouldAddNewNode: @escaping ShouldAddNewNode,
                shouldRemoveNode: @escaping ShouldRemoveNode) {
        self.initials = initials
        self.updates = updates
        self.when = when
        self.shouldAddNewNode = shouldAddNewNode
        self.shouldRemoveNode = shouldRemoveNode
    }
    
    open func tickerViewUpdate(_ tickerView: SwiftTickerView, render nodeView: UIView, offset: CGFloat) {
        updates.forEach { $0.updateWith(current: nodeView, offset: offset) }
        guard let when = when else {
            return
        }
        for whenCondition in when {
            if whenCondition.condition.meets(nodeView: nodeView, tickerView: tickerView) {
                switch whenCondition.then(self, tickerView) {
                case .return:
                    return
                case .break:
                    break
                case .continue:
                    continue
                }
            }
        }
    }
    
    open func tickerViewShouldAddNext(_ tickerView: SwiftTickerView, current nodeView: UIView) -> Bool {
        return shouldAddNewNode(nodeView, tickerView, tickerView.distanceBetweenNodes)
    }
    
    open func tickerViewShouldRemove(_ tickerView: SwiftTickerView, nodeView: UIView) -> Bool {
        return shouldRemoveNode(nodeView, tickerView)
    }
    
    open func tickerView(_ tickerView: SwiftTickerView, render nodeView: UIView, with identifier: String) {
        initials.forEach {
            $0.updateWith(current: nodeView,
                          last: last?.superview != nil ? last : nil,
                          tickerView: tickerView,
                          offset: tickerView.distanceBetweenNodes) }
        last = nodeView
    }
}
