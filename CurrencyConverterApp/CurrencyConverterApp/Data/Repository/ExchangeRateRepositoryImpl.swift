//
//  ExchangeRateRepositoryImpl.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

final class ExchangeRateRepositoryImpl: ExchangeRateRepository {
    
    private let dataManager: CoreDataManager
    private let networkManager: NetworkManager
    
    init(dataManager: CoreDataManager, networkManager: NetworkManager) {
        self.dataManager = dataManager
        self.networkManager = networkManager
    }

    func fetchLocalExchangeRates() async -> [ExchangeRateInfo] {
        let entities = await dataManager.fetchExchangeRates()
        return [ExchangeRateInfo].fromEntity(entities)
    }

    func fetchNextUpdateTime() async -> Int? {
        await dataManager.fetchNextUpdateTime()
    }

    func fetchAndSaveAll() async -> Result<[ExchangeRateInfo], Error> {
        do {
            let dto = try await networkManager.fetchExchangeRateData()
            let list = [ExchangeRateInfo].fromDTO(dto.rates)
            let next = Int(dto.timeNextUpdateUnix)

            await dataManager.saveExchangeRates(list)
            await dataManager.saveTimeStamp(next: next)
            return .success(list)
        } catch {
            return .failure(error)
        }
    }

    func updateRatesOnly() async -> Result<[ExchangeRateInfo], Error> {
        do {
            let dto = try await networkManager.fetchExchangeRateData()
            let updatedList = [ExchangeRateInfo].fromDTO(dto.rates)
            let next = Int(dto.timeNextUpdateUnix)

            let rateMap = Dictionary(uniqueKeysWithValues: updatedList.map { ($0.currencyCode, $0.rate) })
            await dataManager.updateExchangeRates(rateMap)

            await dataManager.deleteTimeStamp()
            await dataManager.saveTimeStamp(next: next)

            let refreshed = await dataManager.fetchExchangeRates()
            return .success([ExchangeRateInfo].fromEntity(refreshed))
        } catch {
            return .failure(error)
        }
    }
    
    func toggleFavorite(for currencyCode: String) async {
          await dataManager.toggleFavorite(for: currencyCode)
      }
}
