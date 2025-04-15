//
//  NetworkManager.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/15/25.
//

import Foundation

// MARK: - 네트워크 관련 에러 정의

enum NetworkError: Error {
    case invalidURL
    case responseError
    case decodingError
}

//MARK: - Networking (서버와 통신하는) 클래스 모델

final class NetworkManager {
    
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchExchangeRateData() async throws -> [ExchangeRateInfo] {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.responseError
        }
        
        guard let exchangeRates = try? JSONDecoder().decode(ExchangeRatesDTO.self, from: data) else {
            throw NetworkError.decodingError
        }
        
        return exchangeRates.exchangeRateList
    }
}
