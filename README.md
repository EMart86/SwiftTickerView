# SwiftTickerView

[![CI Status](http://img.shields.io/travis/EMart86/SwiftTickerView.svg?style=flat)](https://travis-ci.org/EMart86/SwiftTickerView)
[![Version](https://img.shields.io/cocoapods/v/SwiftTickerView.svg?style=flat)](http://cocoapods.org/pods/SwiftTickerView)
[![License](https://img.shields.io/cocoapods/l/SwiftTickerView.svg?style=flat)](http://cocoapods.org/pods/SwiftTickerView)
[![Platform](https://img.shields.io/cocoapods/p/SwiftTickerView.svg?style=flat)](http://cocoapods.org/pods/SwiftTickerView)

![Animation](https://thumbs.gfycat.com/NextFabulousEarthworm-size_restricted.gif)
I'll definately have to update this gif, it doesn't look that crappy anymore!

## 1.5.0

### Following new Render decorators are vailable:
*  ```initialRenderer(closure: (UIView, UIView?, SwiftTickerView, CGFloat) -> Void)```
positon your node view wherever you want them to be placed
*  ```updateRenderer(closure: (UIView, CGFloat) -> Void)``` 
use this to customize your rendering option for e.g. to fade in the items or fade out
*  ```bottomToTopStopAtCenter(holdForSeconds seconds: TimeInterval)``` 
this can be used to create the mostly in TV used Ticker where the Ticker node appears at the bottom, when reaching center stayes there for some time and continues to the top

## 1.4.3

- Add support for iOS 9

## 1.4.2

### Fixes
- Fixes ignoreSeparator on startup when calling reloadData #5

## 1.4.1

### Fixes
- Fix center vertical and horizontal

## 1.4.0

###  Customize the Renderer easily by adding a new decorators:
    ```Renderer.topToBottom.customize(with: SwiftTickerItemDecorators.prepareAtBottomInnerBorder(with: 8))```
    
### Following new Render decorators are vailable:
    *  ```prepareAtTopInnerBorder()```
    *  ```prepareAtTopOuterBorder()```
    *  ```prepareAtBottomInnerBorder()```
    *  ```prepareAtBottomOuterBorder()```
    *  ```prepareAtLeftInnerBorder()```
    *  ```prepareAtLeftOuterBorder()```
    *  ```prepareAtRightInnerBorder()```
    *  ```prepareAtRightOuterBorder()```
    
### Implement your own inital or update Render decorator by implementing the ```InitialRenderer & SwiftTickerItemDecorator``` or ```UpdateRenderer & SwiftTickerItemDecorator```

### Following new Ticker decorator is available:
*  ```ignoreFirstSeparator```
Add a decorator to the TickerView by calling  ```tickerView.add(.ignoreFirstSeparator)```

### Renamings
* ```SwiftTickerView.Renderer.rightToLeft``` renamed to ```Renderer.rightToLeft```
* ```SwiftTickerView.Renderer.leftToRight``` renamed to ```Renderer.leftToRight```
* ```SwiftTickerView.Renderer.topToBottom``` renamed to ```Renderer.topToBottom```
* ```SwiftTickerView.Renderer.bottomToTop``` renamed to ```Renderer.bottomToTop```

## 1.3.0

* You can now implement your own renderer

### Renamings
* renamed ```direction``` to ```renderer```
* ```Direction.horizontalRightToLeft``` renamed to ```SwiftTickerView.Renderer.rightToLeft```
* ```Direction.horizontalLeftToRight``` renamed to ```SwiftTickerView.Renderer.leftToRight```
* ```Direction.verticalTopToBottom``` renamed to ```SwiftTickerView.Renderer.topToBottom```
* ```Direction.verticalBottomToTop``` renamed to ```SwiftTickerView.Renderer.bottomToTop```

## 1.2.2

* Now supports TV OS
* Performance improvements

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

SwiftTickerView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftTickerView'
```

## Setup

You can eigther embed the SwiftTickerView within an Storyboard or a Xib View, or instantiate the View just like any other view:

```swift
let tickerView = SwiftTickerView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
```

Use the separator property to simply create those textual separators or set a separator view class or nib to create those separator views. Also implement the viewProvider protocol to manipulate the separator view and the node view on demand
```swift
tickerView.separator = "+++"
tickerView.viewProvider = self
...
```

Register also some custom node views to be able to load them more easily
```swift
tickerView.registerNodeView(UILabel.self, for: labelIdentifier)
```

If you want some callbacks on if the user stopped the ticker view (yes, the user can stop the view by tapping on the ticker view), implement the tickerDelegate and don't forget to asign it to the ticker view. You will also be able to determine the content, which the user has selected.
```swift
tickerView.tickerDelegate = self
```

This ticker view is designed to be able to support arabic and hebrew aswell as the other languages. Simply use the direction property, to determine if you want the content to run from left to right, from right to left, from top to bottom or from bottom to top:
```swift
tickerView.renderer = SwiftTickerView.Renderer.rightToLeft
```

You can manage the velocity of the content to run across the display. You can alter this value at runtime aswell to increase or slow down the ticker view:
```swift
tickerView.pixelPerSecond = 60 //default is 60
```

Don't forget to start the tickerview, otherwhise it's not working:
```swift
tickerView.start() 
```

And last but not least, implement the contentProvider property to provide your content!

Btw, in the viewProvider protocol, the view node view creation function has to return a tuple with a view parameter and an optional reuseIdentifier parameter. Use this parameter to store it and reuse it for later usage:
```swift
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

func tickerView(_ tickerView: SwiftTickerView, prepareSeparator separator: UIView) {
    if let separator = separator as? UILabel {
        separator.textColor = .white
    }
}
```

## Author

Martin Eberl, eberl_ma@gmx.at

## License

SwiftTickerView is available under the MIT license. See the LICENSE file for more info.
