//
//  Interactor.swift
//  CryptViper
//
//  Network loading and response validation for the cryptocurrency sample.
//

import Foundation

protocol AnyInteractor: AnyObject {
    var presenter: AnyPresenter? { get set }
    func downloadCryptos()
}

enum NetworkError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case emptyData
}

final class CryptoInteractor: AnyInteractor {
    weak var presenter: AnyPresenter?

    private let session: URLSession
    private let endpoint: URL
    private var task: URLSessionDataTask?

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://raw.githubusercontent.com/atilsamancioglu/K21-JSONDataSet/master/crypto.json")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    deinit {
        task?.cancel()
    }

    func downloadCryptos() {
        // Ignore repeated requests while a download is in flight.
        guard task == nil else { return }
        task = session.dataTask(with: endpoint) { [weak self] data, response, error in
            let result: Result<[Crypto], Error> = Result {
                if let error = error { throw error }
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard (200 ..< 300).contains(response.statusCode) else {
                    throw NetworkError.httpStatus(response.statusCode)
                }
                guard let data = data else { throw NetworkError.emptyData }
                return try JSONDecoder().decode([Crypto].self, from: data)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.task = nil
                self.presenter?.interactorDidDownloadCryptos(result: result)
            }
        }
        task?.resume()
    }
}
