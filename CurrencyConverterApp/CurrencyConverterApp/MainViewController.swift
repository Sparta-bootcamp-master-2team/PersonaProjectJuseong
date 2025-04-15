//
//  MainViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

final class MainViewController: UIViewController {
    
    private var exchangeRates: [ExchangeRateInfo] = []
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "통화 검색"
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        return searchBar
    }()
    
    private let emptyMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "검색 결과 없음"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.rowHeight = 60
        tableView.register(ExchangeRateCell.self, forCellReuseIdentifier: ExchangeRateCell.reuseIdentifier)
        return tableView
    }()
    
    enum Section { case main }
    typealias Item = ExchangeRateInfo
    private var datasource: UITableViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        loadExchangeRates()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        setupConstraints()
    }
    
    private func setupConstraints() {
        [searchBar ,tableView].forEach { self.view.addSubview($0) }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.horizontalEdges.equalTo(self.view.safeAreaLayoutGuide)
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
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
                exchangeRates = try await NetworkManager.shared.fetchExchangeRateData()
                
                await MainActor.run {
                    configureSnapshot(with: exchangeRates)
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
        self.datasource.apply(snapshot, animatingDifferences: false)
        
        tableView.backgroundView = items.isEmpty ? emptyMessageLabel : nil
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

extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter(with: searchText)
    }
    
    private func applyFilter(with keyword: String) {
        let filtered: [ExchangeRateInfo]
        
        if keyword.isEmpty {
            filtered = exchangeRates
        } else {
            filtered = exchangeRates.filter {
                $0.currencyCode.lowercased().contains(keyword.lowercased()) ||
                $0.country.contains(keyword)
            }
        }
        
        configureSnapshot(with: filtered)
    }

}

