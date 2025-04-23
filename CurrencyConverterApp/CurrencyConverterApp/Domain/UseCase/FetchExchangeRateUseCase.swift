//
//  FetchExchangeRateUseCase.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

final class FetchExchangeRateUseCase {
    private let repository: ExchangeRateRepository

    init(repository: ExchangeRateRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[ExchangeRateInfo], Error> {
        let localData = await repository.fetchLocalExchangeRates()
        let now = Int64(Date().timeIntervalSince1970)
        let nextUpdateUnix = await repository.fetchNextUpdateTime()

        if localData.isEmpty {
            return await repository.fetchAndSaveAll()
        } else if let next = nextUpdateUnix, now >= next {
            return await repository.updateRatesOnly()
        } else {
            return .success(localData)
        }
    }
}
