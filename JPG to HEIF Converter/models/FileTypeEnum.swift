//
//  FileTypeEnum.swift
//  JPG to HEIF Converter
//
//  Created by Christopher Spradling on 8/31/18.
//  Copyright © 2018 Sergey Armodin. All rights reserved.
//

import Foundation

enum FileType {
    
    case image
    case json
    case directory
    case invalid
    
    init(_ url: URL) {
        if FileType.allowedImageTypes.contains(url.pathExtension.lowercased()) {
            self = .image
        }
        else if FileType.directoryTypes.contains(url.pathExtension) {
            self = .directory
        }
        else if url.lastPathComponent.lowercased() == "contents.json" {
            self = .json
        }
        else {
            self = .invalid
        }
        
    }
    
    static var allowedImageTypes: [String] {
        return ["jpg", "jpeg", "png", "nef", "cr2", "sr2", "arw", "dng"]
    }
    
    static var directoryTypes: [String] {
        return ["xcassets", "imageset", ""]
    }
    
}
