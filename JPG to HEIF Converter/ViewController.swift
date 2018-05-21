//
//  ViewController.swift
//  JPG to HEIF Converter
//
//  Created by Sergey Armodin on 21.05.2018.
//  Copyright © 2018 Sergey Armodin. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	
}


// MARK: - Actions
extension ViewController {
	
	/// Open files button touched
	///
	/// - Parameter sender: NSButton
	@IBAction func openFilesButtonTouched(_ sender: Any) {
		let panel = NSOpenPanel.init()
		panel.allowsMultipleSelection = true
		panel.canChooseDirectories = false
		panel.canChooseFiles = true
		panel.isFloatingPanel = true
		panel.allowedFileTypes = ["jpg", "jpeg", "png"]
		
		panel.beginSheetModal(for: self.view.window!) { (result) in
			guard result == .OK else { return }
			guard panel.urls.isEmpty == false else { return }
			
			for imageUrl in panel.urls {
				guard let source = CGImageSourceCreateWithURL(imageUrl as CFURL, nil) else { continue }
				
//				let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
				let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
				
//				let options = [
//					kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
//					kCGImageSourceThumbnailMaxPixelSize as String: 320
//				] as [String: Any]
//				let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
				
				let pathWithName = imageUrl.deletingPathExtension()
				
				guard let outputUrl = URL(string: pathWithName.absoluteString + ".heic") else { continue }
				
				guard let destination = CGImageDestinationCreateWithURL(
					outputUrl as CFURL,
					AVFileType.heic as CFString,
					1, nil
				) else {
					fatalError("unable to create CGImageDestination")
				}
				
				CGImageDestinationAddImage(destination, image!, nil)
				CGImageDestinationFinalize(destination)
				
			}
		}
	}
	
}

