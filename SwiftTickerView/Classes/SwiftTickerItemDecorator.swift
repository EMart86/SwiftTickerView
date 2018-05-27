import UIKit

public struct SwiftTickerItemDecorators {
    /**
     InitialRenderer
     
     Aligns the items left to each other
     
     This is used in the rightToLeft Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    public static func alignItemsLeftToEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.x = last.frame.maxX + (customOffset ?? offset)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items right to each other
     
     This is used in the leftToRight Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    
    public static func alignItemsRightToEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.x = last.frame.minX - (customOffset ?? offset) - frame.width
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items below each other
     
     This is used in the bottomToTop Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    
    public static func alignItemsBelowEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.y = last.frame.maxY + (customOffset ?? offset)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items above each other
     
     This is used in the topToBottom Rendering option
     
     - Parameter customOffset: A custom offset to each item
     */
    
    public static func alignItemsAboveEachOther(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard let last = last else {
                    return
                }
                var frame = current.frame
                frame.origin.y = last.frame.minY - (customOffset ?? offset) - frame.height
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the right border so that it is not visible in the beginning
     
     This is used in the rightToLeft Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtRightOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = tickerView.frame.maxX + (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the right border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtRightInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = tickerView.frame.maxX - frame.width - (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the left border so that it is not visible in the beginning
     
     This is used in the leftToRight Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtLeftOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = -frame.width - (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the left border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtLeftInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = customOffset ?? offset
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the bottom border so that it is not visible in the beginning
     
     This is used in the bottomToTop Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtBottomOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = tickerView.frame.maxY + (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the left border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtBottomInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = tickerView.frame.height - frame.height - (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at the top border so that it is not visible in the beginning
     
     This is used in the topToBottom Rendering option
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtTopOuterBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = -frame.height + (customOffset ?? 0)
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the first item at top border so that it is visible in the beginning
     
     - Parameter customOffset: A custom offset to the border
     */
    public static func prepareAtTopInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.y = customOffset ?? 0
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
        }
        return Anonymous(customOffset: customOffset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items vertically centered in the view
     
     This is used in the leftToRight and rightToLeft Rendering option
     
     - Parameter customOffset: A custom offset from the vertical center
     */
    public static func centerVertical(with offset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.y = ((tickerView.frame.height - frame.height) / 2) + (offset ?? 0)
                current.frame = frame
            }
            
            init(offset: CGFloat? = nil) {
                self.offset = offset
            }
            
            let offset: CGFloat?
        }
        return Anonymous(offset: offset)
    }
    
    /**
     InitialRenderer
     
     Aligns the items horizontally centered in the view
     
     This is used in the topToBottom and bottomToTop Rendering option
     
     - Parameter customOffset: A custom offset from the horizontal center
     */
    public static func centerHorizontal(with offset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.x = ((tickerView.frame.width - frame.width) / 2) + (offset ?? 0)
                current.frame = frame
            }
            
            init(offset: CGFloat? = nil) {
                self.offset = offset
            }
            
            let offset: CGFloat?
        }
        return Anonymous(offset: offset)
    }
    
    /**
     UpdateRenderer
     
     Updates the x position of the view
     
     This is used in the leftToRight and rightToLeft Rendering option
     
     - Parameter function: Use an oparator eg (+, -, *, /,...)
     */
    public static func updateX(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) -> SwiftTickerItemDecorator & UpdateRenderer {
        struct Anonymous: SwiftTickerItemDecorator, UpdateRenderer {
            func updateWith(current: UIView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.x = function(frame.origin.x, offset)
                current.frame = frame
            }
            
            init(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) {
                self.function = function
            }
            
            let function: (CGFloat, CGFloat) -> CGFloat
        }
        return Anonymous(function)
    }
    
    /**
     UpdateRenderer
     
     Updates the y position of the view
     
     This is used in the topToBottom and bottomToTop Rendering option
     
     - Parameter function: Use an oparator eg (+, -, *, /,...)
     */
    public static func updateY(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) -> SwiftTickerItemDecorator & UpdateRenderer {
        struct Anonymous: SwiftTickerItemDecorator, UpdateRenderer {
            func updateWith(current: UIView, offset: CGFloat) {
                var frame = current.frame
                frame.origin.y = function(frame.origin.y, offset)
                current.frame = frame
            }
            
            init(_ function: @escaping (CGFloat, CGFloat) -> CGFloat) {
                self.function = function
            }
            
            let function: (CGFloat, CGFloat) -> CGFloat
        }
        return Anonymous(function)
    }
}
