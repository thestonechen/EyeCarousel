//
//  ViewController.swift
//  eyeCarousel
//
//  Created by Stone Chen on 2/27/21.
//

import UIKit
import PhotosUI
import Kingfisher // NEED TO REFACTOR AND MOVE THIS TO SEPARATE CLASS AT SOME POINT. Adding here to confirm it works 

class HomeViewController: UIViewController {
    
    let maxAlbumNameCharacters = 10
    let maxSavableAlbums = 10
    let maxSavableImagesPerAlbum = 10
    let cache = ImageCache.default
    
    let tableView = UITableView()
    let cacheSerialQueue = DispatchQueue(label: "com.thestonechen.eyecarousel.cachequeue")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.setupTableView()
        self.setupNavigationBar()
        self.setupCache()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
    func setupTableView() {
        self.tableView.register(UITableViewCell.self,
                                forCellReuseIdentifier: "cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func setupCache() {
        self.cache.diskStorage.config.expiration = .never
        self.cache.diskStorage.config.sizeLimit = 0
        self.cache.memoryStorage.config.totalCostLimit = 1
    }
    
    func setupNavigationBar() {
        
        // Disable scrolling to previous VC by swiping back 
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // TODO: Only want a max number of albums before showing this???
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
    }
    
    @objc
    func addButtonTapped() {
        var configuration = PHPickerConfiguration()
        // TODO: Make this a constant to be referenced later on for album naming
        configuration.selectionLimit = self.maxSavableImagesPerAlbum
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    // TODO: Re-look into design if I want this on this VC
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // TODO: This method is too big, break it down
    func showNameAlbumAlert(with results: [PHPickerResult]) {
        let alert = UIAlertController(title: "Please enter a name for the album", message: nil, preferredStyle: .alert)

        alert.addTextField()
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let albumName = alert!.textFields![0].text!
            UserDefaultsManager.shared.addAlbum(albumName)
            
            var carouselVC: CarouselViewController?
            var imageCount = 0
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
                        
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                       
                        if let image = image as? UIImage {
                            print("Calling cacheImages on \(image)")
                            self.cacheSerialQueue.async {
                                self.cacheImage(image, albumName: albumName, imageCount: imageCount)
                                imageCount+=1
                            }
                            
                            DispatchQueue.main.async {
                                if let carouselVC = carouselVC {
                                    carouselVC.addImage(image: image)
                                } else {
                                    carouselVC = CarouselViewController(image: image)
                                    self.navigationController?.pushViewController(carouselVC!, animated: true)
                                }
                            }
                        }
                    })
                }
            }
        })
        okAction.isEnabled = false
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alert.textFields?[0], queue: nil, using: { _ in
            guard let albumName = alert.textFields?[0].text else {
                return
            }
            alert.message = ""
            if albumName.isEmpty || !self.isAlbumNameValid(albumName) || UserDefaultsManager.shared.doesAlbumNameExist(albumName) {
                okAction.isEnabled = false
                if albumName.isEmpty {
                    alert.message = NSLocalizedString("Album name cannot be empty", comment: "")
                } else if !self.isAlbumNameValid(albumName) {
                    alert.message = NSLocalizedString("Album name can only contain alphanumeric characters and must not exceed \(self.maxAlbumNameCharacters) characters.", comment: "")
                } else {
                    alert.message = NSLocalizedString("Album name: \"\(albumName)\" already exists. Please choose another.", comment: "")
                }
                
            } else {
                okAction.isEnabled = true
            }
        })
        
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func isAlbumNameValid(_ name: String) -> Bool {
        return name.isAlphanumeric() && name.count <= self.maxAlbumNameCharacters
    }
}

extension HomeViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true, completion: nil)
        // Show alert to save album name, need to make sure there is a photo to save the album, if not, same page...
        // Need to also make sure the album name doesn't already exist (or a way of handling duplicate album names...)
        // Need to make sure cache not full? Set a limit?
        // Need to create a new constructor for carousel to initisalize with multiple images
        // Can still use kingfisher, namingconvention? album_Name_5
        // DISK CACHE is persistent
        // need to sanitize album name
        
        guard !results.isEmpty else {
            return
        }
        
        // Show an alert for album
        self.showNameAlbumAlert(with: results)
    }
}

// TODO: Testing KingFisher stuff here -- probably want this to live elsewhere
extension HomeViewController {
    
    func cacheImage(_ image: UIImage, albumName: String, imageCount: Int) {
        // TODO: Do i need to ensure this happens on same queue, or risk race conditions
        let cacheKey = "\(albumName)\(imageCount)"
        print("Caching image \(image) with key: \(cacheKey)")
        self.cache.store(image, forKey: cacheKey)
        
        // TODO: Look into better way for this
        let cacheType = cache.imageCachedType(forKey: cacheKey)
        print("Cache type saved in \(cacheType)")
        
    }
    
    func retrieveCachedImages(with albumName: String) {
        var carouselVC: CarouselViewController?
        for i in 0..<self.maxSavableAlbums {
            let cacheKey = "\(albumName)\(i)"
            if !cache.isCached(forKey: cacheKey) {
                print("No image cached for cachekey: \(cacheKey)")
                return
            }
            
            let cacheType = cache.imageCachedType(forKey: cacheKey)
            print("Cache type saved in \(cacheType)")
            
            cache.retrieveImage(forKey: cacheKey) { result in
                switch result {
                case .success(let value):
                    if value.cacheType != .none { // Safety check to ensure no crash
                        print("image found in cache with cachekey \(cacheKey)")
        
                        DispatchQueue.main.async {
                            if let carouselVC = carouselVC {
                                carouselVC.addImage(image: value.image!)
                            } else {
                                carouselVC = CarouselViewController(image: value.image!)
                                self.navigationController?.pushViewController(carouselVC!, animated: true)
                            }
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func removeImagesFromCache(with albumName: String) {
        for i in 0..<self.maxSavableAlbums {
            let cacheKey = "\(albumName)\(i)"
            if cache.isCached(forKey: cacheKey) {
                self.cache.removeImage(forKey: cacheKey)
            }
        }
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let albums = UserDefaultsManager.shared.getExistingAlbums()
        let album = albums[indexPath.row]
        self.retrieveCachedImages(with: album)
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: set this in viewWillappear
        // TODO: Update this variable when deleting a row too
        UserDefaultsManager.shared.getExistingAlbums().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let albums = UserDefaultsManager.shared.getExistingAlbums()
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = albums[indexPath.row]
        return cell
    }
}
