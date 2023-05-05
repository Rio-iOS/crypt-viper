//
//  Entity.swift
//  CryptViper
//
//  Created by 藤門莉生 on 2023/05/05.
//

import Foundation

/*
 Entity
 - Struct
 - モデルである
 -
 */

struct Crypto: Decodable {
    let currency: String
    let price: String
}
