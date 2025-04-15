//
//  ExchangeRatesDTO.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import Foundation

struct ExchangeRatesDTO: Decodable {
    let rates: [String: Double]
    
    var exchangeRateList: [ExchangeRateInfo] {
        rates.map { ExchangeRateInfo(currencyCode: $0.key, rate: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }
}
