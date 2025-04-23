//
//  ExchangeRateRepositoryImpl.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

final class ExchangeRateRepositoryImpl: ExchangeRateRepository {

    func fetchLocalExchangeRates() async -> [ExchangeRateInfo] {
        let entities = await CoreDataManager.shared.fetchExchangeRates()
        return [ExchangeRateInfo].fromEntity(entities)
    }

    func fetchNextUpdateTime() async -> Int? {
        await CoreDataManager.shared.fetchNextUpdateTime()
    }

    func fetchAndSaveAll() async -> Result<[ExchangeRateInfo], Error> {
        do {
            let dto = try await NetworkManager.shared.fetchExchangeRateData()
            let list = [ExchangeRateInfo].fromDTO(dto.rates)
            let last = Int(dto.timeLastUpdateUnix)
            let next = Int(dto.timeNextUpdateUnix)

            await CoreDataManager.shared.saveExchangeRates(list)
            await CoreDataManager.shared.saveTimeStamp(last: last, next: next)
            return .success(list)
        } catch {
            return .failure(error)
        }
    }

    func updateRatesOnly() async -> Result<[ExchangeRateInfo], Error> {
        do {
            let dto = try await NetworkManager.shared.fetchExchangeRateData()
            let updatedList = [ExchangeRateInfo].fromDTO(dto.rates)
            let last = Int(dto.timeLastUpdateUnix)
            let next = Int(dto.timeNextUpdateUnix)

            let rateMap = Dictionary(uniqueKeysWithValues: updatedList.map { ($0.currencyCode, $0.rate) })
            await CoreDataManager.shared.updateExchangeRates(rateMap)

            await CoreDataManager.shared.deleteTimeStamp()
            await CoreDataManager.shared.saveTimeStamp(last: last, next: next)

            let refreshed = await CoreDataManager.shared.fetchExchangeRates()
            return .success([ExchangeRateInfo].fromEntity(refreshed))
        } catch {
            return .failure(error)
        }
    }
    
    func toggleFavorite(for currencyCode: String) async {
          await CoreDataManager.shared.toggleFavorite(for: currencyCode)
      }
}
