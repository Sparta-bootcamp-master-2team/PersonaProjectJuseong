//
//  ExchangeRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//

import Foundation

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

// MARK: - ViewModel

final class ExchangeRateViewModel: ViewModelProtocol {

    // MARK: - Typealias

    typealias Action = ExchangeRateAction
    typealias State = ExchangeRateState

    // MARK: - Properties

    private(set) var state: State {
        didSet {
            Task { @MainActor in
                onStateChange?(state)
            }
        }
    }
    
    private var allExchangeRates: [ExchangeRateInfo] = []
    
    private(set) var action: ((Action) -> Void)?
    var onStateChange: ((State) -> Void)?

    // MARK: - Initializer

    init() {
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
            // 현재 시간과 다음 업데이트 시간을 가져옴
            let nextUpdateUnix = await CoreDataManager.shared.fetchNextUpdateTime()
            let now = Int64(Date().timeIntervalSince1970)
            
            let result: Result<[ExchangeRateInfo], Error>
            
            // nextUpdateUnix가 nil이 아닌 경우 → 이미 캐시된 데이터가 있음
            if let nextUpdateUnix {
                if true { // MockData 테스트하기 위해 true
                    // 업데이트 시간이 지났으므로 네트워크에서 최신 환율만 갱신
                    print("업데이트")
                    result = await updateRatesOnly()
                } else {
                    // 캐시된 데이터가 아직 유효하므로 CoreData에서 데이터만 불러옴
                    print("코어 데이터")
                    let cachedEntities = await CoreDataManager.shared.fetchExchangeRates()
                    result = .success([ExchangeRateInfo].fromEntity(cachedEntities))
                }
            } else {
                print("최초 실행")
                // nextUpdateUnix가 nil인 경우 → 앱 최초 실행이거나 캐시 없음
                result = await fetchAndSaveAll()
            }

            // 결과에 따라 ViewModel 상태를 업데이트
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
            let mockRate = MockData.mockRates // 테스트 용
            
            await CoreDataManager.shared.updateExchangeRates(mockRate)
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
