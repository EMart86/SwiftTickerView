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
    
    private var initials: [InitialRenderer & SwiftTickerItemDecorator]
    private var updates: [UpdateRenderer & SwiftTickerItemDecorator]
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
                shouldAddNewNode: @escaping ShouldAddNewNode,
                shouldRemoveNode: @escaping ShouldRemoveNode) {
        self.initials = initials
        self.updates = updates
        self.shouldAddNewNode = shouldAddNewNode
        self.shouldRemoveNode = shouldRemoveNode
    }

    open func tickerViewUpdate(_ tickerView: SwiftTickerView, render nodeView: UIView, offset: CGFloat) {
        updates.forEach { $0.updateWith(current: nodeView, offset: offset) }
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
