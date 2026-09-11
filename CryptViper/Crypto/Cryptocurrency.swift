import Foundation

/// サンプルサービスから取得した通貨名と価格。価格は元のJSONどおり文字列で保持します。
struct Cryptocurrency: Decodable, Equatable {
    let currency: String
    let price: String
}
