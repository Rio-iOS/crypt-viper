// Regression tests for feature behavior and ownership.
@testable import CryptViper
import XCTest

final class CryptocurrencyListPresenterTests: XCTestCase {
    func testLoadingStartsOnlyWhenViewIsReady() {
        let interactor = InteractorSpy()
        let view = ViewSpy()
        let presenter = CryptocurrencyListPresenter(view: view, interactor: interactor, router: RouterSpy())
        XCTAssertEqual(interactor.requestCount, 0)
        presenter.loadCryptocurrencies()
        XCTAssertEqual(interactor.requestCount, 1)
    }

    func testSuccessDisplaysCurrenciesAndPrices() {
        let view = ViewSpy()
        let presenter = makePresenter(view: view)
        presenter.didFetchCryptocurrencies(.success([Cryptocurrency(currency: "BTC", price: "100")]))
        XCTAssertEqual(view.cryptocurrencies?.first?.currency, "BTC")
        XCTAssertEqual(view.cryptocurrencies?.first?.price, "100")
        XCTAssertNil(view.errorMessage)
    }

    func testEmptyResponseIsForwardedToTheView() {
        let view = ViewSpy()
        makePresenter(view: view).didFetchCryptocurrencies(.success([]))
        XCTAssertEqual(view.cryptocurrencies?.count, 0)
        XCTAssertNil(view.errorMessage)
    }

    func testFailureDisplaysAnError() {
        let view = ViewSpy()
        makePresenter(view: view).didFetchCryptocurrencies(.failure(URLError(.notConnectedToInternet)))
        XCTAssertNotNil(view.errorMessage)
        XCTAssertNil(view.cryptocurrencies)
    }

    func testSelectionIsForwardedToRouter() {
        let view = ViewSpy()
        let router = RouterSpy()
        let presenter = CryptocurrencyListPresenter(view: view, interactor: InteractorSpy(), router: router)
        let quote = Cryptocurrency(currency: "BTC", price: "100")
        presenter.didSelect(quote)
        XCTAssertEqual(router.selectedCryptocurrency, quote)
    }

    func testPresenterDoesNotRetainViewAndAcceptsLateResults() {
        var view: ViewSpy? = ViewSpy()
        weak var reference = view
        let presenter = makePresenter(view: view!)
        view = nil
        XCTAssertNil(reference)
        presenter.didFetchCryptocurrencies(.success([]))
    }

    func testInteractorDoesNotRetainOutput() {
        let interactor = CryptocurrencyListInteractor()
        var output: OutputSpy? = OutputSpy { _ in }
        weak var reference = output
        interactor.output = output
        output = nil
        XCTAssertNil(reference)
        XCTAssertNil(interactor.output)
    }

    func testAssemblyReleasesViewController() {
        weak var reference: UIViewController?
        autoreleasepool {
            let viewController = CryptocurrencyListModule.makeViewController()
            reference = viewController
        }
        XCTAssertNil(reference)
    }

    func testViewPresenterInteractorAndRouterAreReleasedTogether() {
        weak var viewReference: CryptocurrencyListViewController?
        weak var presenterReference: CryptocurrencyListPresenter?
        weak var interactorReference: CryptocurrencyListInteractor?
        weak var routerReference: CryptocurrencyListRouter?
        autoreleasepool {
            let view = CryptocurrencyListViewController()
            let interactor = CryptocurrencyListInteractor()
            let router = CryptocurrencyListRouter(viewController: view)
            let presenter = CryptocurrencyListPresenter(view: view, interactor: interactor, router: router)
            view.configure(presenter: presenter)
            interactor.output = presenter
            viewReference = view
            presenterReference = presenter
            interactorReference = interactor
            routerReference = router
        }
        XCTAssertNil(viewReference)
        XCTAssertNil(presenterReference)
        XCTAssertNil(interactorReference)
        XCTAssertNil(routerReference)
    }

    private func makePresenter(view: ViewSpy) -> CryptocurrencyListPresenter {
        CryptocurrencyListPresenter(view: view, interactor: InteractorSpy(), router: RouterSpy())
    }
}

