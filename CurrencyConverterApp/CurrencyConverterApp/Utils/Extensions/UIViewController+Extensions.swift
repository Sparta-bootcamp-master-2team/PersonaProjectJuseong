//
//  UIViewController+Extensions.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/16/25.
//

import UIKit

extension UIViewController {
    func showAlert(title: String, message: String, completionHandler: @escaping () -> Void = { }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completionHandler() }))
        self.present(alert, animated: true)
    }
    
    func showNetworkErrorAlert(for error: Error) {
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
        
        showAlert(title: "네트워크 오류", message: message) { exit(0) }
    }
}
