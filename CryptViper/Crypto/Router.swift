//
//  Router.swift
//  CryptViper
//
//  Created by 藤門莉生 on 2023/05/05.
//

import Foundation
import UIKit

/*
 Router
 - 全体を統括する（オーケストラレーションする）
 - Class, Protocolを利用
 - エントリーポイントがある
 -
 */

typealias EntryPoint = AnyView & UIViewController

protocol AnyRouter {
    var entry: EntryPoint? { get }
    static func startExecution() -> AnyRouter
}

class CryptoRouter: AnyRouter {
    var entry: EntryPoint?
    // SceneDelegateから呼ばれる
    static func startExecution() -> AnyRouter {
        let router = CryptoRouter()
        
        var view: AnyView = CryptoViewController()
        var presenter: AnyPresenter = CryptoPresenter()
        var interactor: AnyInteractor = CryptoInteractor()
        
        view.presenter = presenter
        
        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor
        
        interactor.presenter = presenter
        
        router.entry = view as? EntryPoint
        
        return router
    }
}
