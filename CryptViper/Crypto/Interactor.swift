//
//  Interactor.swift
//  CryptViper
//
//  Created by 藤門莉生 on 2023/05/05.
//

import Foundation

/*
 Interactor
 - Interactorにも、ClassやProtocolが準備される
 - Talsk to -> Presenter
 - 
 */

protocol AnyInteractor {
    // やりとりを行うのは、Presenterのみ
    var presenter: AnyPresenter? { get set }
    
    // データをダウンロードするためのメソッドが必要
    func downloadCryptos()
}

class CryptoInteractor: AnyInteractor {
    var presenter: AnyPresenter?
    
    func downloadCryptos() {
        guard let url = URL(string: "https://raw.githubusercontent.com/atilsamancioglu/K21-JSONDataSet/master/crypto.json") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] data, response, error in
            
            guard let data = data, error == nil else {
                self?.presenter?.interactorDidDownloadCryptos(result: .failure(NetworkError.NetWorkFailed as! Error))
                return
            }
            
            do {
                let cryptos = try JSONDecoder().decode([Crypto].self, from: data)
                self?.presenter?.interactorDidDownloadCryptos(result: .success(cryptos))
            } catch {
                self?.presenter?.interactorDidDownloadCryptos(result: .failure(NetworkError.ParsingFailed as! Error))
            }
            
        }
        
        task.resume()
        
    }
}