final class CryptocurrencyListInteractorTests: XCTestCase {
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CryptoURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        session = nil
        super.tearDown()
    }

    func testSuccessfulResponseIsDecodedOnMainThread() {
        load(path: "success") { result in
            XCTAssertTrue(Thread.isMainThread)
            guard case let .success(cryptos) = result else { return XCTFail("Expected success") }
            XCTAssertEqual(cryptos.map(\.currency), ["BTC", "ETH"])
            XCTAssertEqual(cryptos.map(\.price), ["100", "50"])
        }
    }

    func testHTTPErrorIsNotTreatedAsSuccessfulJSON() {
        load(path: "server-error") { result in
            guard case let .failure(error) = result else { return XCTFail("Expected HTTP error") }
            XCTAssertEqual(error as? NetworkError, .httpStatus(503))
        }
    }

    func testMalformedJSONIsReported() {
        load(path: "malformed") { result in
            guard case let .failure(error) = result else { return XCTFail("Expected decoding error") }
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testOfflineErrorIsPreserved() {
        load(path: "offline") { result in
            guard case let .failure(error) = result else { return XCTFail("Expected transport error") }
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testEmptyListSucceeds() {
        load(path: "empty") { result in
            guard case let .success(cryptos) = result else { return XCTFail("Expected empty success") }
            XCTAssertTrue(cryptos.isEmpty)
        }
    }

    private func load(path: String, assertions: @escaping (Result<[Cryptocurrency], Error>) -> Void) {
        let completed = expectation(description: "Download completes")
        let presenter = OutputSpy { result in
            assertions(result)
            completed.fulfill()
        }
        let interactor = CryptocurrencyListInteractor(session: session, endpoint: URL(string: "https://example.invalid/" + path)!)
        interactor.output = presenter
        interactor.fetchCryptocurrencies()
        withExtendedLifetime((interactor, presenter)) {
            wait(for: [completed], timeout: 3)
        }
    }
}

private final class InteractorSpy: CryptocurrencyListInteracting {
    private(set) var requestCount = 0
    private(set) var cancellationCount = 0
    func fetchCryptocurrencies() { requestCount += 1 }
    func cancelFetching() { cancellationCount += 1 }
}

private final class ViewSpy: CryptocurrencyListView {
    private(set) var cryptocurrencies: [Cryptocurrency]?
    private(set) var errorMessage: String?
    func showLoading() {}
    func show(_ cryptocurrencies: [Cryptocurrency]) { self.cryptocurrencies = cryptocurrencies }
    func showError(message: String) { errorMessage = message }
}

private final class RouterSpy: CryptocurrencyListRouting {
    private(set) var selectedCryptocurrency: Cryptocurrency?
    func showDetails(for cryptocurrency: Cryptocurrency) { selectedCryptocurrency = cryptocurrency }
}

private final class OutputSpy: CryptocurrencyListInteractorOutput {
    private let completion: (Result<[Cryptocurrency], Error>) -> Void
    init(completion: @escaping (Result<[Cryptocurrency], Error>) -> Void) { self.completion = completion }
    func didFetchCryptocurrencies(_ result: Result<[Cryptocurrency], Error>) { completion(result) }
}

private final class CryptoURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "example.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let url = request.url else { return }
        if url.path == "/offline" {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let status = url.path == "/server-error" ? 503 : 200
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        let body: String
        switch url.path {
        case "/malformed": body = "not-json"
        case "/empty": body = "[]"
        default: body = #"[{"currency":"BTC","price":"100"},{"currency":"ETH","price":"50"}]"#
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class CryptocurrencyListViewTests: XCTestCase {
    @MainActor func testErrorRetryLoadingSuccessAndSelectionUseTheActualView() throws {
        let view = CryptocurrencyListViewController()
        let interactor = InteractorSpy()
        let router = RouterSpy()
        let presenter = CryptocurrencyListPresenter(view: view, interactor: interactor, router: router)
        view.configure(presenter: presenter)
        view.loadViewIfNeeded()
        view.viewWillAppear(false)
        let button = try XCTUnwrap(view.view.subviews.compactMap { $0 as? UIButton }.first)
        let table = try XCTUnwrap(view.view.subviews.compactMap { $0 as? UITableView }.first)
        XCTAssertEqual(interactor.requestCount, 1)
        XCTAssertTrue(button.isHidden)
        presenter.didFetchCryptocurrencies(.failure(URLError(.timedOut)))
        XCTAssertFalse(button.isHidden)
        XCTAssertTrue(table.isHidden)
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(interactor.requestCount, 2)
        XCTAssertTrue(button.isHidden)
        let quote = Cryptocurrency(currency: "BTC", price: "100")
        presenter.didFetchCryptocurrencies(.success([quote]))
        XCTAssertFalse(table.isHidden)
        XCTAssertEqual(table.dataSource?.tableView(table, numberOfRowsInSection: 0), 1)
        let cell = try XCTUnwrap(table.dataSource?.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)))
        let content = try XCTUnwrap(cell.contentConfiguration as? UIListContentConfiguration)
        XCTAssertEqual(content.text, "BTC")
        XCTAssertEqual(content.secondaryText, "100")
        table.delegate?.tableView?(table, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(router.selectedCryptocurrency, quote)
        view.viewWillDisappear(false)
        XCTAssertEqual(interactor.cancellationCount, 1)
    }

    @MainActor func testEmptyStateCanRetryWithoutShowingStaleRows() throws {
        let view = CryptocurrencyListViewController()
        let interactor = InteractorSpy()
        view.configure(presenter: CryptocurrencyListPresenter(view: view, interactor: interactor, router: RouterSpy()))
        view.loadViewIfNeeded()
        view.show([Cryptocurrency(currency: "BTC", price: "100")])
        view.show([])
        let table = try XCTUnwrap(view.view.subviews.compactMap { $0 as? UITableView }.first)
        let button = try XCTUnwrap(view.view.subviews.compactMap { $0 as? UIButton }.first)
        XCTAssertEqual(table.dataSource?.tableView(table, numberOfRowsInSection: 0), 0)
        XCTAssertTrue(table.isHidden)
        XCTAssertFalse(button.isHidden)
    }
}
