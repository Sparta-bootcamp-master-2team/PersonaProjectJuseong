//
//  MainViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit

final class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 전체 환율 정보 배열
    private var exchangeRates: [ExchangeRateInfo] = []
    
    /// 통화 검색을 위한 서치바
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "통화 검색"
        searchBar.searchBarStyle = .minimal
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.returnKeyType = .done
        searchBar.delegate = self
        return searchBar
    }()
    
    /// 검색 결과가 없을 때 표시되는 메시지 라벨
    private let emptyMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "검색 결과 없음"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    /// 환율 정보를 표시할 테이블 뷰
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.rowHeight = 60
        tableView.delegate = self
        tableView.register(ExchangeRateCell.self, forCellReuseIdentifier: ExchangeRateCell.reuseIdentifier)
        return tableView
    }()
    
    /// 테이블 뷰의 섹션 정의
    enum Section { case main }
    
    /// Diffable DataSource에서 사용할 아이템 타입
    typealias Item = ExchangeRateInfo
    
    /// Diffable DataSource 객체
    private var datasource: UITableViewDiffableDataSource<Section, Item>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        loadExchangeRates()
    }
    
    // MARK: - UI Setup
    
    /// UI 요소들을 초기화하고 배치
    private func setupUI() {
        self.view.backgroundColor = .white
        setupConstraints()
    }
    
    /// SnapKit을 사용하여 UI 제약 조건 설정
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
    
    // MARK: - DataSource Configuration
    
    /// Diffable DataSource 구성
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

    // MARK: - Networking
    
    /// 비동기로 환율 정보를 불러옴
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
    
    // MARK: - DiffableDataSourceSnapshot Configuration
    
    /// Snapshot을 구성하여 테이블 뷰에 적용
    private func configureSnapshot(with items: [ExchangeRateInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        self.datasource.apply(snapshot, animatingDifferences: false)
        
        // 검색 결과가 없을 경우 빈 메시지 라벨을 배경으로 설정
        tableView.backgroundView = items.isEmpty ? emptyMessageLabel : nil
    }
    
    // MARK: - Error Handling
    
    /// 네트워크 오류에 따른 Alert 표시
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
    
    /// 공통 Alert 표시 함수
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in exit(0) }))
        self.present(alert, animated: true)
    }
    
    // MARK: - Utility
    
    /// 키보드를 내리는 동작 처리
    private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
    
    /// 검색 버튼 클릭 시 키보드 내림
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    /// 검색어 변경 시 필터링 적용
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter(with: searchText)
    }
    
    /// 검색 키워드에 따른 필터링 적용
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

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    
    /// 테이블 뷰 스크롤 시 키보드 내림
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
}
