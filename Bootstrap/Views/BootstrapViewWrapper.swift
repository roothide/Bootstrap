//
//  BootstrapViewWrapper.swift
//  Bootstrap
//
//  Created by haxi0 on 02.01.2024.
//

import SwiftUI

@objc class BootstrapViewWrapper: NSObject {
    @objc static func createBootstrapView() -> UIViewController {
        let viewController = UIHostingController(rootView: BootstrapView())
        return viewController
    }
}
