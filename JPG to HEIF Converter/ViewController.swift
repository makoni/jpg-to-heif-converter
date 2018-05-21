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
	
	// MARK: - Outlets
	
	/// Open files button
	@IBOutlet fileprivate weak var openFilesButton: NSButtonCell!
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		if #available(macOS 10.13, *) {
			self.openFilesButton.isEnabled = true
		} else {
			self.openFilesButton.isEnabled = false
		}
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
				
				DispatchQueue.main.async {
					guard let source = CGImageSourceCreateWithURL(imageUrl as CFURL, nil) else { return }
					
					guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return }
					guard let imageMetadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) else { return }
					
					let pathWithName = imageUrl.deletingPathExtension()
					guard let outputUrl = URL(string: pathWithName.absoluteString + ".heic") else { return }
					
					guard let destination = CGImageDestinationCreateWithURL(
						outputUrl as CFURL,
						AVFileType.heic as CFString,
						1, nil
					) else {
						fatalError("unable to create CGImageDestination")
					}
					
					CGImageDestinationAddImageAndMetadata(destination, image, imageMetadata, nil)
					CGImageDestinationFinalize(destination)
				}
				
			}
		}
	}
	
}

