//
//  FetchExchangeRateUseCase.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

final class FetchExchangeRateUseCase {
    private let repository: ExchangeRateRepository

    init(exchangeRateRepository: ExchangeRateRepository) {
        repository = exchangeRateRepository
    }

    func execute() async -> Result<[ExchangeRateInfo], Error> {
        await repository.fetchExchangeRates()
    }
}
