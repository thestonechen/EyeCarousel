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
    let maxSavableImagesPerAlbum = 10
    let cache = ImageCache.default
    let cellIdentifier = "albumCell"
    var albums = [String]()
    
    let tableView = UITableView()
    let cacheSerialQueue = DispatchQueue(label: "com.thestonechen.eyecarousel.cachequeue")

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.setupTableView()
        self.setupNavigationBar()
        self.setupCache()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.albums = UserDefaultsManager.shared.getExistingAlbums()
        self.tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
    func setupTableView() {
        self.tableView.register(UITableViewCell.self,
                                forCellReuseIdentifier: self.cellIdentifier)
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
    }
    
    @objc
    func addButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = self.maxSavableImagesPerAlbum
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // TODO: This method is too big, break it down. Also rename it
    func showNameAlbumAlert(with results: [PHPickerResult]) {
        let alert = UIAlertController(title: "Please enter a name for the album", message: nil, preferredStyle: .alert)

        alert.addTextField()
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { [weak alert, weak self] (_) in
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
                            self?.cacheSerialQueue.async {
                                self?.cacheImage(image, albumName: albumName, imageCount: imageCount)
                                imageCount+=1
                            }
                            
                            DispatchQueue.main.async {
                                if let carouselVC = carouselVC {
                                    carouselVC.addImage(image: image)
                                } else {
                                    carouselVC = CarouselViewController(image: image)
                                    self?.navigationController?.pushViewController(carouselVC!, animated: true)
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
        
        guard !results.isEmpty else {
            return
        }
        
        // Show an alert for naming the album
        self.showNameAlbumAlert(with: results)
    }
}

// TODO: Testing KingFisher stuff here -- probably want this to live elsewhere
extension HomeViewController {
    
    func cacheImage(_ image: UIImage, albumName: String, imageCount: Int) {
        let cacheKey = "\(albumName)\(imageCount)"
        self.cache.store(image, forKey: cacheKey)
    }
    
    func retrieveCachedImages(with albumName: String) {
        var carouselVC: CarouselViewController?
        for i in 0..<self.maxSavableImagesPerAlbum {
            let cacheKey = "\(albumName)\(i)"
            if !cache.isCached(forKey: cacheKey) {
                return
            }
        
            cache.retrieveImage(forKey: cacheKey) { result in
                switch result {
                case .success(let value):
                    if value.cacheType != .none {
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
        for i in 0..<self.maxSavableImagesPerAlbum {
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let album = albums[indexPath.row]
            UserDefaultsManager.shared.deleteAlbum(album)
            self.albums.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.removeImagesFromCache(with: album)
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = self.albums[indexPath.row]
        return cell
    }
}
