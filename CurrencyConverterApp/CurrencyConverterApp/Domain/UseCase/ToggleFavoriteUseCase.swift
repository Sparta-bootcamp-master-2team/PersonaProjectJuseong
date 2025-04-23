//
//  ToggleFavoriteUseCase.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

final class ToggleFavoriteUseCase {
    private let repository: ExchangeRateRepository

    init(repository: ExchangeRateRepository) {
        self.repository = repository
    }

    func execute(for currencyCode: String) async -> [ExchangeRateInfo] {
        await repository.toggleFavorite(for: currencyCode)
        return await repository.fetchLocalExchangeRates()
    }
}
