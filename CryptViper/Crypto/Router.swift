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

protocol AnyRouter: AnyObject {
    var entry: EntryPoint? { get }
    static func startExecution() -> AnyRouter
}

final class CryptoRouter: AnyRouter {
    var entry: EntryPoint?
    // SceneDelegateから呼ばれる
    static func startExecution() -> AnyRouter {
        let router = CryptoRouter()

        let view: AnyView = CryptoViewController()
        let presenter: AnyPresenter = CryptoPresenter()
        let interactor: AnyInteractor = CryptoInteractor()

        view.presenter = presenter

        presenter.view = view
        presenter.router = router
        presenter.interactor = interactor

        interactor.presenter = presenter

        router.entry = view as? EntryPoint

        return router
    }
}
