import UIKit

public protocol SwiftTickerItemDecorator { }

public struct SwiftTickerItemDecorators {
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
    
    public static func prepareAtLeftInnerBorder(with customOffset: CGFloat? = nil) -> SwiftTickerItemDecorator & InitialRenderer {
        struct Anonymous: SwiftTickerItemDecorator, InitialRenderer {
            func updateWith(current: UIView, last: UIView?, tickerView: SwiftTickerView, offset: CGFloat) {
                guard last == nil else {
                    return
                }
                var frame = current.frame
                frame.origin.x = customOffset ?? 0
                current.frame = frame
            }
            
            init(customOffset: CGFloat? = nil) {
                self.customOffset = customOffset
            }
            
            let customOffset: CGFloat?
            
        }
        return Anonymous(customOffset: customOffset)
    }
    
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
