//
//  AppViewControllerWrapper.swift
//  Bootstrap
//
//  Created by haxi0 on 02.01.2024.
//

import SwiftUI
import UIKit

struct AppViewControllerWrapper: UIViewControllerRepresentable {
    class Coordinator: NSObject {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let navigationController = UINavigationController(rootViewController: AppViewController.sharedInstance())
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
