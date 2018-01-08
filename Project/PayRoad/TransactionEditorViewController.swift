//
//  AddTransactionViewController.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 8..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

import RealmSwift
import GooglePlacePicker

protocol TransactionEditorDelegate {
    func edited(transaction: Transaction)
}

class TransactionEditorViewController: UIViewController {
    fileprivate let realm = try! Realm()
    
    fileprivate(set) var delegate: TransactionEditorDelegate?
    
    fileprivate(set) var travel: Travel!
    fileprivate(set) var currency: Currency!
    fileprivate(set) var transaction = Transaction()
    
    fileprivate(set) var editorMode: EditorMode = .new
    fileprivate(set) var titleName: String!
    
    fileprivate(set) lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    
    //User Input Data
    fileprivate(set) var standardDate: DateInRegion? = nil
    fileprivate(set) var inputImages: [UIImage]? = nil
    fileprivate(set) var isCash = true {
        didSet {
            payTypeToggleButton.isSelected = !isCash
        }
    }
    
    fileprivate(set) var category: Category? = nil
    fileprivate(set) lazy var categories: Results<Category> = { [unowned self] in
        return self.realm.objects(Category.self)
    }()
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate(set) var currentLocationCoordinate: CLLocationCoordinate2D? // 위치 -> 현 위치 또는 사용자가 Google Place Picker로 선택한 위치
    fileprivate(set) var currentLocationName: String? // 위치에 대한 지역 이름 (CLGeocoder)
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var payTypeToggleButton: UIButton!
    @IBOutlet weak var dateEditTextField: UITextField!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var categoryCollectionViewBG: UIView!
    @IBOutlet weak var multiImagePickerView: MultiImagePickerView!
    @IBOutlet weak var textViewUnderLineView: UIView!
    
