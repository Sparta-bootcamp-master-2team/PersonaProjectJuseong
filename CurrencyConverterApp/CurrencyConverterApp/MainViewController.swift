//
//  MainViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

final class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExchangeRates()
    }
    
    private func loadExchangeRates() {
        Task {
            do {
                let data = try await NetworkManager.shared.fetchExchangeRateData()
                print(data)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}

