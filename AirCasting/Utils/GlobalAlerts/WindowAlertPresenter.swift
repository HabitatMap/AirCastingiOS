// Created by Lunar on 18/08/2022.
//

import UIKit

class WindowAlertPresenter: GlobalAlertPresenter {
    func showAlert(title: String, text: String, buttons: [GlobalAlertButton]) {
        guard let windowScene = UIApplication.firstActiveWindowScene else { return }
        let (window, vc) = setupWindow(in: windowScene)
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addButtons(buttons, window: window)
        vc.present(alert, animated: true)
    }
    
    private func setupWindow(in windowScene: UIWindowScene) -> (UIWindow, UIViewController) {
        let window = UIWindow(windowScene: windowScene)
        window.frame = UIScreen.main.bounds
        window.windowLevel = UIWindow.Level.statusBar + 1
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        window.rootViewController = vc
        window.makeKeyAndVisible()
        return (window, vc)
    }
}

private extension UIAlertController {
    func addButtons(_ buttons: [GlobalAlertButton], window: UIWindow) {
        buttons.forEach { alertButton in
            let action = UIAlertAction(title: alertButton.title, style: .default, handler: { _ in
                window.isHidden = true
                alertButton.onTap?()
            })
            self.addAction(action)
        }
    }
}
