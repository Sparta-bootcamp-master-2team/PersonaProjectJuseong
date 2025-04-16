//
//  CalculatorViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/15/25.
//

import UIKit
import SnapKit

final class CalculatorViewController: UIViewController {
    
    private let exchangeRate: ExchangeRateInfo
    
    init(exchangeRate: ExchangeRateInfo) {
        self.exchangeRate = exchangeRate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 통화 코드와 국가명을 수직으로 정렬하는 스택 뷰
    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [currencyLable, countryLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()
    
    /// 통화 코드 라벨 (예: USD, KRW)
    private let currencyLable: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    /// 국가명 라벨 (예: 미국, 대한민국)
    private let countryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    private let amountTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.placeholder = "달러(USD)를 입력하세요"
        textField.textAlignment = .center
        return textField
    }()
    
    private lazy var convertButton: UIButton = {
        let button = UIButton()
        button.setTitle("환율 계산", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(convertButtonDidTap), for: .touchUpInside)
        return button
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "게산 결과가 여기에 표시됩니다"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        self.title = "환율 계산기"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        setupConstraints()
    }
    
    private func setupConstraints() {
        [
            labelStackView,
            amountTextField,
            convertButton,
            resultLabel
        ].forEach { self.view.addSubview($0) }
        
        labelStackView.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide).inset(32)
            $0.centerX.equalToSuperview()
        }
        
        amountTextField.snp.makeConstraints {
            $0.top.equalTo(labelStackView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }
        
        convertButton.snp.makeConstraints {
            $0.top.equalTo(amountTextField.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }
        
        resultLabel.snp.makeConstraints {
            $0.top.equalTo(convertButton.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(24)
        }
    }
    
    private func configureUI() {
        currencyLable.text = exchangeRate.currencyCode
        countryLabel.text = exchangeRate.country
    }
    
    @objc
    private func convertButtonDidTap() {
        guard
            let inputText = amountTextField.text,
            let inputAmount = validateInput(inputText)
        else { return }
        
        fetchAndUpdateExchangeRate(for: inputAmount)
    }
    
    private func validateInput(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            showAlert(title: "오류", message: "금액을 입력해주세요")
            return nil
        }
        
        guard let amount = Double(trimmed) else {
            showAlert(title: "오류", message: "올바른 숫자를 입력해주세요")
            return nil
        }
        
        return amount
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        self.present(alert, animated: true)
    }
    
    private func fetchAndUpdateExchangeRate(for amount: Double) {
        Task {
            do {
                let allRates = try await NetworkManager.shared.fetchExchangeRateData()
                let matchedRate = allRates.first { $0.currencyCode == exchangeRate.currencyCode }
                
                await MainActor.run {
                    updateResultLabel(rate: matchedRate?.rate, amount: amount)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateResultLabel(rate: Double?, amount: Double) {
        guard let rate else { return }

        let formattedAmount = String(format: "%.2f", amount)
        let formattedResult = String(format: "%.2f", rate * amount)

        resultLabel.text = "$\(formattedAmount) → \(formattedResult) \(exchangeRate.currencyCode)"
    }

}
