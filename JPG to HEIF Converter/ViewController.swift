//
//  ViewController.swift
//  JPG to HEIF Converter
//
//  Created by Sergey Armodin on 21.05.2018.
//  Copyright © 2018 Sergey Armodin. All rights reserved.
//

import Cocoa
import AVFoundation


/// Converter state
///
/// - launched: just launched
/// - converting: converting right now
/// - complete: convertion complete
enum ConverterState: Int {
	case launched
	case converting
	case complete
}


class ViewController: NSViewController {
	
	// MARK: - Outlets
	
	/// Open files button
	@IBOutlet fileprivate weak var openFilesButton: NSButtonCell!
	
	/// Indicator
	@IBOutlet fileprivate weak var progressIndicator: NSProgressIndicator!
	
	/// Complete label
	@IBOutlet fileprivate weak var completeLabel: NSTextField!
	
	
	// MARK: - Properties
	
	/// Processed images number
	fileprivate var processedImages: Int = 0 {
		didSet {
			self.completeLabel.stringValue = "\(self.processedImages) of \(self.totalImages)"
			
			self.progressIndicator.doubleValue = Double(self.processedImages)
		}
	}
	
	/// Total selected images number
	fileprivate var totalImages: Int = 0 {
		didSet {
			self.progressIndicator.maxValue = Double(totalImages)
		}
	}
	
	/// State
	fileprivate var converterState: ConverterState = .launched {
		didSet {
			switch converterState {
			case .launched:
				self.progressIndicator.isHidden = true
				self.completeLabel.isHidden = true
			case .converting:
				self.openFilesButton.isEnabled = false
				self.progressIndicator.isHidden = false
				self.completeLabel.isHidden = false
			case .complete:
				self.openFilesButton.isEnabled = true
				self.progressIndicator.isHidden = false
				self.completeLabel.isHidden = false
				
				self.completeLabel.stringValue = NSLocalizedString("Converting complete", comment: "Label")
			}
		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if #available(macOS 10.13, *) {
			self.openFilesButton.isEnabled = true
		} else {
			self.openFilesButton.isEnabled = false
		}
		
		self.converterState = .launched
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
		
		self.totalImages = 0
		self.processedImages = 0
		
		let panel = NSOpenPanel.init()
		panel.allowsMultipleSelection = true
		panel.canChooseDirectories = false
		panel.canChooseFiles = true
		panel.isFloatingPanel = true
		panel.allowedFileTypes = ["jpg", "jpeg", "png"]
		
		panel.beginSheetModal(for: self.view.window!) { [weak self] (result) in
			guard let `self` = self else { return }
			
			guard result == .OK else { return }
			guard panel.urls.isEmpty == false else { return }
			
			self.totalImages = panel.urls.count
			self.converterState = .converting
			self.processedImages = 0
			
			let group = DispatchGroup()
			
			for imageUrl in panel.urls {
				group.enter()
				
				DispatchQueue.global(qos: .utility).async { [weak self] in
					
					guard let `self` = self else { return }
					
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
					
					DispatchQueue.main.async {
						self.processedImages += 1
					}
					
					group.leave()
				}
				
			}
			
			group.notify(queue: .main, execute: { [weak self] in
				guard let `self` = self else { return }
				self.converterState = .complete
			})
		}
	}
	
}

