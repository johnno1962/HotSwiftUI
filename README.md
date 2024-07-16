# HotSwiftUI

Utilitiy methods for use with [HotReloading](https://github.com/johnno1962/HotReloading) or [InjectionIII](https://github.com/johnno1962/InjectionIII) to make live code updates to fully functional SwiftUI Applictions.

Add this repo to your project and add the following to a source file.
```
@_exported import HotSwiftUI
```

This will make the `.eraseToAnyView()` method on `SwiftUI.View`
used to erase their type available throughout the app along with the
global `injectionObserver` variable you can observe to force the
View to update when code has been injected. SwiftUI is very well
suited to injection as, provided you observe the injectionObserver
which has an `@Published` injection counter, you can rest assured
your views will update as required.

In short, modify the end of your `SwiftUI` View body properties
to look like this:
```Swift
    var body: some View {
        // Your SwiftUI code...
        .eraseToAnyView()
    }

    #if DEBUG
    @ObservedObject var iO = injectionObserver
    #endif
    // or use the new property wrapper...
    @ObserveInjection var redraw
```
You need to do this for all view properties you'd like to inject
and have refesh on injection which is a bit tedious but the InjectionIII
or HotReloading app can make these changes automatically using the
"Prepare Project" Menu Item. You can check in these changes as, in a
"Release" build, these functions compile to a null operation.

There is a compatible version of this code along with ideas further developed for 
"hosting" UIViewControllers in the project https://github.com/krzysztofzablocki/Inject.
