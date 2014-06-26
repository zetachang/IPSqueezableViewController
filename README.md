# IPSqueezableViewController 

**Condensing effect of navigation bar as the one in Safari.app**

Though iOS 8 introduce the `condensesBarsOnSwipe` property. It's still not the same as the one we see in Safari.app.

## Demo

| Safari        | IPSqueezableViewController  |
| ------------- | --------------------------- |
| ![](https://raw.githubusercontent.com/zetachang/IPSqueezableViewController/master/Demo/demo-safari.gif) | ![](https://raw.githubusercontent.com/zetachang/IPSqueezableViewController/master/Demo/demo.gif) |

## Installation

[CocoaPods](http://cocoapods.org) is the recommended method to install. Simply add the following line to your `Podfile`:

#### Podfile

```ruby
pod 'IPSqueezableViewController'
```

## Usage

1. Make your view controller inherit `IPSqueezableViewController`.
2. Set up the `triggeringScrollView` property as the scrollview you want to trigger the condensing effect.
3. Set up `ip_rightNavBarItem` property to the bar button item you want to show as the right bar button item of the view controller.
4. See `Demo/IPSqueezableViewController.xcodepro` for example.

## Requirements

* The subclass of IPSqueezableViewController must be contained in a `UINavigationController` and **cannot** be the `topViewController` of a `UINavigationController`.

## Contributions

Suggestions or PR are welcome :-)

## Contact

[David Chang](http://github.com/zetachang)
[@zetachang](https://twitter.com/zetachang)

## License

In short, IPSqueezableViewController is available under the MIT license. See the LICENSE file for more info.
