import Foundation

// MARK: - State

/// 환율 계산기의 상태 정의
enum CalculatorState {
    case result(String)
    case error(String)
}

// MARK: - Action

/// 환율 계산기에서 발생 가능한 사용자 액션 정의
enum CalculatorAction {
    case submitInput(String)
}

// MARK: - ViewModel

final class CalculatorViewModel: ViewModelProtocol {
    // MARK: - Typealias
    
    typealias Action = CalculatorAction
    typealias State = CalculatorState
    
    // MARK: - Properties
    
    var state: State {
        didSet {
            onStateChange?(state)
        }
    }

    let exchangeRate: ExchangeRateInfo
    
    var action: ((Action) -> Void)?
    var onStateChange: ((State) -> Void)?
    
    // MARK: - Init
    
    init(exchangeRate: ExchangeRateInfo) {
        self.exchangeRate = exchangeRate
        self.state = .result("0")
        bindAction()
    }
    
    // MARK: - Binding
    
    private func bindAction() {
        self.action = { [weak self] action in
            switch action {
            case .submitInput(let userInput):
                self?.handleCalculationInput(userInput)
            }
        }
    }
    
    // MARK: - Logic
    
    /// 입력 문자열을 환율 계산하여 상태로 반영
    private func handleCalculationInput(_ input: String) {
        guard let amount = validatedAmount(from: input) else { return }
        
        let inputFormatted = String(format: "%.2f", amount)
        let resultFormatted = String(format: "%.2f", self.exchangeRate.rate * amount)
        let resultText = "$\(inputFormatted) → \(resultFormatted) \(self.exchangeRate.currencyCode)"
        
        state = .result(resultText)
    }
    
    /// 입력값 유효성 검사 및 Double로 변환
    private func validatedAmount(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            state = .error("금액을 입력해주세요")
            return nil
        }
        
        guard let amount = Double(trimmed) else {
            state = .error("올바른 숫자를 입력해주세요")
            return nil
        }
        
        return amount
    }
}
