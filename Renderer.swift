import Foundation

extension SwiftTickerView.Renderer {
    public static func bottomToTop(waiting: TimeInterval) -> Renderer {
        
    }
    open class BottomToTopWaitingRenderer: Renderer {
        private let timeInterval: TimeInterval
        
        init(timeInterval: TimeInterval) {
            self.timeInterval = timeInterval
            super(initial: { current, last, tickerView, offset in
            var frame = current.frame
            if let last = last {
            frame.origin.y = last.frame.maxY + offset
            } else {
            frame.origin.y = tickerView.frame.maxY
            }
            frame.origin.x = (tickerView.frame.width - frame.width) / 2
            return frame
            }, update: { current, offset in
            var frame = current.frame
            frame.origin.y -= offset
            if 
            return frame
            }, shouldAddNewNode: { current, tickerView, offset in
            tickerView.frame.height - current.frame.maxY > offset
            }, shouldRemoveNode: { current, _ in
            current.frame.maxY < 0
            })
        }
    }
}
