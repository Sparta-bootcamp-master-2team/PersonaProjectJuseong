//
//  NetworkManager.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/15/25.
//

import Foundation

// MARK: - 네트워크 관련 에러 정의

/// 서버 통신 중 발생할 수 있는 에러 케이스 정의
enum NetworkError: Error {
    case invalidURL       // URL 생성 실패
    case responseError    // 서버 응답 오류
    case decodingError    // JSON 디코딩 실패
}

// MARK: - NetworkManager

/// 환율 데이터를 서버로부터 비동기적으로 가져오는 싱글톤 네트워크 매니저
final class NetworkManager {    
    /// 서버에서 최신 환율 데이터를 가져오는 비동기 메서드
    /// - Returns: `ExchangeRateInfo` 배열
    /// - Throws: `NetworkError`에 정의된 에러
    func fetchExchangeRateData() async throws -> ExchangeRatesDTO {
        // URL 생성
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else {
            throw NetworkError.invalidURL
        }
        
        // 서버 요청 및 응답 처리
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // HTTP 상태 코드 검사 (200~299 이외는 실패 처리)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.responseError
        }
        
        // JSON 디코딩
        guard let dto = try? JSONDecoder().decode(ExchangeRatesDTO.self, from: data) else {
            throw NetworkError.decodingError
        }
        
        return dto
    }
}
