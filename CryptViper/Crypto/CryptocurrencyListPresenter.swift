import Foundation

protocol CryptocurrencyListPresenting: AnyObject {
    func loadCryptocurrencies()
    func cancelLoading()
    func didSelect(_ cryptocurrency: Cryptocurrency)
}

/// 一覧の入力イベントと取得結果を、表示更新および詳細画面への遷移へ変換するPresenter。
final class CryptocurrencyListPresenter: CryptocurrencyListPresenting, CryptocurrencyListInteractorOutput {
    private weak var view: CryptocurrencyListView?
    private let interactor: CryptocurrencyListInteracting
    private let router: CryptocurrencyListRouting

    init(view: CryptocurrencyListView, interactor: CryptocurrencyListInteracting, router: CryptocurrencyListRouting) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    func loadCryptocurrencies() {
        view?.showLoading()
        interactor.fetchCryptocurrencies()
    }

    func cancelLoading() {
        interactor.cancelFetching()
    }

    func didSelect(_ cryptocurrency: Cryptocurrency) {
        router.showDetails(for: cryptocurrency)
    }

    func didFetchCryptocurrencies(_ result: Result<[Cryptocurrency], Error>) {
        switch result {
        case let .success(cryptocurrencies):
            view?.show(cryptocurrencies)
        case .failure:
            view?.showError(message: "Unable to load cryptocurrencies. Please try again later.")
        }
    }
}