    override func loadView() {
        super.loadView()
        
        nameTextField.addUnderline(color: ColorStore.unselectGray, borderWidth: 0.5)
        dateEditTextField.addUpperline(color: ColorStore.unselectGray, borderWidth: 0.5)
        dateEditTextField.addUnderline(color: ColorStore.unselectGray, borderWidth: 0.5)
        textViewUnderLineView.addUpperline(color: ColorStore.unselectGray, borderWidth: 0.5)
        contentTextView.placeholder = "내용을 입력해주세요"
        nameTextField.borderStyle = .none
        
        payTypeToggleButton.backgroundColor = ColorStore.mainSkyBlue
        payTypeToggleButton.layer.cornerRadius = payTypeToggleButton.frame.height / 5
        payTypeToggleButton.setTitleColor(payTypeToggleButton.currentTitleColor.withAlphaComponent(0.8), for: .highlighted)
        payTypeToggleButton.setTitle("현금", for: .normal)
        payTypeToggleButton.setTitle("카드", for: .selected)
        
        currencyTextField.borderStyle = .none
        categoryCollectionViewBG.addUnderline(color: ColorStore.unselectGray, borderWidth: 0.5)
        categoryCollectionViewBG.addUpperline(color: ColorStore.unselectGray, borderWidth: 0.5)
        dateEditTextField.text = DateFormatter.string(for: standardDate?.date ?? Date(), timeZone: standardDate?.timeZone)
        dateEditTextField.inputDatePicker(mode: .dateAndTime, date: standardDate?.date, timeZone: standardDate?.timeZone)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.showsHorizontalScrollIndicator = false
        currencyTextField.delegate = self
        
        multiImagePickerView.set(delegate: self)
        
        let bgTapGestureReconizer: UITapGestureRecognizer = .init(target: self, action: #selector(backgroundDidTap(_:)))
        bgTapGestureReconizer.cancelsTouchesInView = false
        view.addGestureRecognizer(bgTapGestureReconizer)
        
        let nibCell = UINib(nibName: "CategoryCollectionViewCell", bundle: nil)
        categoryCollectionView.register(nibCell, forCellWithReuseIdentifier: "categoryCell")
        
        payTypeToggleButton.addTarget(self, action: #selector(togglePayTypeButtonDidTap(_:)), for: .touchUpInside)

        setupCurrencyPicker()
        adjustViewMode()
        
        nameTextField.delegate = self
    }
    
    func setupCurrencyPicker() {
        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(pickerDonePressed))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.sizeToFit()
        toolbar.setItems([space, doneButton], animated: false)
        
        currencyTextField.inputAccessoryView = toolbar
        currencyTextField.inputView = pickerView
    }
    
    func togglePayTypeButtonDidTap(_ sender: UIButton) {
        isCash = !isCash
        print("\(isCash ? "현금" : "카드") 선택됨")
    }
    
    
    func setTitleView(subTitle: String?) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 1, width: 0, height: 0))
        titleLabel.text = titleName
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = ColorStore.basicBlack
        titleLabel.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 17)
        titleLabel.textAlignment = .center
        titleLabel.sizeToFit()
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let attributed = [
            NSFontAttributeName: UIFont(name: "AppleSDGothicNeo-Light", size: 13),
            NSForegroundColorAttributeName: ColorStore.darkGray,
            NSParagraphStyleAttributeName: style
        ]
        
        let subTitleButton = UIButton(frame: CGRect(x: 0, y: 22, width: 0, height: 0))
        subTitleButton.backgroundColor = UIColor.clear
        subTitleButton.setTitle(" " + (subTitle ?? "위치 설정"), for: .normal)
        subTitleButton.setImage(#imageLiteral(resourceName: "Icon_LocationPin"), for: .normal)
        
        let attString = NSMutableAttributedString(string: subTitleButton.titleLabel!.text!)
        attString.addAttributes(attributed, range: NSMakeRange(0, attString.length))
        
        subTitleButton.setAttributedTitle(attString, for: .normal)
        subTitleButton.sizeToFit()
        subTitleButton.addTarget(self, action: #selector(setLocationInfo), for: .touchUpInside)
        
        let imageView = UIImageView(frame: CGRect(x: subTitleButton.frame.maxX + 2, y: subTitleButton.frame.midY - 3, width: 8, height: 4))
        imageView.image = #imageLiteral(resourceName: "Icon_DropDown")
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel.frame.width, subTitleButton.frame.width), height: 40))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subTitleButton)
        titleView.addSubview(imageView)
        
        let widthGap = subTitleButton.frame.width - titleLabel.frame.width
        
        if widthGap < 0 {
            let gap = abs(widthGap / 2)
            subTitleButton.frame.origin.x = gap
            imageView.frame.origin.x = imageView.frame.origin.x + gap
        } else {
            titleLabel.frame.origin.x = widthGap / 2
        }
        return titleView
    }
    
    func updateTitleView(subTitle: String?) {
        navigationItem.titleView = setTitleView(subTitle: subTitle)
    }
    
    //TODO: Location Setting Method
    func setLocationInfo() {
        var viewport: GMSCoordinateBounds? = nil
        
        if let currentLocationCoordinate = currentLocationCoordinate {
            let center = currentLocationCoordinate
            let northEast = CLLocationCoordinate2D(latitude: center.latitude + 0.005, longitude: center.longitude + 0.005)
            let southWest = CLLocationCoordinate2D(latitude: center.latitude - 0.005, longitude: center.longitude - 0.005)
            viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        }
        
        let config = GMSPlacePickerConfig(viewport: viewport)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        
        present(placePicker, animated: true, completion: nil)
    }
    
    func pickerDonePressed() {
        self.view.endEditing(true)
    }

    @IBAction func cancelButtonDidTap(_ sender: Any) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backgroundDidTap(_ sender: Any) {
        view.endEditing(true)
    }
    
    func checkIsExistInputField() -> Bool {
        guard !(amountTextField.text!.isEmpty) else {
            UIAlertController.oneButtonAlert(target: self, title: "에러", message: "사용 금액을 입력해주세요.")
            return false
        }
        
        guard !(currency == nil) else {
            UIAlertController.oneButtonAlert(target: self, title: "에러", message: "화폐를 선택해주세요.")
            return false
        }
        
        guard !(nameTextField.text!.isEmpty) else {
            UIAlertController.oneButtonAlert(target: self, title: "에러", message: "항목명을 입력해주세요.")
            return false
        }
        return true
    }
    
    func generateLocaionName(from placemark: CLPlacemark) -> String {
        var locationComponents = [String]()
        
        if let country = placemark.country { locationComponents.append(country) }
        if let administrativeArea = placemark.administrativeArea { locationComponents.append(administrativeArea) }
        if let locality = placemark.locality { locationComponents.append(locality) }
        if let subLocality = placemark.subLocality { locationComponents.append(subLocality) }

        return locationComponents.joined(separator: " ")
    }
}

