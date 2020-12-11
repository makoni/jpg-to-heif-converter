//
//  UserDefaultsManager.swift
//  JPG to HEIF Converter
//
//  Created by Christopher Spradling on 9/5/18.
//  Copyright © 2018 Sergey Armodin. All rights reserved.
//

import Foundation

struct UserDefaultsManager {
	// MARK: - Private properties
	private static let removeOriginalImagePreferenceKey = "removeOriginalImagePreferenceKey"
	private static let qualityPreferenceKey = "qualityPreferenceKey"
	
	// MARK: - Public properties
	static var preferToRemoveOriginals: Bool {
		get {
			return UserDefaults.standard.bool(forKey: removeOriginalImagePreferenceKey)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: removeOriginalImagePreferenceKey)
		}
	}
	
	static var qualityPreference: Double? {
		get {
			return UserDefaults.standard.double(forKey: removeOriginalImagePreferenceKey)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: removeOriginalImagePreferenceKey)
		}
	}
	
}
