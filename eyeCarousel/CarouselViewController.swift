//
//  CarouselViewController.swift
//  eyeCarousel
//
//  Created by Stone Chen on 2/28/21.
//

import UIKit

class CarouselViewController: UIViewController {

    private var images: [UIImage]
    private var faceTracker: FaceTracker
    private let collectionView: UICollectionView
    private var timer: Timer?
    
    private var isPaused: Bool {
        didSet {
            self.enableDisableTimer()
        }
    }
    
    private var faceTrackerIsInterupted: Bool {
        didSet {
            self.enableDisableTimer()
        }
    }
    
    private var isFaceShown: Bool {
        didSet {
            self.enableDisableTimer()
        }
    }
    
    init(image: UIImage) {
        // Want the first element to be the first and last for infinite looping purposes
        self.images = [image, image]
        self.faceTracker = FaceTracker()
        self.collectionView = UICollectionView(frame: .zero,
                                               collectionViewLayout: UICollectionViewFlowLayout())
        self.isPaused = false
        self.faceTrackerIsInterupted = false
        self.isFaceShown = false
        super.init(nibName: nil, bundle: nil)
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
        self.setupNavigationBar()
        self.setupCollectionView()
        self.faceTracker.delegate = self
        self.view.addSubview(self.collectionView)
        
        // Start face tracker
        self.faceTracker.resume()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionView.frame = self.view.bounds
    }
    
    func setupNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Pause",
                                                                                          comment: ""),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(pauseButtonTapped))
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
    
    @objc
    func pauseButtonTapped() {
        if self.isPaused {
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("Pause", comment: "")
            self.faceTracker.resume()
        } else {
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("Resume", comment: "")
            self.faceTracker.pause()
        }
        
        self.isPaused = !self.isPaused
    }
    
    @objc
    func changeToNextImage() {
        let currentIndex = Int((self.collectionView.contentOffset.x)/(self.collectionView.bounds.size.width))
        let contentOffsetXOfNextImage = self.collectionView.contentOffset.x + self.collectionView.frame.width
        
        // If we're at the second to last image, instead of going to the duplicated last image, go to the first image
        // TODO: Consider calling handleIndexingForInfiniteLooping here
        if currentIndex == self.images.count - 2 {
            self.collectionView.setContentOffset(CGPoint(x: 0,
                                                         y: self.collectionView.contentOffset.y),
                                                 animated: true)
        } else {
            self.collectionView.setContentOffset(CGPoint(x: contentOffsetXOfNextImage,
                                                         y: self.collectionView.contentOffset.y),
                                                 animated: true)
        }
    }
    
    func enableDisableTimer() {
        if isFaceShown && !self.faceTrackerIsInterupted && !self.isPaused {
            self.timer = Timer.scheduledTimer(timeInterval: 2,
                                              target: self,
                                              selector: #selector(changeToNextImage),
                                              userInfo: nil,
                                              repeats: true)
        } else {
            self.timer?.invalidate()
        }
    }
    
    func handleIndexingForInfiniteLooping(_ scrollView: UIScrollView) {
        
        let index = Int((self.collectionView.contentOffset.x)/(self.collectionView.bounds.size.width))
        
        guard index == self.images.count - 1 else {
            return
        }

        // If we're at the last image, which is the duplicated first image, set the contentOffset to be 0
        self.collectionView.setContentOffset(CGPoint(x: 0,
                                                     y: self.collectionView.contentOffset.y),
                                             animated: false)
    }
}


extension CarouselViewController: UICollectionViewDelegate {
    
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


extension CarouselViewController: UICollectionViewDelegateFlowLayout {
    
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

extension CarouselViewController: FaceTrackerDelegate {
    
    func faceTracker(_ tracker: FaceTracker, didFailWithError error: Error) {
        // SHOW ALERTS HERE
    }
    
    func faceTrackerWasInterrupted(_ tracker: FaceTracker) {
        self.faceTrackerIsInterupted = true
    }
    
    func faceTrackerInterruptionEnded(_ tracker: FaceTracker) {
        self.faceTrackerIsInterupted = false
    }
    
    func faceTrackerDidStartDetectingFace(_ tracker: FaceTracker) {
        self.isFaceShown = true
    }
    
    func faceTrackerDidEndDetectingFace(_ tracker: FaceTracker) {
        self.isFaceShown = false
    }
}
