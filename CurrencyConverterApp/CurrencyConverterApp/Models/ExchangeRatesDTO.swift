//
//  ExchangeRatesDTO.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import Foundation

/// 환율 API 응답에서 필요한 데이터만 추출한 DTO
/// 전체 JSON 중 "rates" 키의 값만 사용
struct ExchangeRatesDTO: Decodable {
    
    /// 통화 코드와 환율을 매핑한 딕셔너리 (예: ["KRW": 1350.123])
    let rates: [String: Double]
    
    /// `ExchangeRateInfo` 배열로 변환된 가공 데이터
    /// 알파벳순 정렬된 리스트 반환
    var exchangeRateList: [ExchangeRateInfo] {
        rates
            .map { ExchangeRateInfo(currencyCode: $0.key, rate: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
    }
}
