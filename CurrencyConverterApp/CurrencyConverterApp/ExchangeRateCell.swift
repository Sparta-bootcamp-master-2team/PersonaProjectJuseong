//
//  ExchangeRateCell.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit
import SnapKit

final class ExchangeRateCell: UITableViewCell {
    
    // MARK: - Properties
    
    /// 셀 재사용 식별자
    static let reuseIdentifier = "ExchangeRateCell"
    
    /// 통화 코드와 국가명을 수직으로 정렬하는 스택 뷰
    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [currencyLable, countryLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    /// 통화 코드 라벨 (예: USD, KRW)
    private let currencyLable: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    /// 국가명 라벨 (예: 미국, 대한민국)
    private let countryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    /// 환율 표시 라벨
    private let exchangeRateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    /// 셀의 UI 구성 및 초기화
    private func setupUI() {
        self.contentView.backgroundColor = .white
        setupConstraints()
    }
    
    /// SnapKit을 사용하여 UI 제약 조건 설정
    private func setupConstraints() {
        [labelStackView, exchangeRateLabel].forEach { contentView.addSubview($0) }
        
        labelStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        
        exchangeRateLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(labelStackView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(120)
            $0.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    
    /// 셀에 데이터를 바인딩하여 표시
    /// - Parameters:
    ///   - currency: 통화 코드 (예: USD)
    ///   - country: 국가명 (예: 미국)
    ///   - exchangeRate: 환율 값 (예: 1324.1234)
    func configure(currency: String, country: String, exchangeRate: Double) {
        currencyLable.text = currency
        countryLabel.text = country
        exchangeRateLabel.text = String(format: "%.4f", exchangeRate)
    }
}
