//
//  SceneDelegate.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        Task {
            let screen = await CoreDataManager.shared.fetchLastViewedScreen()
            
            let exchangeRateRepository = ExchangeRateRepository()
            let fetchExchangeRateUseCase = FetchExchangeRateUseCase(exchangeRateRepository: exchangeRateRepository)
            let exchangeRateVM = ExchangeRateViewModel(fetchExchangeRateUseCase: fetchExchangeRateUseCase)
            let exchangeRateVC = ExchangeRateViewController(viewModel: exchangeRateVM)
            let nav = UINavigationController(rootViewController: exchangeRateVC)
            
            switch screen {
            case .exchangeRate:
                self.window = window
                window.rootViewController = nav
                window.makeKeyAndVisible()
            case .calculator(let currencyCode):
                let entities = await CoreDataManager.shared.fetchExchangeRates()
                let exchangeRateInfos = [ExchangeRateInfo].fromEntity(entities)
                
                guard let targetInfo = exchangeRateInfos.first(where: { $0.currencyCode == currencyCode }) else { break }
                
                let calculatorVM = CalculatorViewModel(exchangeRate: targetInfo)
                let calculatorVC = CalculatorViewController(viewModel: calculatorVM)
                
                self.window = window
                window.rootViewController = nav
                window.makeKeyAndVisible()
                try? await Task.sleep(nanoseconds: 400_000_000) // 0.4초 뒤 push
                nav.pushViewController(calculatorVC, animated: true)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        guard let root = window?.rootViewController as? UINavigationController else { return }
        
        let screen: LastViewedScreen
        
        if let calculatorVC = root.topViewController as? CalculatorViewController {
            screen = .calculator(currencyCode: calculatorVC.currencyCode)
        } else {
            screen = .exchangeRate
        }
        
        Task {
            await CoreDataManager.shared.saveLastViewedScreen(screen)
        }
    }
}

