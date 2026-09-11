// Displays list state and forwards user events to the presenter.
import UIKit

protocol CryptocurrencyListView: AnyObject {
    func show(_ cryptocurrencies: [Cryptocurrency])
    func showError(message: String)
}

final class CryptocurrencyListViewController: UIViewController, CryptocurrencyListView {
    private var presenter: CryptocurrencyListPresenting?
    private var cryptocurrencies: [Cryptocurrency] = []
    private let tableView = UITableView()
    private let messageLabel = UILabel()

    /// Connects the presenter before the view is loaded.
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
        for subview in [tableView, messageLabel] {
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
        ])
        presenter?.viewDidLoad()
    }

    func show(_ cryptocurrencies: [Cryptocurrency]) {
        self.cryptocurrencies = cryptocurrencies
        messageLabel.text = "No cryptocurrencies available."
        messageLabel.isHidden = !cryptocurrencies.isEmpty
        tableView.isHidden = cryptocurrencies.isEmpty
        tableView.reloadData()
    }

    func showError(message: String) {
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
