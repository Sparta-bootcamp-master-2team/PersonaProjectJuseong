//
//  SceneDelegate.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appCoordinator?.saveLastViewedScreen()
    }
}

