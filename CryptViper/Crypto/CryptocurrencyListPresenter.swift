// Translates view events and interactor results into presentation updates.
import Foundation

protocol CryptocurrencyListPresenting: AnyObject {
    func viewDidLoad()
    func didSelect(_ cryptocurrency: Cryptocurrency)
}

final class CryptocurrencyListPresenter: CryptocurrencyListPresenting, CryptocurrencyListInteractorOutput {
    private weak var view: CryptocurrencyListView?
    private let interactor: CryptocurrencyListInteracting
    private let router: CryptocurrencyListRouting

    init(view: CryptocurrencyListView, interactor: CryptocurrencyListInteracting, router: CryptocurrencyListRouting) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        interactor.fetchCryptocurrencies()
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
