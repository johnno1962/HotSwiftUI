//
//  HotSwiftUI.swift
//  HotSwiftUI
//
//  Created by John Holdsworth on 03/01/2021.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  $Id: //depot/HotSwiftUI/Sources/HotSwiftUI/HotSwiftUI.swift#25 $
//

import SwiftUI
#if DEBUG
import Combine

public class InjectionObserver {
    public static let shared = InjectionObserver()
    public static var appResources =
        "/Applications/InjectionIII.app/Contents/Resources/"
    public static var keyed = [String: InjectionCounter]()
    public class InjectionCounter: ObservableObject {
        @Published var injectionNumber = 0
    }
    var cancellable: AnyCancellable? = nil
    let publisher = PassthroughSubject<Void, Never>()
    init() {
        _ = loadInjectionOnce // .enableInjection() optional with Xcode 16+
        cancellable = NotificationCenter.default.publisher(for:
            Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { [weak self] change in
            var incremented = false
            for key in change.object as? [String] ?? [] {
                if let counter = Self.keyed[key] {
                    counter.injectionNumber += 1
                    incremented = true
                }
            }
            if !incremented {
                for counter in Self.keyed.values {
                    counter.injectionNumber += 1
                }
            }
            self?.publisher.send()
        }
    }
}

private var loadInjectionOnce: Void = {
    guard objc_getClass("InjectionClient") == nil else {
        return
    }
    // If project has a "Build Phase" running script (works on device):
    // /Applications/InjectionIII.app/Contents/Resources/copy_bundle.sh
    if let path = Bundle.main.path(forResource:
            "iOSInjection", ofType: "bundle") ??
        Bundle.main.path(forResource:
            "macOSInjection", ofType: "bundle"),
        Bundle(path: path)?.load() == true {
        return
    }
    #if os(macOS) || targetEnvironment(macCatalyst)
    let bundleName = "macOSInjection.bundle"
    #elseif os(tvOS)
    let bundleName = "tvOSInjection.bundle"
    #elseif os(visionOS)
    let bundleName = "xrOSInjection.bundle"
    #elseif os(watchOS)
    let bundleName = "watchOSInjection.bundle"
    #elseif targetEnvironment(simulator)
    let bundleName = "iOSInjection.bundle"
    #else
    let bundleName = "maciOSInjection.bundle"
    #endif
    let bundlePath = InjectionObserver.appResources+bundleName
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
            .onReceive(InjectionObserver.shared.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection: DynamicProperty {
    @ObservedObject private var iO: InjectionObserver.InjectionCounter
    public init(path: String = #filePath) {
        _ = InjectionObserver.shared
        let url = URL(fileURLWithPath: path)
        let key = url.deletingPathExtension().lastPathComponent
        if let counter = InjectionObserver.keyed[key] {
            iO = counter
        } else {
            iO = InjectionObserver.InjectionCounter()
            InjectionObserver.keyed[key] = iO
        }
    }
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct ObserveInjection {
    public init() {}
    public private(set) var wrappedValue: Int {
        get {0} set {}
    }
}
#endif
