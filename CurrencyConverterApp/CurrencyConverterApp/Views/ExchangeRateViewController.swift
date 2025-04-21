//
//  ExchangeRateViewController.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/14/25.
//

import UIKit
import SnapKit

final class ExchangeRateViewController: UIViewController {
    
    // MARK: - Properties

    /// ExchangeRateViewModel 인스턴스
    private let viewModel: ExchangeRateViewModel
    
    /// Diffable DataSource 섹션 정의
    enum Section { case main }
    typealias Item = ExchangeRateInfo
    private var datasource: UITableViewDiffableDataSource<Section, Item>!
    
    // MARK: - UI Components
    
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
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    /// 환율 정보를 표시할 테이블 뷰
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.rowHeight = 60
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(ExchangeRateCell.self, forCellReuseIdentifier: ExchangeRateCell.reuseIdentifier)
        return tableView
    }()
    
    // MARK: - Initailizer
    init(viewModel: ExchangeRateViewModel) {
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
        configureDataSource()
        bindViewModel()
        viewModel.action?(.fetch) // 데이터 로드 액션 전달
    }
    
    // MARK: - UI Setup
    
    /// UI 요소들을 초기화하고 배치
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        title = "환율 정보"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupConstraints()
    }
    
    /// SnapKit을 사용하여 UI 제약 조건 설정
    private func setupConstraints() {
        [searchBar, tableView].forEach { view.addSubview($0) }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
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
                exchangeRate: item.rate,
                trend: item.trend,
                isFavorite: item.isFavorite
            )
            cell.delegate = self
            
            return cell
        }
    }
    
    // MARK: - Binding
    
    private func bindViewModel() {
        // ViewModel의 상태 변화 시 Snapshot 업데이트 및 에러 처리
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .exchangeRates(let exchangeInfos):
                self?.configureSnapshot(with: exchangeInfos)
            case .networkError(let error):
                self?.showNetworkErrorAlert(for: error)
            }
        }
    }
    
    // MARK: - Snapshot Update
    
    /// Snapshot을 구성하여 테이블 뷰에 적용
    private func configureSnapshot(with items: [ExchangeRateInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
        
        // 검색 결과가 없을 경우 빈 메시지 라벨을 배경으로 설정
        tableView.backgroundView = items.isEmpty ? emptyMessageLabel : nil
    }
    
    // MARK: - Utility
    
    /// 키보드를 내리는 동작 처리
    private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UISearchBarDelegate

extension ExchangeRateViewController: UISearchBarDelegate {
    /// 검색 버튼 클릭 시 키보드 내림
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    /// 검색어 변경 시 필터링 적용
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 검색 입력 시 필터링 액션 전달
        viewModel.action?(.applyFilter(searchText))
    }
}

// MARK: - UITableViewDelegate

extension ExchangeRateViewController: UITableViewDelegate {
    /// 셀 선택 시 CalculatorViewController로 이동
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let exchangeRate = datasource.itemIdentifier(for: indexPath) else { return }
        let nextVM = CalculatorViewModel(exchangeRate: exchangeRate)
        let nextVC = CalculatorViewController(viewModel: nextVM)
        navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension ExchangeRateViewController: ExchangeRateCellDelegate {
    func favoriteButtonDidTap(for currencyCode: String) {
        viewModel.action?(.favorite(currencyCode))
    }
}
