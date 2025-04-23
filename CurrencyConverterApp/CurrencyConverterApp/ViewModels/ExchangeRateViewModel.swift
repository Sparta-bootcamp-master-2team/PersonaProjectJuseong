//
//  ExchangeRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//

import Foundation

// MARK: - ViewModel

final class ExchangeRateViewModel: ViewModelProtocol {
    
    // MARK: - State

    /// ExchangeRate 화면에서 사용하는 상태 정의
    enum ExchangeRateState {
        case exchangeRates([ExchangeRateInfo])
        case networkError(Error)
    }

    // MARK: - Action

    /// ExchangeRate 화면에서 발생 가능한 액션 정의
    enum ExchangeRateAction {
        case fetch              // 환율 데이터 전체 로드
        case applyFilter(String)    // 검색어를 통한 필터링
        case favorite(String)
    }

    // MARK: - Typealias

    typealias Action = ExchangeRateAction
    typealias State = ExchangeRateState

    // MARK: - Properties

    var state: State {
        didSet {
            Task { @MainActor in
                onStateChange?(state)
            }
        }
    }
    
    private let fetchExchangeRateUseCase: FetchExchangeRateUseCase
    private var allExchangeRates: [ExchangeRateInfo] = []
    
    
    var action: ((Action) -> Void)?
    var onStateChange: ((State) -> Void)?

    // MARK: - Initializer

    init(fetchExchangeRateUseCase: FetchExchangeRateUseCase) {
        self.fetchExchangeRateUseCase = fetchExchangeRateUseCase
        self.state = .exchangeRates([])
        bindAction()
    }

    // MARK: - Action Handling

    private func bindAction() {
        self.action = { [weak self] action in
            guard let self else { return }

            switch action {
            case .fetch:
                self.performFetch()
            case .applyFilter(let keyword):
                self.filter(with: keyword)
            case .favorite(let currencyCode):
                self.handleFavoriteToggle(for: currencyCode)
            }
        }
    }

    // MARK: - Data Fetching

    private func performFetch() {
        Task {
            let result = await fetchExchangeRateUseCase.execute()
            
            switch result {
            case .success(let list):
                // 성공 시 전체 리스트 저장 및 상태 업데이트
                self.allExchangeRates = list
                self.state = .exchangeRates(list)
            case .failure(let error):
                // 실패 시 네트워크 에러 상태 전달
                self.state = .networkError(error)
            }
        }
    }
    
    // MARK: - Favorite Handle

    private func handleFavoriteToggle(for currencyCode: String) {
        Task {
            await CoreDataManager.shared.toggleFavorite(for: currencyCode)
            let updatedEntities = await CoreDataManager.shared.fetchExchangeRates()
            let updatedRates = [ExchangeRateInfo].fromEntity(updatedEntities)
            
            self.allExchangeRates = updatedRates
            self.state = .exchangeRates(updatedRates)
        }
    }

    // MARK: - Filtering

    private func filter(with keyword: String) {
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

        state = .exchangeRates(filtered)
    }
}
