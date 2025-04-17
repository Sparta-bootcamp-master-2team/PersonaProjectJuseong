//
//  ExchangeRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//

import Foundation

/// ExchangeRate 화면에서 사용하는 상태 정의
enum ExchangeRateState {
    case exchangeRates([ExchangeRateInfo])
    case networkError(Error)
}

/// ExchangeRate 화면에서 발생 가능한 액션 정의
enum ExchangeRateAction {
    case fetch              // 환율 데이터 전체 로드
    case applyFilter(String)    // 검색어를 통한 필터링
}

@MainActor
final class ExchangeRateViewModel: ViewModelProtocol {
    // MARK: - Typealias

    typealias Action = ExchangeRateAction
    typealias State = ExchangeRateState
    
    // MARK: - Properties
    
    /// 네트워크에서 불러온 전체 환율 데이터를 저장
    private var allExchangeRates: [ExchangeRateInfo] = []
    
    /// 현재 상태 (변경 시 onStateChange 호출)
    private(set) var state: ExchangeRateState {
        didSet {
            onStateChange?(state)
        }
    }
        
    /// View에서 전달받은 액션을 처리하는 클로저
    private(set) var action: ((ExchangeRateAction) -> Void)?
    
    /// View에 상태 변경을 알리기 위한 클로저
    var onStateChange: ((ExchangeRateState) -> Void)?
    
    // MARK: - Init
    
    init() {
        self.state = .exchangeRates([]) // 초기 상태: 빈 환율 정보
        bindAction()
    }
    
    // MARK: - Binding
    
    private func bindAction() {
        // View에서 액션을 전달받으면 handle(action:)을 호출
        self.action = { [weak self] action in
            switch action {
            case .fetch:
                self?.fetchExchangeRates()
            case .applyFilter(let keyword):
                self?.filterExchangeRates(with: keyword)
            }
        }
    }
    
    // MARK: - Logic
    
    private func fetchExchangeRates() {
        let nextUpdateUnix = CoreDataManager.shared.fetchNextUpdateTime()
        let currentUnix = Int64(Date().timeIntervalSince1970)

        if nextUpdateUnix == nil || currentUnix >= nextUpdateUnix! {
            print("네트워크로 환율 데이터 가져오는 중")
            fetchFromNetwork()
        } else {
            print("CoreData에서 환율 데이터 불러오기")
            fetchFromCoreData()
        }
    }
    
    /// 네트워크를 통해 전체 환율 데이터를 불러와 상태를 업데이트
    nonisolated private func fetchFromNetwork() {
        Task {
            do {
                let response = try await NetworkManager.shared.fetchExchangeRateData()
                CoreDataManager.shared.saveExchangeRate(exchangeRates: response.exchangeRateList)
                CoreDataManager.shared.saveTimeStamp(
                    last: response.timeLastUpdateUnix,
                    next: response.timeNextUpdateUnix
                )
                print(response.timeNextUpdateUnix)
                await MainActor.run {
                    allExchangeRates = response.exchangeRateList
                    state = .exchangeRates(response.exchangeRateList)
                }
            } catch {
                await MainActor.run {
                    state = .networkError(error)
                }
            }
        }
    }
    
    private func fetchFromCoreData() {
        let entity = CoreDataManager.shared.fetchExchangeRate()
        let rates = entity.map { ExchangeRateInfo(entity: $0) }
        allExchangeRates = rates
        state = .exchangeRates(rates)
    }
    
    /// 검색어에 따른 환율 데이터 필터링을 수행
    private func filterExchangeRates(with keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let filtered: [ExchangeRateInfo]
        if trimmed.isEmpty {
            filtered = allExchangeRates
        } else {
            filtered = allExchangeRates.filter {
                $0.currencyCode.localizedCaseInsensitiveContains(trimmed) ||
                $0.country.localizedCaseInsensitiveContains(trimmed)
            }
        }
        // 필터링 결과 업데이트
        state = .exchangeRates(filtered)
    }
}
