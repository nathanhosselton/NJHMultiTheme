# NJHMultiTheme
Set separate Xcode themes for Swift and Objective-C source files.

![](https://raw.githubusercontent.com/nathanhosselton/NJHMultiTheme/master/Screenshot.png)

The selected theme will become active whenever the corresponding source file type has focus.

![](https://raw.githubusercontent.com/nathanhosselton/NJHMultiTheme/master/animated.gif)
## Installation
* Via [Alcatraz](http://alcatraz.io) (recommended)
* Or simply download and build the project

## Use
1. Use the new Edit menu items to select the themes you want to use.
2. Go about your business.

## Removal
Use Alcatraz or in Terminal, run:
```
rm -rf ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/NJHMultiTheme.xcplugin
```

## Considerations
While the vast majority of use cases will see MultiTheme function as you would expect, there are edge cases where behavior is not as refined as I would like.
* When switching projects and landing on a different file type, theme changing is not as quick and may sometimes flicker. Clicking into the source editor will settle this.
* When multiple file types are opened in the Assistant Editor, only the current theme will be used. This is simply a limitation with themes in Xcode. However, manual manipulation of the additional source editor spaces could allow for an effective display of multiple themes at once, which is something I might look into for a future enhancement.
