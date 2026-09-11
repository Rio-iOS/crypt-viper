//
//  CryptoTests.swift
//  CryptViperTests
//
//  Regression tests for VIPER ownership, loading order, and HTTP failures.
//

@testable import CryptViper
import XCTest

final class CryptoPresenterTests: XCTestCase {
    func testLoadingStartsOnlyWhenViewIsReady() {
        let presenter = CryptoPresenter()
        let interactor = InteractorSpy()
        presenter.interactor = interactor
        XCTAssertEqual(interactor.requests, 0)
        presenter.viewDidLoad()
        XCTAssertEqual(interactor.requests, 1)
    }

    func testSuccessDisplaysCurrenciesAndPrices() {
        let view = ViewSpy()
        let presenter = CryptoPresenter()
        presenter.view = view
        presenter.interactorDidDownloadCryptos(result: .success([Crypto(currency: "BTC", price: "100")]))
        XCTAssertEqual(view.cryptos?.first?.currency, "BTC")
        XCTAssertEqual(view.cryptos?.first?.price, "100")
        XCTAssertNil(view.error)
    }

    func testEmptyResponseIsForwardedToTheView() {
        let view = ViewSpy()
        let presenter = CryptoPresenter()
        presenter.view = view
        presenter.interactorDidDownloadCryptos(result: .success([]))
        XCTAssertEqual(view.cryptos?.count, 0)
        XCTAssertNil(view.error)
    }

    func testFailureDisplaysErrorInsteadOfResults() {
        let view = ViewSpy()
        let presenter = CryptoPresenter()
        presenter.view = view
        presenter.interactorDidDownloadCryptos(result: .failure(URLError(.notConnectedToInternet)))
        XCTAssertNotNil(view.error)
        XCTAssertNil(view.cryptos)
    }

    func testPresenterDoesNotRetainView() {
        let presenter = CryptoPresenter()
        var view: ViewSpy? = ViewSpy()
        weak var reference = view
        view?.presenter = presenter
        presenter.view = view
        view = nil
        XCTAssertNil(reference)
        XCTAssertNil(presenter.view)
    }

    func testInteractorDoesNotRetainPresenter() {
        let interactor = CryptoInteractor()
        var presenter: CryptoPresenter? = CryptoPresenter()
        weak var reference = presenter
        presenter?.interactor = interactor
        interactor.presenter = presenter
        presenter = nil
        XCTAssertNil(reference)
        XCTAssertNil(interactor.presenter)
    }

    func testRouterDoesNotFormOwnershipCycle() {
        var router: AnyRouter? = CryptoRouter.startExecution()
        weak var view = router?.entry
        XCTAssertNotNil(view)
        router = nil
        XCTAssertNil(view)
    }
}

final class CryptoInteractorTests: XCTestCase {
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

    private func load(path: String, assertions: @escaping (Result<[Crypto], Error>) -> Void) {
        let completed = expectation(description: "Download completes")
        let presenter = PresenterSpy { result in
            assertions(result)
            completed.fulfill()
        }
        let interactor = CryptoInteractor(session: session, endpoint: URL(string: "https://example.invalid/" + path)!)
        interactor.presenter = presenter
        interactor.downloadCryptos()
        withExtendedLifetime((interactor, presenter)) {
            wait(for: [completed], timeout: 3)
        }
    }
}

private final class InteractorSpy: AnyInteractor {
    weak var presenter: AnyPresenter?
    var requests = 0
    func downloadCryptos() { requests += 1 }
}

private final class ViewSpy: AnyView {
    var presenter: AnyPresenter?
    var cryptos: [Crypto]?
    var error: String?
    func update(with cryptos: [Crypto]) { self.cryptos = cryptos }
    func update(with error: String) { self.error = error }
}

private final class PresenterSpy: AnyPresenter {
    weak var router: AnyRouter?
    var interactor: AnyInteractor?
    weak var view: AnyView?
    let completion: (Result<[Crypto], Error>) -> Void
    init(completion: @escaping (Result<[Crypto], Error>) -> Void) { self.completion = completion }
    func viewDidLoad() {}
    func interactorDidDownloadCryptos(result: Result<[Crypto], Error>) { completion(result) }
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
