//
//  PhotoDetailViewController.swift
//  PayRoad
//
//  Created by Febrix on 2017. 8. 24..
//  Copyright © 2017년 REFUEL. All rights reserved.
//

import UIKit

protocol PhotoDatailViewDelegate {
    func changedCurrentPhoto(_ page: Int)
}

class PhotoDetailViewController: UIViewController, UIScrollViewDelegate {
    var delegate: PhotoDatailViewDelegate?
    
    var photos: [Photo]!
    var selectedIndex: Int!
    var photoDetailViews = [PhotoDetailView]()
    
    var previousPage = 0
    var currentPage = 0 {
        didSet {
            photoDetailViews[previousPage].resetZoomScale()
            photoDetailViews[currentPage].resetZoomScale()
            delegate?.changedCurrentPhoto(currentPage)
        }
    }
    
    @IBOutlet weak var baseScrollView: UIScrollView!
    @IBOutlet weak var baseBlackView: UIView!
    
    override func viewDidLoad() {
        baseScrollView.delegate = self
        setupImageView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for item in photoDetailViews {
            item.restoreView(view: item.detailImageView)
            item.resetZoomScale()
        }
        showSelectedIndexImage(index: selectedIndex)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
    }
    
    func setupImageView() {
        for (index, item) in photos.enumerated() {
            let photoDetailView = UINib(nibName: "PhotoDetailView", bundle: nil).instantiate(withOwner: self, options: nil).first as! PhotoDetailView
            
            photoDetailView.delegate = self
            photoDetailView.detailImageView.image = item.fetchPhoto()
            
            let dynamicX = self.view.frame.width * CGFloat(index)
            photoDetailView.frame = CGRect(x: dynamicX, y: 0, width: photoDetailView.frame.width, height: photoDetailView.frame.height)
            baseScrollView.contentSize.width = baseScrollView.frame.width * CGFloat(index + 1)
            
            baseScrollView.addSubview(photoDetailView)
            photoDetailViews.append(photoDetailView)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / view.frame.width))
        previousPage = page
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / view.frame.width))
        if currentPage != page {
            currentPage = page
        }
    }
    
    func showSelectedIndexImage(index: Int) {
        let newOffset = view.frame.width * CGFloat(index)
        baseScrollView.setContentOffset(CGPoint(x: newOffset, y: 0), animated: true)
    }
    
    func panDownGuesture(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonDidTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
