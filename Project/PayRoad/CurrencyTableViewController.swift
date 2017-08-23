//
//  CurrencyTableViewController.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 8..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

import RealmSwift

class CurrencyTableViewController: UIViewController {
    
    let realm = try! Realm()
    
    var travel: Travel!
    var notificationToken: NotificationToken? = nil
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if travel.currencies.count == 0 {
            try? realm.write {
                if let currencyCode = Locale.current.currencyCode {
                    let currency = Currency()
                    currency.id = travel.id + "-" + currencyCode
                    currency.code = currencyCode
                    currency.rate = 1.0
                    travel.currencies.append(currency)
                }
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        notificationToken = travel.currencies.addNotificationBlock({ (changes: RealmCollectionChange) in
            self.tableView.reloadData()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addCurrency" {
            guard let navigationController = segue.destination as? UINavigationController,
            let addCurrencyTableViewController = navigationController.topViewController as? CurrencyEditorViewController
            else {
                return
            }
            
            addCurrencyTableViewController.travel = travel
        }
        
        if segue.identifier == "editCurrency" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                let navigationController = segue.destination as? UINavigationController,
                let editCurrencyTableViewController = navigationController.topViewController as? CurrencyEditorViewController
            else {
                return
            }
            
            editCurrencyTableViewController.editorMode = .edit
            editCurrencyTableViewController.travel = travel
            editCurrencyTableViewController.originCurrency = travel.currencies[indexPath.row]
        }
    }

    @IBAction func cancelButtonDidTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension CurrencyTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyBudgetTableViewCell", for: indexPath) as! CurrencyBudgetTableViewCell
        
        let currency = travel.currencies[indexPath.row]
        cell.currencyCodeLabel?.text = currency.code
        cell.currencyLocaleLabel?.text = Locale.current.localizedString(forCurrencyCode: currency.code)
        cell.budgetAmountLabel?.text = currency.budget.nonZeroString(maxDecimalPlace: 2)
        
        if currency.rate == 1.0 {
            cell.rateLabel?.text = "기준"
        } else {
            let basicCurrencyCode = travel.currencies.first!.code
            cell.rateLabel?.text = "1\(currency.code)당 \(currency.rate.nonZeroString(maxDecimalPlace: 2))\(basicCurrencyCode)"
        }
            
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editCurrency", sender: nil)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return travel.currencies.count
    }
}
