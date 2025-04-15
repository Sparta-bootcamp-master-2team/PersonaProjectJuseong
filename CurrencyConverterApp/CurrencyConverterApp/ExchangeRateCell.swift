//
//  ExchangeRateCell.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit
import SnapKit

final class ExchangeRateCell: UITableViewCell {
    
    static let reuseIdentifier = "ExchangeRateCell"
    
    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [currencyLable, countryLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    private let currencyLable: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let countryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        return label
    }()
    
    private let exchangeRateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
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
    
    func configure(currency: String, country:String, exchangeRate: Double) {
        currencyLable.text = currency
        countryLabel.text = country
        exchangeRateLabel.text = String(format: "%.4f", exchangeRate)
    }
}
