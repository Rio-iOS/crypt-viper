import Foundation

/// 通貨一覧の取得を開始するための入力境界。
protocol CryptocurrencyListInteracting: AnyObject {
    func fetchCryptocurrencies()
}

/// 取得結果を受け取る出力境界。標準Interactorはメインキューから通知します。
protocol CryptocurrencyListInteractorOutput: AnyObject {
    func didFetchCryptocurrencies(_ result: Result<[Cryptocurrency], Error>)
}

enum NetworkError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case emptyData
}

/// 同時に1件のダウンロードを保持し、破棄時にキャンセルするInteractor。
final class CryptocurrencyListInteractor: CryptocurrencyListInteracting {
    weak var output: CryptocurrencyListInteractorOutput?

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

    /// サンプルJSONを取得し、デコード結果を`output`へ通知します。
    ///
    /// 通信中の再呼び出しは無視します。空の配列は成功として扱います。
    /// Interactorが解放された場合は結果を通知しません。
    /// - Precondition: メインスレッドから呼び出してください。
    func fetchCryptocurrencies() {
        // Ignore repeated requests while a download is in flight.
        guard task == nil else { return }
        task = session.dataTask(with: endpoint) { [weak self] data, response, error in
            let result: Result<[Cryptocurrency], Error> = Result {
                if let error = error { throw error }
                guard let response = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                guard (200 ..< 300).contains(response.statusCode) else {
                    throw NetworkError.httpStatus(response.statusCode)
                }
                guard let data = data else { throw NetworkError.emptyData }
                return try JSONDecoder().decode([Cryptocurrency].self, from: data)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.task = nil
                self.output?.didFetchCryptocurrencies(result)
            }
        }
        task?.resume()
    }
}
