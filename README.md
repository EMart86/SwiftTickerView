# SwiftTickerView

[![CI Status](http://img.shields.io/travis/eberl_ma@gmx.at/SwiftTickerView.svg?style=flat)](https://travis-ci.org/eberl_ma@gmx.at/SwiftTickerView)
[![Version](https://img.shields.io/cocoapods/v/SwiftTickerView.svg?style=flat)](http://cocoapods.org/pods/SwiftTickerView)
[![License](https://img.shields.io/cocoapods/l/SwiftTickerView.svg?style=flat)](http://cocoapods.org/pods/SwiftTickerView)
[![Platform](https://img.shields.io/cocoapods/p/SwiftTickerView.svg?style=flat)](http://cocoapods.org/pods/SwiftTickerView)

![Animation](https://thumbs.gfycat.com/NextFabulousEarthworm-size_restricted.gif)

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
tickerView.direction = .horizontalRightToLeft
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


## tvOS

The pod is also tested on the lastest Apples TV OS 11

## Author

Martin Eberl, eberl_ma@gmx.at

## License

SwiftTickerView is available under the MIT license. See the LICENSE file for more info.
