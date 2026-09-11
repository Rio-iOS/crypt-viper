// Assembles the VIPER feature and owns navigation, without retaining its view.
import UIKit

protocol CryptocurrencyListRouting: AnyObject {
    func showDetails(for cryptocurrency: Cryptocurrency)
}

final class CryptocurrencyListRouter: CryptocurrencyListRouting {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func showDetails(for cryptocurrency: Cryptocurrency) {
        let detail = CryptocurrencyDetailViewController(cryptocurrency: cryptocurrency)
        viewController?.present(detail, animated: true)
    }
}

enum CryptocurrencyListModule {
    static func makeViewController() -> UIViewController {
        let viewController = CryptocurrencyListViewController()
        let interactor = CryptocurrencyListInteractor()
        let router = CryptocurrencyListRouter(viewController: viewController)
        let presenter = CryptocurrencyListPresenter(view: viewController, interactor: interactor, router: router)
        viewController.configure(presenter: presenter)
        interactor.output = presenter
        return viewController
    }
}
