//
//  UIAlert++.swift
//  Kitsune
//
//  Created by haxi0 on 05.12.2023.
//

import UIKit

var currentUIAlertController: UIAlertController?

extension UIApplication {
    func dismissAlert(animated: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController?.dismiss(animated: animated)
        }
    }
    func alert(title: String, body: String, animated: Bool = true, withButton: Bool = true) {
        DispatchQueue.main.async {
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if withButton { currentUIAlertController?.addAction(.init(title: "OK", style: .cancel)) }
            self.present(alert: currentUIAlertController!)
        }
    }
    func confirmAlert(title: String, body: String, onOK: @escaping () -> (), noCancel: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if !noCancel {
                currentUIAlertController?.addAction(.init(title: "Cancel", style: .cancel))
            }
            currentUIAlertController?.addAction(.init(title: "OK", style: noCancel ? .cancel : .default, handler: { _ in
                onOK()
            }))
            self.present(alert: currentUIAlertController!)
        }
    }
    func change(title: String, body: String) {
        DispatchQueue.main.async {
            currentUIAlertController?.title = title
            currentUIAlertController?.message = body
        }
    }
    
    func present(alert: UIAlertController) {
        if var topController = self.windows[0].rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true)
            // topController should now be your topmost view controller
        }
    }
    
    func alertWithTextField(title: String, body: String, placeholder: String, onOK: @escaping (String) -> ()) {
           DispatchQueue.main.async {
               currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)

               currentUIAlertController?.addTextField { textField in
                   textField.placeholder = placeholder
               }
               
               currentUIAlertController?.addAction(.init(title: "Cancel", style: .cancel))

               currentUIAlertController?.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                   if let text = currentUIAlertController?.textFields?.first?.text {
                       onOK(text)
                   }
               })

               self.present(alert: currentUIAlertController!)
           }
       }
}

