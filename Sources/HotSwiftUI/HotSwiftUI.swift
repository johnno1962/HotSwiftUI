//
//  HotSwiftUI.swift
//  HotSwiftUI
//
//  Created by John Holdsworth on 03/01/2021.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  $Id: //depot/HotSwiftUI/Sources/HotSwiftUI/HotSwiftUI.swift#15 $
//

import SwiftUI
#if DEBUG
import Combine

public let injectionObserver = InjectionObserver()

public class InjectionObserver: ObservableObject {
    @Published var injectionNumber = 0
    var cancellable: AnyCancellable? = nil
    let publisher = PassthroughSubject<Void, Never>()
    init() {
        cancellable = NotificationCenter.default.publisher(for:
            Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { [weak self] change in
            self?.injectionNumber += 1
            self?.publisher.send()
        }
    }
}

private var loadInjectionOnce: Void = {
    guard objc_getClass("InjectionClient") == nil else {
        return
    }
    #if os(macOS) || targetEnvironment(macCatalyst)
    let bundleName = "macOSInjection.bundle"
    #elseif os(tvOS)
    let bundleName = "tvOSInjection.bundle"
    #elseif targetEnvironment(simulator)
    let bundleName = "iOSInjection.bundle"
    #else
    let bundleName = "maciOSInjection.bundle"
    #endif
    let bundlePath = "/Applications/InjectionIII.app/Contents/Resources/"+bundleName
    guard let bundle = Bundle(path: bundlePath), bundle.load() else {
        return print("""
            ⚠️ Could not load injection bundle from \(bundlePath). \
            Have you downloaded the InjectionIII.app from either \
            https://github.com/johnno1962/InjectionIII/releases \
            or the Mac App Store? Build clean if you have been \
            using the HotReloading Swift Package from github.
            """)
    }
}()

extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View {
        _ = loadInjectionOnce
        return AnyView(self)
    }
    public func enableInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func loadInjection() -> some SwiftUI.View {
        return eraseToAnyView()
    }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
            .onReceive(injectionObserver.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}

@available(iOS 13.0, *)
@propertyWrapper
public struct ObserveInjection: DynamicProperty {
    @ObservedObject private var iO = injectionObserver
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}

#else
extension SwiftUI.View {
    @inline(__always)
    public func eraseToAnyView() -> some SwiftUI.View { return self }
    @inline(__always)
    public func enableInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func loadInjection() -> some SwiftUI.View { return self }
    @inline(__always)
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
    }
}

@available(iOS 13.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#endif
