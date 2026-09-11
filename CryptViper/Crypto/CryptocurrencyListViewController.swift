import UIKit

protocol CryptocurrencyListView: AnyObject {
    func showLoading()
    func show(_ cryptocurrencies: [Cryptocurrency])
    func showError(message: String)
}

/// 一覧・空状態・エラーを表示し、操作をPresenterへ通知する画面。
final class CryptocurrencyListViewController: UIViewController, CryptocurrencyListView {
    private var presenter: CryptocurrencyListPresenting?
    private var cryptocurrencies: [Cryptocurrency] = []
    private let tableView = UITableView()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    /// Viewをロードする前にPresenterを接続します。
    ///
    /// - Precondition: `isViewLoaded`が`false`であること。
    func configure(presenter: CryptocurrencyListPresenting) {
        precondition(!isViewLoaded, "Configure the presenter before loading the view")
        self.presenter = presenter
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cryptocurrency")
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        messageLabel.text = "Downloading…"
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .label
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        for subview in [tableView, messageLabel, retryButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.loadCryptocurrencies()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter?.cancelLoading()
    }

    @objc private func retryTapped() {
        presenter?.loadCryptocurrencies()
    }

    func showLoading() {
        retryButton.isHidden = true
        tableView.isHidden = true
        messageLabel.text = "Downloading…"
        messageLabel.isHidden = false
    }

    func show(_ cryptocurrencies: [Cryptocurrency]) {
        self.cryptocurrencies = cryptocurrencies
        retryButton.isHidden = !cryptocurrencies.isEmpty
        messageLabel.text = "No cryptocurrencies available."
        messageLabel.isHidden = !cryptocurrencies.isEmpty
        tableView.isHidden = cryptocurrencies.isEmpty
        tableView.reloadData()
    }

    func showError(message: String) {
        retryButton.isHidden = false
        cryptocurrencies = []
        tableView.reloadData()
        tableView.isHidden = true
        messageLabel.text = message
        messageLabel.isHidden = false
    }
}

extension CryptocurrencyListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelect(cryptocurrencies[indexPath.row])
    }
}

extension CryptocurrencyListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        cryptocurrencies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cryptocurrency", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = cryptocurrencies[indexPath.row].currency
        content.secondaryText = cryptocurrencies[indexPath.row].price
        cell.contentConfiguration = content
        return cell
    }
}
