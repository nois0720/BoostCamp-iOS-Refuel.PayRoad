
//  AddCurrencyViewController.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 8..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

import RealmSwift

class CurrencyEditorViewController: UIViewController {
    
    let realm = try! Realm()
    
    var travel: Travel!
    var originCurrency: Currency!
    var standardCurrency: Currency!
    var editedCurrency: Currency!
    
    var editorMode: EditorMode = .new
    var isUpdating = false
    
    @IBOutlet weak var currencySelectButton: UIButton!
    @IBOutlet weak var rateTextField: UITextField!
    @IBOutlet weak var lastUpdateDateLabel: UILabel!
    @IBOutlet weak var budgetTextField: UITextField!
    @IBOutlet weak var updateRateButton: UIButton!
    @IBOutlet weak var deleteCurrencyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        self.standardCurrency = travel.currencies.first!
        rateTextField.delegate = self
        budgetTextField.delegate = self
        rateTextField.addTarget(self, action: #selector(editingChangedRate(_:)), for: .editingChanged)
        budgetTextField.addTarget(self, action: #selector(editingChangedBudget(_:)), for: .editingChanged)
        
        adjustViewMode()
        
        currencySelectButton.cornerRound(cornerOptions: [.bottomLeft, .topLeft], cornerRadius: 5)
        rateTextField.borderStyle = .roundedRect
        
        rateTextField.layer.cornerRadius = 5
        rateTextField.layer.borderColor = ColorStore.unselectGray.cgColor
        rateTextField.layer.borderWidth = 0.5
        
        deleteCurrencyButton.cornerRound(cornerOptions: [.allCorners], cornerRadius: 5)
    }
    
    func editingChangedRate(_ sender: UITextField) {
        guard let rateText = sender.text,
            let rate = Double(rateText)
        else {
            return
        }
        
        editedCurrency.rate = rate
    }
    
    func editingChangedBudget(_ sender: UITextField) {
        guard let budgetText = sender.text else { return }
        
        guard !budgetText.isEmpty else {
            editedCurrency.budget = 0
            return
        }
        
        guard let budget = Double(budgetText) else { return }
        
        editedCurrency.budget = budget
    }
    
    func checkIsExistInputField() -> Bool {
        guard !(editedCurrency.code == "") else {
            UIAlertController.oneButtonAlert(target: self, title: "저장 실패", message: "화폐를 선택해주세요.")
            return false
        }
        
        guard !(budgetTextField.text!.isEmpty) else {
            //UIAlertController.oneButtonAlert(target: self, title: "저장 실패", message: "예산을 입력해주세요.")
            editedCurrency.budget = 0.0
            return true
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectCurrencyCode" {
            let currencySelectTableViewController = segue.destination as! CurrencySelectTableViewController
            currencySelectTableViewController.delegate = self
            currencySelectTableViewController.travel = travel
        }
    }
    
    //MARK: Actions
    @IBAction func backgroundDidTap(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func cancelButtonDidTap(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func updateRateButtonDidTap(_ sender: Any) {
        guard let code = currencySelectButton.title(for: .normal) else {
            return
        }
        
        currencySelectResponse(code: code)
    }
    
    @IBAction func deleteButtonDidTap(_ sender: Any) {
        
        let realm = try! Realm()
        let result = realm.objects(Transaction.self).filter("currency.id == '\(originCurrency.id)'")
        
        let alert = UIAlertController(title: "\(originCurrency.code) 통화 삭제",
                                    message: "해당 통화를 삭제하면, 현재 이 통화를 사용하고 있는 \(result.count)개의 지출 내역이 함께 삭제됩니다.\n정말 삭제하시겠습니까?",
                                    preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [unowned self] (alertAction) in
            result.forEach({ (transaction) in
                Object.cascadingDelete(realm: realm, object: transaction)
            })
            
            try! realm.write {
                realm.delete(self.originCurrency)
            }
            
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension CurrencyEditorViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField === rateTextField {
            rateTextField.text = String(editedCurrency.rate)
        } else if textField === budgetTextField {
            let budget = editedCurrency.budget.nonZeroString(maxDecimalPlace: 2, option: .default)
            textField.text = budget == "0" ? "" : budget
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === rateTextField {
            let standard = travel.currencies.first!.code
            let code = currencySelectButton.title(for: .normal)!
            textField.text = "1 \(code)당, \(editedCurrency.rate) \(standard)"
            
        } else if textField === budgetTextField {
            textField.text = editedCurrency.budget.nonZeroString(maxDecimalPlace: 2, option: .seperator)
        }
        
        textField.endEditing(true)
    }
}

extension CurrencyEditorViewController: CurrencySelectTableViewControllerDelegate {
    func currencySelectResponse(code: String) {
        isUpdating = true
        
        currencySelectButton.setTitle(code, for: .normal)
        let standard = travel.currencies.first!.code
        
        updateRateButton.isEnabled = false
        rotateView(targetView: updateRateButton)
        
        exchangeRateFromAPI(standard: standard, compare: code) { [unowned self] rate in
            OperationQueue.main.addOperation {
    
                self.rateTextField.isEnabled = true
                self.updateRateButton.isEnabled = true
                self.rateTextField.textColor = self.rateTextField.textColor?.withAlphaComponent(0.6)
                
                self.editedCurrency.code = code
                
                if let rate = rate {
                    self.editedCurrency.rate = rate
                    
                    let updatedAt = Date()
                    self.lastUpdateDateLabel.text = "마지막 업데이트 : \(DateFormatter.string(for: updatedAt))"
                    self.editedCurrency.lastUpdateDate = updatedAt
                } else {
                    self.editedCurrency.rate = 0.0
                    
                    UIAlertController.oneButtonAlert(target: self, title: "환율 가져오기 실패", message: "네트워크 오류로 환율 정보를 가져오지 못했습니다. 직접 환율을 입력해주세요.")
                }
                
                self.rateTextField.text = "1 \(code)당, \(self.editedCurrency.rate) \(standard)"
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.isUpdating = false
            }
        }
    }
    
    func rotateView(targetView: UIView) {
        UIView.animate(withDuration: 0.03, delay: 0.0, options: .curveLinear, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat.pi / 10)
        }) { [unowned self] (finished) in
            guard self.isUpdating == true else {
                return
            }
            
            self.rotateView(targetView: targetView)
        }
    }
    
    func exchangeRateFromAPI(standard: String, compare: String, completion: @escaping (Double?) -> Void) {
        
        let query = "\(compare)_\(standard)"
        let url = URL(string: "https://free.currencyconverterapi.com/api/v3/convert?q=\(query)&compact=ultra")!
        
        let request = URLRequest(url: url, timeoutInterval: 10.0)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let jsonData = try? JSONSerialization.jsonObject(with: data!, options: [])
            
            var exchangeRate: Double? = nil
            
            if let jsonObject = jsonData as? [String: Double],
                let val = jsonObject[query] {
                exchangeRate = val
            }
            
            completion(exchangeRate)
        }
        task.resume()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
}

extension CurrencyEditorViewController {
    fileprivate func adjustViewMode() {
        editedCurrency = Currency()
        
        if originCurrency != nil {
            editedCurrency.code = originCurrency.code
            editedCurrency.rate = originCurrency.rate
            editedCurrency.budget = originCurrency.budget
            editedCurrency.lastUpdateDate = originCurrency.lastUpdateDate
        }
        
        let origImage = #imageLiteral(resourceName: "Icon_Refresh")
        let tintedImage = origImage.withRenderingMode(.alwaysTemplate)
        updateRateButton.setImage(tintedImage, for: .normal)
        updateRateButton.tintColor = ColorStore.mainSkyBlue
        
        let barButtonItem: UIBarButtonItem = .init(image: #imageLiteral(resourceName: "Icon_Check"), style: .plain, target: self, action: nil)
        switch self.editorMode {
        case .new:
            barButtonItem.action = #selector(saveButtonDidTap)
            rateTextField.isEnabled = false
            updateRateButton.isEnabled = false
            lastUpdateDateLabel.text = "마지막 업데이트 : 없음"
            deleteCurrencyButton.isHidden = true
        case .edit:
            barButtonItem.action = #selector(editButtonDidTap)
            navigationItem.title = "예산 수정"
            
            currencySelectButton.setTitle(originCurrency.code, for: .normal)
            currencySelectButton.backgroundColor = UIColor.gray
            currencySelectButton.isEnabled = false
            
            budgetTextField.text = originCurrency.budget.nonZeroString(maxDecimalPlace: 2, option: .seperator)
            
            if originCurrency.code == standardCurrency.code {
                rateTextField.text = "기준 통화"
                rateTextField.isEnabled = false
                updateRateButton.isEnabled = false
                lastUpdateDateLabel.text = "기준 통화는 환율 업데이트가 되지 않습니다."
                deleteCurrencyButton.isHidden = true
            } else {
                rateTextField.text = "1 \(originCurrency.code)당 \(originCurrency.rate)\(standardCurrency.code)"
                lastUpdateDateLabel.text = "마지막 업데이트 : \(DateFormatter.string(for: originCurrency.lastUpdateDate))"
            }
        }
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    func saveButtonDidTap() {
        if checkIsExistInputField() {
            let currency = Currency()
            currency.id = travel.id + "-" + editedCurrency.code
            currency.code = editedCurrency.code
            currency.rate = editedCurrency.rate
            currency.budget = editedCurrency.budget
            currency.lastUpdateDate = editedCurrency.lastUpdateDate
            do {
                try realm.write {
                    travel.currencies.append(currency)
                    print("Currency 추가")
                }
            } catch {
                print(error)
            }
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func editButtonDidTap() {
        if checkIsExistInputField() {
            do {
                try realm.write {
                    originCurrency.rate = editedCurrency.rate
                    originCurrency.budget = editedCurrency.budget
                    originCurrency.lastUpdateDate = editedCurrency.lastUpdateDate
                    print("통화 수정")
                }
            } catch {
                print(error)
            }
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func deleteCurrencyButtonDidTap() {
        defer {
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
        }
        
        try! realm.write {
            self.realm.delete(originCurrency)
        }
    }
}

