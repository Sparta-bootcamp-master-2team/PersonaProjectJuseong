//
//  ExchangeRateRepository.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/23/25.
//

import Foundation

final class ExchangeRateRepository {
    func fetchExchangeRates() async -> Result<[ExchangeRateInfo], Error> {
        let result: Result<[ExchangeRateInfo], Error>

        let nextUpdateUnix = await CoreDataManager.shared.fetchNextUpdateTime()
        let now = Int64(Date().timeIntervalSince1970)
        
        if let nextUpdateUnix {
            if now >= nextUpdateUnix {
                print("업데이트")
                result = await updateRatesOnly()
            } else {
                print("코어 데이터")
                let cachedEntities = await CoreDataManager.shared.fetchExchangeRates()
                result = .success([ExchangeRateInfo].fromEntity(cachedEntities))
            }
        } else {
            print("최초 실행")
            result = await fetchAndSaveAll()
        }
         
        return result
    }
    
    private func fetchAndSaveAll() async -> Result<[ExchangeRateInfo], Error> {
        do {
            let response = try await NetworkManager.shared.fetchExchangeRateData()
            await CoreDataManager.shared.saveExchangeRates(response.exchangeRateList)
            await CoreDataManager.shared.saveTimeStamp(
                last: response.timeLastUpdateUnix,
                next: response.timeNextUpdateUnix
            )
            return .success(response.exchangeRateList)
        } catch {
            return .failure(error)
        }
    }

    private func updateRatesOnly() async -> Result<[ExchangeRateInfo], Error> {
        do {
            let response = try await NetworkManager.shared.fetchExchangeRateData()
            let rateMap = Dictionary(uniqueKeysWithValues: response.exchangeRateList.map { ($0.currencyCode, $0.rate) })
            
            await CoreDataManager.shared.updateExchangeRates(rateMap)
            await CoreDataManager.shared.deleteTimeStamp()
            await CoreDataManager.shared.saveTimeStamp(
                last: response.timeLastUpdateUnix,
                next: response.timeNextUpdateUnix
            )

            let updatedEntities = await CoreDataManager.shared.fetchExchangeRates()
            return .success([ExchangeRateInfo].fromEntity(updatedEntities))
        } catch {
            return .failure(error)
        }
    }
}
