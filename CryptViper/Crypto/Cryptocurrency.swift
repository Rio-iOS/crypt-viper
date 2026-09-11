// A cryptocurrency quote returned by the sample service.
import Foundation

struct Cryptocurrency: Decodable, Equatable {
    let currency: String
    let price: String
}
