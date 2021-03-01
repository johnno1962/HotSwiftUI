//
//  AppDelegate.swift
//  InjectionIII
//
//  Created by John Holdsworth on 03/01/2021.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  $Id: //depot/HotSwiftUI/Sources/HotSwiftUI/HotSwiftUI.swift#2 $
//

import SwiftUI
import Combine

#if DEBUG
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

extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View {
        return AnyView(self)
    }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
            .onReceive(injectionObserver.publisher, perform: bumpState)
            .eraseToAnyView()
    }
}
#else
extension SwiftUI.View {
    public func eraseToAnyView() -> some SwiftUI.View { return self }
    public func onInjection(bumpState: @escaping () -> ()) -> some SwiftUI.View {
        return self
    }
}
#endif
