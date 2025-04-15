//
//  MainViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

final class MainViewController: UIViewController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ExchangeRateCell.self, forCellReuseIdentifier: ExchangeRateCell.reuseIdentifier)
        return tableView
    }()
    
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
        tableView.delegate = self
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
            cell.configure(currency: item.currencyCode, exchangeRate: item.rate)
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
                print(error.localizedDescription)
            }
        }
    }
    
    private func configureSnapshot(with items: [ExchangeRateInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        self.datasource.apply(snapshot)
    }
    
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
