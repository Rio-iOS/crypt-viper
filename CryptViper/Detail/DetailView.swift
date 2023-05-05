//
//  DetailView.swift
//  CryptViper
//
//  Created by 藤門莉生 on 2023/05/05.
//

import Foundation
import UIKit

class DetailViewController: UIViewController {
    
    var currency: String = ""
    var price = ""
    
    private let currencyLabel: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = "Currency Label"
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.isHidden = false
        label.text = "Price Label"
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
        view.addSubview(currencyLabel)
        view.addSubview(priceLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currencyLabel.frame = CGRect(x: view.frame.width / 2 - 100, y: view.frame.height / 2 - 25, width: 200, height: 50)
        priceLabel.frame = CGRect(x: view.frame.width / 2 - 100, y: view.frame.height / 2 + 50, width: 200, height: 50)
       
        currencyLabel.text = currency
        priceLabel.text = price
        
        currencyLabel.isHidden = false
        priceLabel.isHidden = false
    }
}
