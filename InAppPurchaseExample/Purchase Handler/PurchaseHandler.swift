//
//  PurchaseHandler.swift
//  HOP
//
//  Created by Mayank Barnwal on 19/06/21.
//

import UIKit
import StoreKit
import AVFAudio



class PurchaseHandler: NSObject{
    
    enum PurchaseHandlerError: Error {
        case noProductIDsFound
        case noProductsFound
        case paymentWasCancelled
        case productRequestFailed
        case productNotFound
        case noPurchaseToRestore
        case purchaseExpired
        case somethingWentWrong
    }
    
    var productArray:[String] = ["com.synch.InAppPurchaseExample.10coins"]
    
    var productsRequest:SKProductsRequest!
    
    static let shared = PurchaseHandler()
    
    var onReceiveProductsHandler: ((Result<[SKProduct], PurchaseHandlerError>) -> Void)?
    
    var onBuyProductHandler: ((Result<Bool, Error>) -> Void)?
    
    var onRestoreProductHandler: ((Result<Bool, Error>) -> Void)?
    
    var totalRestoredPurchases = 0
    
    var products:[SKProduct] = []
    
    private override init() {
        super.init()
    
    }
    
    fileprivate func getProductIDs() -> [String]? {
        return productArray
    }
    
    func getProducts(withHandler productsReceiveHandler: @escaping (_ result: Result<[SKProduct], PurchaseHandlerError>) -> Void) {
        
        onReceiveProductsHandler = productsReceiveHandler
        
        guard let productIDs = getProductIDs() else {
            productsReceiveHandler(.failure(.noProductIDsFound))
            return
        }
    
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    func startObserving() {
        SKPaymentQueue.default().add(self)
    }
    
    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func buy(productId: String, withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        
        var productToPurchase:SKProduct!
        
        onBuyProductHandler = handler
        
        products.forEach { product in
            if product.productIdentifier == productId{
                productToPurchase = product
            }
        }
        if (productToPurchase != nil){
            let payment = SKPayment(product: productToPurchase)
            SKPaymentQueue.default().add(payment)
        }
        else{
            onBuyProductHandler?(.failure(PurchaseHandlerError.productNotFound))
        }
    }
    
    func restorePurchases(withHandler handler: @escaping ((_ result: Result<Bool, Error>) -> Void)) {
        onRestoreProductHandler = handler
        totalRestoredPurchases = 0
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension PurchaseHandler:SKPaymentTransactionObserver{
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transaction) in
            switch transaction.transactionState {
            case .purchased:
                onBuyProductHandler?(.success(true))
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                totalRestoredPurchases += 1
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error as? SKError {
                    if error.code != .paymentCancelled {
                        onBuyProductHandler?(.failure(error))
                    } else {
                        onBuyProductHandler?(.failure(PurchaseHandlerError.paymentWasCancelled))
                    }
                    print("IAP Error:", error.localizedDescription)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .deferred, .purchasing: break
            @unknown default: break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        onRestoreProductHandler?(.failure(PurchaseHandlerError.noPurchaseToRestore))
    }
    
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let error = error as? SKError {
            if error.code != .paymentCancelled {
                print("IAP Restore Error:", error.localizedDescription)
                onBuyProductHandler?(.failure(error))
            } else {
                onBuyProductHandler?(.failure(PurchaseHandlerError.paymentWasCancelled))
            }
        }
    }
}

extension PurchaseHandler: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        if products.count > 0 {
            onReceiveProductsHandler?(.success(products))
            products.forEach({ product in
                print(product.productIdentifier)
            })
            self.products = products
        } else {
            onReceiveProductsHandler?(.failure(.noProductsFound))
        }
    }
    func request(_ request: SKRequest, didFailWithError error: Error) {
        onReceiveProductsHandler?(.failure(.productRequestFailed))
    }
}

extension PurchaseHandler.PurchaseHandlerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noProductIDsFound: return "No In-App Purchase product identifiers were found."
        case .noProductsFound: return "No In-App Purchases were found."
        case .productRequestFailed: return "Unable to fetch available In-App Purchase products at the moment."
        case .paymentWasCancelled: return "In-App Purchase process was cancelled."
        case .productNotFound: return "Product not found"
        case .noPurchaseToRestore: return "No purchases to restore!"
        case .purchaseExpired: return "Your purchase is expired"
        case .somethingWentWrong: return "Something went wrong try again!!!"
        }
    }
}

extension PurchaseHandler{
    
    func getPriceOf(puchasingId:String) -> String{
        for product in products{
            if product.productIdentifier == puchasingId{
                return "\(product.priceLocale.currencySymbol ?? "$")\(product.price)"
            }
        }
        return ""
    }
}