extension TransactionEditorViewController {
    func set(travel: Travel) {
        self.travel = travel
    }
    
    func set(transaction: Transaction) {
        self.transaction = transaction
    }
    
    func set(standardDate: DateInRegion?) {
        self.standardDate = standardDate
    }
    
    func set(delegate: TransactionEditorDelegate) {
        self.delegate = delegate
    }
    
    func set(editorMode: EditorMode) {
        self.editorMode = editorMode
    }
}

extension TransactionEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameTextField {
            textField.resignFirstResponder()
        }
        
        return true
    }
}

extension TransactionEditorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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

extension TransactionEditorViewController {
    fileprivate func adjustViewMode() {
        let barButtonItem: UIBarButtonItem = .init(image: #imageLiteral(resourceName: "Icon_Check"), style: .plain, target: self, action: #selector(writeButtonDidTap))
        navigationItem.rightBarButtonItem = barButtonItem
        
        switch self.editorMode {
        case .new:
            titleName = "새 항목"
            updateTitleView(subTitle: nil)
            //TODO: PickerView 없애면서 들어내야될 코드
            if let lastCurrency = travel.transactions.last?.currency {
                currency = lastCurrency
                currencyTextField.text = lastCurrency.code
            } else {
                currency = travel.currencies.first!
                currencyTextField.text = currency?.code
            }
            
            if let _category = realm.object(ofType: Category.self, forPrimaryKey: "category-etc") {
                category = _category
            }
            
            let status = CLLocationManager.authorizationStatus()
            
            if status == CLAuthorizationStatus.authorizedWhenInUse {
                if let currentLocation = locationManager.location {
                    currentLocationCoordinate = currentLocation.coordinate
                    updateTitleView(subTitle: "현 위치")
                    
                    CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: { placemarks, error in
                        if let placemark = placemarks?.first {
                            self.currentLocationName = self.generateLocaionName(from: placemark)
                            self.updateTitleView(subTitle: self.currentLocationName)
                        }
                    })
                }
            }
            
        case .edit:
            titleName = "항목 수정"
            updateTitleView(subTitle: nil)
            nameTextField?.text = transaction.name
            amountTextField?.text = String(transaction.amount)
            currencyTextField?.text = transaction.currency?.code
            contentTextView.text = transaction.content
            isCash = transaction.isCash
            currency = transaction.currency
            category = transaction.category
            
            if let coordinate = transaction.coordinate {
                currentLocationCoordinate = coordinate
                
                if let placeName = transaction.placeName {
                    updateTitleView(subTitle: placeName)
                } else {
                    self.updateTitleView(subTitle: "알 수 없는 위치")
                    
                    // 위치 가져오기 재시도
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    CLGeocoder().reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                        if let placemark = placemarks?.first {
                            self.currentLocationName = self.generateLocaionName(from: placemark)
                            self.updateTitleView(subTitle: self.currentLocationName)
                        }
                    })
                }
            }
            
            if let _category = transaction.category {
                category = _category
            }
            
