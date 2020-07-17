//
//  UserDefaultsStorage.swift
//  YPImagePicker
//
//  Created by art on 7/16/20.
//  Copyright © 2020 Yummypets. All rights reserved.
//

import Foundation

struct GlobalConstant {
    #if DEBUG
    static let enableOnboardingAtEachSession = true
    #else
    static let enableOnboardingAtEachSession = false
    #endif
}

class UserDefaultsStorage {
    private let defaults = UserDefaults.standard
    
    static let shared = UserDefaultsStorage()
    
    private init() { }
    private var _isAlreadyAddCustomImage = false
    private var _isAlreadyStartPlayButton = false
    
    var keyIsAlreadyTapAddCustomImage: Bool {
        get {
            GlobalConstant.enableOnboardingAtEachSession  ? _isAlreadyAddCustomImage : defaults.keyIsAlreadyAddCustomImage
        }
        set {
           _isAlreadyAddCustomImage = newValue
            defaults.keyIsAlreadyAddCustomImage = newValue
        }
    }

}


extension UserDefaults {
    enum Keys: String {

        case isAlreadyAddCustomImage
    }

    var keyIsAlreadyAddCustomImage: Bool {
        get { bool(forKey: Keys.isAlreadyAddCustomImage.rawValue)}
        set { set(newValue, forKey: Keys.isAlreadyAddCustomImage.rawValue)}
    }
}
