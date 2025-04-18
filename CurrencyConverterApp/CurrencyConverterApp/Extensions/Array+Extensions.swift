//
//  Array+Extensions.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/18/25.
//

import Foundation

extension Array where Element == ExchangeRateInfo {
    static func fromDTO(_ dto: [String: Double]) -> [ExchangeRateInfo] {
        dto
            .map { ExchangeRateInfo(currencyCode: $0.key, rate: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }
    
    static func fromEntity(_ entity: [ExchangeRateEntity]) -> [ExchangeRateInfo] {
        entity
            .map { ExchangeRateInfo(
                currencyCode: $0.currency ?? "알 수 없음",
                rate: $0.rate,
                isFavorite: $0.isFavorite
            )}
            .sorted {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite
                } else {
                    return $0.currencyCode < $1.currencyCode
                }
            }
    }
}
