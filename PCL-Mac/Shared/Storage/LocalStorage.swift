//
//  LocalStorage.swift
//  PCL-Mac
//
//  Created by YiZhiMCQiu on 2025/5/19.
//

import SwiftUI

public class LocalStorage {
    public static let shared = LocalStorage()
    private let defaults = UserDefaults.standard
    
    public var userAddedJVMPaths: [URL] {
        get {
            guard let urlStrings = defaults.array(forKey: "userAddedJVMPaths") as? [String] else { return [] }
            return urlStrings.compactMap { URL(string: $0) }
        }
        set {
            let urlStrings = newValue.map { $0.absoluteString }
            defaults.set(urlStrings, forKey: "userAddedJVMPaths")
        }
    }
    
    private init() {
        log("已加载持久化储存数据")
    }
}
