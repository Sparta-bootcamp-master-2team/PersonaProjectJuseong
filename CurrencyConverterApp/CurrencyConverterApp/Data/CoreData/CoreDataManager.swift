//
//  CoreDataManager.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//

import CoreData

enum LastViewedScreen {
    case exchangeRate
    case calculator(currencyCode: String)
}

actor CoreDataManager {

    // MARK: - 싱글톤 인스턴스

    nonisolated static let shared = CoreDataManager()

    // MARK: - Core Data Context

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.backgroundContext) {
        self.context = context
    }

    // MARK: - 환율 정보 저장/조회

    func saveExchangeRates(_ exchangeRates: [ExchangeRateInfo]) async {
        await context.perform {
            for rate in exchangeRates {
                let entity = ExchangeRateEntity(context: self.context)
                entity.currency = rate.currencyCode
                entity.rate = rate.rate
                entity.isFavorite = rate.isFavorite
                entity.trend = Int64(rate.trend.rawValue)
            }
            self.saveContext()
        }
    }
    
    func fetchExchangeRates() async -> [ExchangeRateEntity] {
        await context.perform {
            let request: NSFetchRequest<ExchangeRateEntity> = ExchangeRateEntity.fetchRequest()
            return (try? self.context.fetch(request)) ?? []
        }
    }

    func updateExchangeRates(_ dto: [String: Double]) async {
        let existingEntities = await fetchExchangeRates()

        await context.perform {
            let entityMap: [String: ExchangeRateEntity] = Dictionary(uniqueKeysWithValues: existingEntities.compactMap {
                guard let code = $0.currency else { return nil }
                return (code, $0)
            })

            for (code, newRate) in dto {
                guard let entity = entityMap[code] else { continue }
                
                let oldRate = entity.rate
                let difference = abs(newRate - oldRate)

                // 변화량에 따라 trend 설정
                if difference > 0.01 {
                    entity.trend = newRate > oldRate ? 1 : -1
                } else {
                    entity.trend = 0
                }

                entity.rate = newRate
            }

            self.saveContext()
        }
    }

    func deleteAllExchangeRates() async {
        await context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = ExchangeRateEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            do {
                try self.context.execute(deleteRequest)
            } catch {
                print("❌ 환율 데이터 삭제 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 타임스탬프 저장/조회
    
    func saveTimeStamp(next: Int) async {
        await context.perform {
            let entity = ExchangeRateTimeStampEntity(context: self.context)
            entity.timeNextUpdateUnix = Int64(next)
            self.saveContext()
        }
    }

    func fetchNextUpdateTime() async -> Int? {
        await context.perform {
            let request: NSFetchRequest<ExchangeRateTimeStampEntity> = ExchangeRateTimeStampEntity.fetchRequest()
            return (try? self.context.fetch(request))?.first.map { Int($0.timeNextUpdateUnix) }
        }
    }

    func deleteTimeStamp() async {
        await context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = ExchangeRateTimeStampEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            do {
                try self.context.execute(deleteRequest)
            } catch {
                print("❌ 타임스탬프 삭제 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 즐겨찾기 처리

    func toggleFavorite(for currencyCode: String) async {
        await context.perform {
            let request: NSFetchRequest<ExchangeRateEntity> = ExchangeRateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "currency == %@", currencyCode)

            guard let target = try? self.context.fetch(request).first else { return }
            target.isFavorite.toggle()

            self.saveContext()
        }
    }
    
    // MARK: - 마지막 화면 상태 저장/복원
    
    func saveLastViewedScreen(_ screen: LastViewedScreen) async {
        context.performAndWait {
            // 기존에 저장된 항목 삭제
            let request: NSFetchRequest<NSFetchRequestResult> = LastViewedScreenEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            let _ = try? self.context.execute(deleteRequest)
            
            // 새 상태 저장
            let entity = LastViewedScreenEntity(context: self.context)
            switch screen {
            case .exchangeRate:
                entity.screenType = "exchangeRate"
                entity.currencyCode = nil
            case .calculator(let currency):
                entity.screenType = "calculator"
                entity.currencyCode = currency
            }
            
            self.saveContext()
        }
    }
    
    func fetchLastViewedScreen() async -> LastViewedScreen {
        await context.perform {
            let request: NSFetchRequest<LastViewedScreenEntity> = LastViewedScreenEntity.fetchRequest()
            guard let entity = try? self.context.fetch(request).first else {
                return .exchangeRate
            }
            
            if entity.screenType == "calculator", let code = entity.currencyCode {
                return .calculator(currencyCode: code)
            } else {
                return .exchangeRate
            }
        }
    }
    
    // MARK: - 컨텍스트 저장

    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("❌ 컨텍스트 저장 실패: \(error.localizedDescription)")
        }
    }
}
