//
//  ExchangeRateResponse.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//


// ExchangeRateResponse.swift

struct ExchangeRateResponse {
    let exchangeRateList: [ExchangeRateInfo]
    let timeLastUpdateUnix: Int
    let timeNextUpdateUnix: Int
}
