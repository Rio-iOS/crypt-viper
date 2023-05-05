//
//  Presenter.swift
//  CryptViper
//
//  Created by 藤門莉生 on 2023/05/05.
//

import Foundation

/*
 Presenter
 - Class, Protocolがある
 - Presenterから目を向け始めると良い → 全体像が見える
 - talks to interactor, router, view → 全てのコンポーネントとやりとりをする
 */

enum NetworkError: Error {
    case NetWorkFailed
    case ParsingFailed
    
}

protocol AnyPresenter {
    var router: AnyRouter? { get set }
    var interactor: AnyInteractor? { get set }
    var view: AnyView? { get set }
    
    func interactorDidDownloadCryptos(result: Result<[Crypto], Error>)
}

class CryptoPresenter: AnyPresenter {
    var router: AnyRouter?
    
    var interactor: AnyInteractor? {
        didSet {
            interactor?.downloadCryptos()
        }
    }
    
    var view: AnyView?
    
    func interactorDidDownloadCryptos(result: Result<[Crypto], Error>) {
        switch result {
        case .success(let cryptos):
            // view.update
            print("update")
            view?.update(with: cryptos)
        case .failure(_):
            // view.update error
            print("error")
            view?.update(with: "Try again later ...")
        }
    }
    
    
}
