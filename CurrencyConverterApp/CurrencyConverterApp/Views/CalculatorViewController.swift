//
//  CalculatorViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/15/25.
//

import UIKit
import SnapKit

final class CalculatorViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: CalculatorViewModel
    
    // MARK: - UI Components
    
    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [currencyLabel, countryLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()
    
    private let currencyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
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
        label.text = "계산 결과가 여기에 표시됩니다"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Initializer
    
    init(viewModel: CalculatorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupDismissKeyboardGesture()
        cofigureCurrencyInfoUI(with: viewModel.exchangeRate)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "환율 계산기"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupConstraints()
    }
    
    private func setupConstraints() {
        [
            labelStackView,
            amountTextField,
            convertButton,
            resultLabel
        ].forEach { view.addSubview($0) }
        
        labelStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(32)
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
    
    // MARK: - Binding
    
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .result(let text):
                self?.resultLabel.text = text
            case .error(let message):
                self?.showAlert(title: "입력값 오류", message: message)
            }
        }
    }
    
    private func cofigureCurrencyInfoUI(with exchangeRate: ExchangeRateInfo) {
        currencyLabel.text = exchangeRate.currencyCode
        countryLabel.text = exchangeRate.country
    }
    
    // MARK: - Actions
    
    @objc
    private func convertButtonDidTap() {
        guard let inputText = amountTextField.text else { return }
        viewModel.action?(.submitInput(inputText))
    }
    
    // MARK: - Keyboard Dismiss
    
    private func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
}
