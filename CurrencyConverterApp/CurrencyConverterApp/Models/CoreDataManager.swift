//
//  CoreDataManager.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//

import UIKit
import CoreData

final class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private lazy var context: NSManagedObjectContext = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate를 찾을 수 없음")
        }
        return appDelegate.persistentContainer.viewContext
    }()
    
    func fetchExchangeRate() -> [ExchangeRateEntity] {
        let request: NSFetchRequest<ExchangeRateEntity> = ExchangeRateEntity.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("환율 정보 가져오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveExchangeRate(exchangeRates: [ExchangeRateInfo]) {
        // 기존 데이터 삭제
        let request: NSFetchRequest<NSFetchRequestResult> = ExchangeRateEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
        } catch {
            print("기존 ExchangeRate 삭제 실패: \(error)")
        }
        
        exchangeRates.forEach {
            let entity = ExchangeRateEntity(context: context)
            entity.currency = $0.currencyCode
            entity.country = $0.country
            entity.rate = $0.rate
            entity.isFavorite = false
        }
        
        saveContext()
    }
    
    func fetchNextUpdateTime() -> Int? {
        let request: NSFetchRequest<ExchangeRateTimeStampEntity> = ExchangeRateTimeStampEntity.fetchRequest()
        
        do {
            if let result = try context.fetch(request).first {
                return Int(result.timeNextUpdateUnix)
            } else {
                return nil
            }
        } catch {
            print("fetchTimeStamp 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveTimeStamp(last: Int, next: Int) {
        // 기존 데이터 삭제
        let request: NSFetchRequest<NSFetchRequestResult> = ExchangeRateTimeStampEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
        } catch {
            print("기존 TimeStamp 삭제 실패: \(error)")
        }
        
        // 새로운 데이터 저장
        let entity = ExchangeRateTimeStampEntity(context: context)
        entity.timeLastUpdateUnix = Int64(last)
        entity.timeNextUpdateUnix = Int64(next)
        saveContext()
    }
    
    func toggleFavorite(for currencyCode: String) {
        let request: NSFetchRequest<ExchangeRateEntity> = ExchangeRateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "currency == %@", currencyCode)
        
        do {
            if let target = try context.fetch(request).first {
                target.isFavorite.toggle()
                saveContext()
            }
        } catch {
            print("즐겨찾기 상태 토글 실패: \(error)")
        }
    }

    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Context 저장 실패: \(error)")
            }
        }
    }
}