            var photos = [UIImage]()
            transaction.photos.forEach {
                guard let image = $0.fetchPhoto() else { return }
                photos.append(image)
            }
            multiImagePickerView.set(visibleImages: photos)
        }

        let index = travel.currencies.index(of: currency)
        pickerView.selectRow(index!, inComponent: 0, animated: true)
        
        if let _category = category,
            let categoryIndex = categories.index(of: _category) {
            categoryCollectionView.selectItem(at: IndexPath(row: categoryIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        }
        
    }
    
    func writeButtonDidTap() {
        if checkIsExistInputField() {
            do {
                try realm.write {
                    transactionFromUI(transaction: &transaction)

                    if editorMode == .new {
                        savePhotosToTransaction(target: transaction)
                        saveLocationTransaction(target: transaction)
                        travel.transactions.append(transaction)
                    }
                    else if editorMode == .edit {
                        if multiImagePickerView.isChanged {
                            for item in transaction.photos {
                                FileUtil.removeData(filePath: item.filePath)
                                realm.delete(item)
                            }
                            savePhotosToTransaction(target: transaction)
                        }
                        
                        saveLocationTransaction(target: transaction)
                        
                        transaction.name = transaction.name
                        transaction.amount = transaction.amount
                        transaction.currency = transaction.currency
                        transaction.content = transaction.content
                        transaction.isCash = transaction.isCash
                        transaction.dateInRegion = transaction.dateInRegion
                        
                        delegate?.edited(transaction: transaction)
                    }
                    print("트랜젝션 수정")
                }
                
            } catch {
                // Alert 위해 남겨둠
                print(error)
            }
            
            view.endEditing(true)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func savePhotosToTransaction(target: Transaction) {
        PhotoUtil.savePhotos(travelID: travel.id, transactionID: transaction.id, photos: multiImagePickerView.visibleImages) { photos -> Void in
            guard let photosModel = photos else { return }
            try? self.realm.write {
                for photo in photosModel {
                    self.transaction.photos.append(photo)
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "didSavedPhoto"), object: self.transaction.photos)
        }
    }
    
    func saveLocationTransaction(target: Transaction) {
        if let currentLocationCoordinate = currentLocationCoordinate {
            target.coordinate = currentLocationCoordinate
            
            if let currentLocationName = currentLocationName {
                target.placeName = currentLocationName
            }
        }
    }

    func transactionFromUI(transaction: inout Transaction) {
        guard let name = nameTextField.text,
            let content = contentTextView.text,
            let amountText = amountTextField.text,
            let amount = Double(amountText)
        else {
            print("fail to get transaction from UI")
            return
        }
        
        let datePicker = dateEditTextField.inputView as! UIDatePicker
        
        transaction.name = name
        transaction.amount = amount
        transaction.currency = currency
        transaction.content = content
        transaction.isCash = isCash
        transaction.category = category
        
        if let dateInRegion = standardDate {
            dateInRegion.date = datePicker.date
            transaction.dateInRegion = dateInRegion
        } else {
            let dateInRegion = DateInRegion()
            dateInRegion.date = datePicker.date
            transaction.dateInRegion = dateInRegion
        }
    }
}

extension TransactionEditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! CategoryCollectionViewCell
        let category = categories[indexPath.row]
        
        cell.categoryImage.image = UIImage(named: category.assetName)
        cell.categoryName.text = category.name
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //TODO: 선택한 카테고리 반영
        print(categories[indexPath.row].name)
        
        category = categories[indexPath.row]
    }
}

extension TransactionEditorViewController: GMSPlacePickerViewControllerDelegate {
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true, completion: nil)
    
        currentLocationCoordinate = place.coordinate
        
        if place.types.contains("synthetic_geocode") {
            updateTitleView(subTitle: "설정한 위치")
            
            let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                if let placemark = placemarks?.first {
                    self.currentLocationName = self.generateLocaionName(from: placemark)
                    self.updateTitleView(subTitle: self.currentLocationName)
                }
            })
        } else {
            currentLocationName = place.name
            updateTitleView(subTitle: place.name)
        }

    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        viewController.dismiss(animated: true, completion: nil)
        
        print("No place selected")
    }
}
