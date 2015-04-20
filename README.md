# NJHMultiTheme
Set separate Xcode themes for Swift and Objective-C source files.

![](https://raw.githubusercontent.com/nathanhosselton/NJHMultiTheme/master/Screenshot.png)

The selected theme will become active whenever the corresponding source file type has focus.
## Installation
Alcatraz integration is coming soon. In the meantime, simply build the project and restart Xcode.

## Removal
In Terminal, run:
```
rm -rf ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/NJHMultiTheme.xcplugin
```

## Considerations
While the vast majority of use cases will see MultiTheme function as you would expect, there are edge cases where behavior is not as refined as I would like.
* When switching between multiple open projects, theme changing is not as quick when landing on a different file type and may sometimes flicker. Clicking into the source editor will settle this.
* When multiple file types are opened in the Assistant Editor, only the current theme will be used. This is simply a limitation with themes in Xcode. However, manual manipulation of the additional source editor spaces could allow for an effective display of multiple themes at once, which is something I might look into for a future enhancement.
