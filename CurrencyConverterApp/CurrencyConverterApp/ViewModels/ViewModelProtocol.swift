//
//  ViewModelProtocol.swift
//  CurrencyConverterApp
//
//  Created by 박주성 on 4/17/25.
//
import Foundation


protocol ViewModelProtocol {
    associatedtype Action
    associatedtype State
    
    var action: ((Action) -> Void)? { get }
    var state: State { get }
    var onStateChange: ((State) -> Void)? { get }
}
