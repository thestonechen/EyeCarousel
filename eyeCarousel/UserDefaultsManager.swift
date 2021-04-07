//
//  UserDefaultsManager.swift
//  eyeCarousel
//
//  Created by Stone Chen on 4/5/21.
//

import Foundation

class UserDefaultsManager {
    
    static let shared = UserDefaultsManager(suiteName: "com.thestonechen.eyecarousel")
    
    let userDefaults: UserDefaults
    let albumKey = "albums"
    
    
    private init(suiteName: String) {
        userDefaults = UserDefaults(suiteName: suiteName)!
    }
    
    func getExistingAlbums() -> [String] {
        guard let albums = userDefaults.value(forKey: self.albumKey) as? [String] else {
            return []
        }
        
        return albums 
    }
    
    func doesAlbumNameExist(_ name: String) -> Bool {
        if let albums = userDefaults.value(forKey: self.albumKey) as? [String] {
            if albums.contains(name) {
                print("album name exists")
            }
            else {
                print("album name unique")
            }
            return albums.contains(name)
        }
        
        return false
    }
    
    func addAlbum(_ name: String) {
        print("Adding album")
        if var albums = userDefaults.value(forKey: self.albumKey) as? [String] {
            albums.append(name)
            print("Existing albums \(albums)")
            userDefaults.setValue(albums, forKey: self.albumKey)
        } else {
            userDefaults.setValue([name], forKey: self.albumKey)
        }
    }
    
    func deleteAlbum(_ name: String) {
        guard var albums = userDefaults.value(forKey: self.albumKey) as? [String] else {
            return
        }
        
        albums = albums.filter { $0 != name }
        userDefaults.setValue(albums, forKey: self.albumKey)
    }
}
