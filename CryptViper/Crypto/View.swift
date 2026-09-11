//
//  View.swift
//  CryptViper
//
//  Created by 藤門莉生 on 2023/05/05.
//

import Foundation
import UIKit

/*
 View

 - Viewは、Presenterとやりとりをする
 - Talks to -> Presenter
 - Viewの内部には、ClassやProtocolがある
 -
 */

protocol AnyView: AnyObject {
    var presenter: AnyPresenter? { get set }
    func update(with cryptos: [Crypto])
    func update(with error: String)
}

class CryptoViewController: UIViewController, AnyView {
    var presenter: AnyPresenter?

    var cryptos: [Crypto] = []

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        // 初期のデータが存在しない場合には、TableViewを見せない
        tableView.isHidden = true

        return tableView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = "Downloading ..."
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        view.addSubview(messageLabel)

        tableView.delegate = self
        tableView.dataSource = self
        presenter?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        messageLabel.frame = CGRect(x: view.frame.width / 2 - 100, y: view.frame.height / 2 - 25, width: 200, height: 100)
    }

    func update(with cryptos: [Crypto]) {
        DispatchQueue.main.async {
            self.cryptos = cryptos
            self.messageLabel.text = "No cryptocurrencies available."
            self.messageLabel.isHidden = !cryptos.isEmpty
            self.tableView.reloadData()
            self.tableView.isHidden = cryptos.isEmpty
        }
    }

    func update(with error: String) {
        DispatchQueue.main.async {
            self.cryptos = []
            self.tableView.isHidden = true
            self.messageLabel.text = error
            self.messageLabel.isHidden = false
        }
    }
}

extension CryptoViewController: UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return cryptos.count
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nextViewController = DetailViewController()
        nextViewController.currency = cryptos[indexPath.row].currency
        nextViewController.price = cryptos[indexPath.row].price

        present(nextViewController, animated: true)
    }
}

extension CryptoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = cryptos[indexPath.row].currency
        content.secondaryText = cryptos[indexPath.row].price
        cell.contentConfiguration = content
        cell.backgroundColor = .systemBackground

        return cell
    }
}
