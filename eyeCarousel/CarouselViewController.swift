//
//  CarouselViewController.swift
//  eyeCarousel
//
//  Created by Stone Chen on 2/28/21.
//

import UIKit

class CarouselViewController: UIViewController {
    
    private var images = [UIImage]()
    private let collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: UICollectionViewFlowLayout())

    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        
        // Want the first element to be the first and last for infinite looping purposes
        self.images = [image, image]
    }
    
    func addImage(image: UIImage) {
        // Since we duplicate the first image to be the first and last, we need to insert new images to be second to last
        self.images.insert(image, at: self.images.count-1)
        self.collectionView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
        self.view.addSubview(self.collectionView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionView.frame = self.view.bounds
    }
    
    func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(PhotoCollectionViewCell.self,
                                     forCellWithReuseIdentifier: PhotoCollectionViewCell.identifier)
        
        
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        self.collectionView.isPagingEnabled = true
    }
    
    
    func changeToNextImage() {
        //self.collectionView.scrollToItem(at: <#T##IndexPath#>, at: <#T##UICollectionView.ScrollPosition#>, animated: <#T##Bool#>)
    }
    
    func handleIndexingForInfiniteLooping(_ scrollView: UIScrollView) {
        let index = Int((collectionView.contentOffset.x)/(collectionView.bounds.size.width))

        guard index == self.images.count - 1 else {
            return
        }

        // If we're at the last image, which is the duplicated first image, set the contentOffset to be 0
        self.collectionView.setContentOffset(CGPoint(x: 0, y: self.collectionView.contentOffset.y), animated: false)
    }
}


extension CarouselViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionView.deselectItem(at: indexPath, animated: true)
        // Do something when selected? Or actually not needed...
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleIndexingForInfiniteLooping(scrollView)
    }
}

extension CarouselViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = self.images[indexPath.item]
        return cell
    }
}


extension CarouselViewController: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width - 1,
                      height: self.collectionView.frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }

}
