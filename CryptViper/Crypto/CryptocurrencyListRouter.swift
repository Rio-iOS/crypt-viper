import UIKit

protocol CryptocurrencyListRouting: AnyObject {
    func showDetails(for cryptocurrency: Cryptocurrency)
}

/// 一覧画面を弱参照し、選択した通貨の詳細をモーダル表示するRouter。
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

/// 一覧機能の依存関係を組み立てる入口。
enum CryptocurrencyListModule {
    /// Presenter・Interactor・Routerを接続済みの一覧画面を返します。
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
