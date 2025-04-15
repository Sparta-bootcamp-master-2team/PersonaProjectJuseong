//
//  MainViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

final class MainViewController: UIViewController {
    
    private let tableView = UITableView()
    
    enum Section { case main }
    typealias Item = ExchangeRateInfo
    private var datasource: UITableViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureTableView()
        loadExchangeRates()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        setupConstraints()
    }
    
    private func setupConstraints() {
        [tableView].forEach { self.view.addSubview($0) }
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func configureTableView() {
        tableView.rowHeight = 60
        tableView.register(ExchangeRateCell.self, forCellReuseIdentifier: ExchangeRateCell.reuseIdentifier)
        configureDataSource()
    }
    
    private func configureDataSource() {
        datasource = UITableViewDiffableDataSource<Section, Item>(
            tableView: tableView
        ) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ExchangeRateCell.reuseIdentifier,
                for: indexPath
            ) as! ExchangeRateCell
            
            cell.configure(
                currency: item.currencyCode,
                country: item.country,
                exchangeRate: item.rate
            )
            
            return cell
        }
    }

    private func loadExchangeRates() {
        Task {
            do {
                let exchangeRateList = try await NetworkManager.shared.fetchExchangeRateData()
                
                await MainActor.run {
                    configureSnapshot(with: exchangeRateList)
                }
            } catch {
                await MainActor.run {
                    presentNetworkErrorAlert(for: error)
                }
            }
        }
    }
    
    private func configureSnapshot(with items: [ExchangeRateInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        self.datasource.apply(snapshot)
    }
    
    private func presentNetworkErrorAlert(for error: Error) {
        guard let networkError = error as? NetworkError else { return }
        let message: String
        
        switch networkError {
        case .invalidURL:
            message = "유효하지 않은 URL입니다."
        case .responseError:
            message = "서버로부터 정상적인 응답을 받지 못했습니다."
        case .decodingError:
            message = "정보를 불러오는 데 실패했습니다."
        }
        
        showAlert(title: "오류", message: message)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in exit(0) }))
        self.present(alert, animated: true)
    }
}
