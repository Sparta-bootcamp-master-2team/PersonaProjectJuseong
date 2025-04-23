//
//  AppCoordinator.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import UIKit

@MainActor
final class AppCoordinator {

    private let window: UIWindow
    private let navigationController = UINavigationController()
    private let dataManager = CoreDataManager()

    init(window: UIWindow) {
        self.window = window
    }
    
    private func showInitialScreen() async {
        let screen = await dataManager.fetchLastViewedScreen()
        let mainVC = makeExchangeRateViewController()
        navigationController.setViewControllers([mainVC], animated: false)
        
        if case .calculator(let currencyCode) = screen {
            await pushCalculator(for: currencyCode)
        }
    }
    
    private func makeExchangeRateViewController() -> UIViewController {
        let repository = ExchangeRateRepositoryImpl(
            dataManager: CoreDataManager(),
            networkManager: NetworkManager()
        )
        let fetchUseCase = FetchExchangeRateUseCase(repository: repository)
        let toggleUseCase = ToggleFavoriteUseCase(repository: repository)
        let viewModel = ExchangeRateViewModel(
            fetchExchangeRateUseCase: fetchUseCase,
            toggleFavoriteUseCase: toggleUseCase
        )
        return ExchangeRateViewController(viewModel: viewModel)
    }

    private func pushCalculator(for currencyCode: String) async {
        let entities = await dataManager.fetchExchangeRates()
        let list = [ExchangeRateInfo].fromEntity(entities)
        guard let selected = list.first(where: { $0.currencyCode == currencyCode }) else { return }

        let viewModel = CalculatorViewModel(exchangeRate: selected)
        let vc = CalculatorViewController(viewModel: viewModel)

        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4초 delay
        navigationController.pushViewController(vc, animated: true)
    }
    
    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        Task {
            await showInitialScreen()
        }
    }

    func saveLastViewedScreen() {
        let screen: LastViewedScreen
        
        if let calculatorVC = navigationController.topViewController as? CalculatorViewController {
            screen = .calculator(currencyCode: calculatorVC.currencyCode)
        } else {
            screen = .exchangeRate
        }
        
        Task { await dataManager.saveLastViewedScreen(screen) }
    }
}
