//
//  HealthKitManager.swift
//  QuickCalories
//
//  Created by John N on 8/12/26.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var latestWeight: Double?
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let status = healthStore.authorizationStatus(for: weightType)
        DispatchQueue.main.async {
            self.isAuthorized = status == .sharingAuthorized
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        
        healthStore.requestAuthorization(toShare: nil, read: [weightType]) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchLatestWeight { _ in }
                }
                completion(success)
            }
        }
    }
    
    func fetchLatestWeight(completion: @escaping (Double?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil)
            return
        }
        
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            
            // Query weight in kilograms (internally, SettingsManager uses kilograms)
            let kgUnit = HKUnit.gramUnit(with: .kilo)
            let valueInKg = sample.quantity.doubleValue(for: kgUnit)
            
            DispatchQueue.main.async {
                self?.latestWeight = valueInKg
                // Update weight in SettingsManager automatically to keep BMR/TDEE synchronized
                if valueInKg > 0 {
                    SettingsManager.shared.userWeight = valueInKg
                    SettingsManager.shared.recalculateFromProfile()
                }
                completion(valueInKg)
            }
        }
        
        healthStore.execute(query)
    }
}
