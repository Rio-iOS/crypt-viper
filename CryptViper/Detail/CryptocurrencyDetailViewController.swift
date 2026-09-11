// Renders an immutable quote passed by the router.
import UIKit

final class CryptocurrencyDetailViewController: UIViewController {
    private let cryptocurrency: Cryptocurrency

    init(cryptocurrency: Cryptocurrency) {
        self.cryptocurrency = cryptocurrency
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("Use init(cryptocurrency:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let currencyLabel = makeLabel(text: cryptocurrency.currency)
        let priceLabel = makeLabel(text: cryptocurrency.price)
        let stackView = UIStackView(arrangedSubviews: [currencyLabel, priceLabel])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }

    private func makeLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}
