//
//  AddTransactionViewController.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 8..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit
import RealmSwift

class AddTransactionViewController: UIViewController {
    
    lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    
    let realm = try! Realm()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var currencyTextField: UITextField!
    
    var travel: Travel!
    var currency: Currency!

    override func viewDidLoad() {
        super.viewDidLoad()

        //TODO: PickerView 없애면서 들어내야될 코드
        if travel.currencies.count == 1 {
            currency = travel.currencies.first!
            currencyTextField.text = currency.code
        }
        
        currencyTextField.inputView = pickerView
        
        for currency in travel.currencies {
            print("\(currency.code) : \(currency.rate)")
        }
        
        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(pickerDonePressed))
        toolbar.sizeToFit()
        toolbar.setItems([doneButton], animated: false)
        
        currencyTextField.inputAccessoryView = toolbar
        currencyTextField.inputView = pickerView
    }

    //TODO: DatePicker 코드 중복 문제 해결과제
    func pickerDonePressed() {
        self.view.endEditing(true)
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        let transaction = Transaction()
        
        guard let name = nameTextField.text,
            let amountText = amountTextField.text,
            let amount = Double(amountText) else { return }
        
        transaction.name = name
        transaction.amount = amount
        transaction.currency = currency
        
        do {
            try realm.write {
                travel.transactions.append(transaction)
                print("트랜젝션 추가")
                dismiss(animated: true, completion: nil)
            }
        } catch {
            print(error)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension AddTransactionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return travel.currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return travel.currencies[row].code
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currency = travel.currencies[row]
        currencyTextField.text = currency.code
    }
}
