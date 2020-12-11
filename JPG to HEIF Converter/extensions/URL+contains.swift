//
//  URL+contains.swift
//  JPG to HEIF Converter
//
//  Created by Sergei Armodin on 11.12.2020.
//  Copyright © 2020 Sergey Armodin. All rights reserved.
//

import Foundation

extension URL {
	public func contains(_ other: URL) -> Bool {
		return autoreleasepool {
			return resolvingSymlinksInPath().absoluteString.lowercased().contains(other.resolvingSymlinksInPath().absoluteString.lowercased())
		}
	}
}
