//
//  CurrencySelectTableViewController.swift
//  PayRoad
//
//  Created by 손동찬 on 2017. 8. 9..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

struct ISOCurrency {
    var code: String
    var name: String
}

protocol CurrencySelectTableViewControllerDelegate {
    
    func currencySelectResponse(code: String)
}

class CurrencySelectTableViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: CurrencySelectTableViewControllerDelegate?
    
    var ISOCurrencies = [ISOCurrency]()
    var filteredCurrencies = [ISOCurrency]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "화폐"
        
        self.searchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        for currencyCode in Locale.commonISOCurrencyCodes {
            if let currencyName = Locale.current.localizedString(forCurrencyCode: currencyCode) {
                let currency = ISOCurrency(code: currencyCode, name: currencyName)
                ISOCurrencies.append(currency)
            }
        }
        
        filteredCurrencies = ISOCurrencies
        tableView.reloadData()
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension CurrencySelectTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredCurrencies.count

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyItemCell", for: indexPath)
        
        let currency = filteredCurrencies[indexPath.row]
        cell.textLabel?.text = currency.name
        cell.detailTextLabel?.text = currency.code
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let code = Locale.commonISOCurrencyCodes[indexPath.row]
        self.delegate?.currencySelectResponse(code: code)
        self.navigationController?.popViewController(animated: true)
        
    }
}

// MARK: UISearchBarDelegate

extension CurrencySelectTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterCurrencyForSearchText(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = false
        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        filteredCurrencies = ISOCurrencies
        tableView.reloadData()
    }
    
    func filterCurrencyForSearchText(_ searchText: String) {
        filteredCurrencies = ISOCurrencies.filter({(currency: ISOCurrency) -> Bool in
            if searchText.isEmpty {
                return true
            } else {
                return currency.code.lowercased().contains(searchText.lowercased()) || currency.name.lowercased().contains(searchText.lowercased())
            }
        })
        tableView.reloadData()
    }
}
