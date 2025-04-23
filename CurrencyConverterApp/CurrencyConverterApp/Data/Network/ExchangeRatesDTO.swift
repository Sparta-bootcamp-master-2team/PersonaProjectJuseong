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
    
    let timeLastUpdateUnix: Int
    let timeNextUpdateUnix: Int
    /// 통화 코드와 환율을 매핑한 딕셔너리 (예: ["KRW": 1350.123])
    let rates: [String: Double]
    
    enum CodingKeys: String, CodingKey {
        case timeLastUpdateUnix = "time_last_update_unix"
        case timeNextUpdateUnix = "time_next_update_unix"
        case rates
    }
}
