//
//  ViewController.swift
//  eyeCarousel
//
//  Created by Stone Chen on 2/27/21.
//

import UIKit
import PhotosUI

class HomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.view.backgroundColor = .blue
        
    }
    
    func setupNavigationBar() {
        
        // Disable scrolling to previous VC by swiping back 
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
    }
    
    @objc
    func addButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // Unlimited
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
}

extension HomeViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true, completion: nil)
        var carouselVC: CarouselViewController?
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
                    
                    guard error == nil else {
                        print(error!.localizedDescription)
                        return
                    }
                   
                    if let image = image as? UIImage {
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
    }
}
