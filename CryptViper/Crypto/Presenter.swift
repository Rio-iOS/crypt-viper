//
//  Presenter.swift
//  CryptViper
//
//  Converts loading results into view updates.
//

import Foundation

protocol AnyPresenter: AnyObject {
    var router: AnyRouter? { get set }
    var interactor: AnyInteractor? { get set }
    var view: AnyView? { get set }

    func viewDidLoad()
    func interactorDidDownloadCryptos(result: Result<[Crypto], Error>)
}

final class CryptoPresenter: AnyPresenter {
    weak var router: AnyRouter?
    var interactor: AnyInteractor?
    weak var view: AnyView?

    func viewDidLoad() {
        interactor?.downloadCryptos()
    }

    func interactorDidDownloadCryptos(result: Result<[Crypto], Error>) {
        switch result {
        case let .success(cryptos):
            view?.update(with: cryptos)
        case .failure:
            view?.update(with: "Unable to load cryptocurrencies. Please try again later.")
        }
    }
}
