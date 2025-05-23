//
//  ExchangeRateRepository.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

protocol ExchangeRateRepository {
    func fetchLocalExchangeRates() async -> [ExchangeRateInfo]
    func fetchNextUpdateTime() async -> Int?
    func fetchAndSaveAll() async -> Result<[ExchangeRateInfo], Error>
    func updateRatesOnly() async -> Result<[ExchangeRateInfo], Error>
    func toggleFavorite(for currencyCode: String) async -> Void
}
