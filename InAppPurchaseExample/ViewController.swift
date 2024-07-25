//
//  ViewController.swift
//  InAppPurchaseExample
//
//  Created by Mayank Barnwal on 25/07/24.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var coinLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorView.isHidden = true
        
        PurchaseHandler.shared.getProducts { result in
            DispatchQueue.main.async {[weak self] in
                if let self {
                    priceLabel.text = PurchaseHandler.shared.getPriceOf(puchasingId: PurchaseHandler.shared.productArray[0])
                }
            }
        }
    }
    
    @IBAction func onBuyCoinBtn(_ sender: Any) {
        if PurchaseHandler.shared.canMakePayments(){
            activityIndicatorView.isHidden = false
            activityIndicatorView.startAnimating()
            
            PurchaseHandler.shared.buy(productId: PurchaseHandler.shared.productArray[0]) {[weak self] result in
                guard let self else{
                    return
                }
                activityIndicatorView.stopAnimating()
                activityIndicatorView.isHidden = true
                switch result {
                case .success(_):
                    coinLabel.text = "\((Int(coinLabel.text!) ?? 0) + 10)"
                case .failure(let failure):
                    makeAlert(failure.localizedDescription)
                }
            }
        }
        else{
            makeAlert("You can't by this product at this time")
        }
    }
}

extension UIViewController{
    public func makeAlert(_ message: String?, _ title: String? = "", isErrorMessage:Bool? = false) {
        
        var appName = title
        
        if title == "" || title == nil{
            appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        }
        
        let alert = UIAlertController(title: appName, message: message, preferredStyle: .alert)
        
        let okAlert = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler:nil)
        
        alert.addAction(okAlert)
        
        present(alert, animated: true, completion: nil)
    }
}

