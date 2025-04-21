//
//  CoreDataStack.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/19/25.
//

import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    private let container: NSPersistentContainer

    let backgroundContext: NSManagedObjectContext

    private init() {
        container = NSPersistentContainer(name: "CoreDataModel")

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data 로딩 실패: \(error), \(error.userInfo)")
            }
        }

        backgroundContext = container.newBackgroundContext()
    }
}
