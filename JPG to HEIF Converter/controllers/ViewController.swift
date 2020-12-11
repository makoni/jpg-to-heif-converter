//
//  ViewController.swift
//  JPG to HEIF Converter
//
//  Created by Sergey Armodin on 21.05.2018.
//  Copyright © 2018 Sergey Armodin. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreFoundation


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

typealias JSON = [String:Any]

class ViewController: NSViewController {
	
	// MARK: - Outlets
	
	/// Open files button
	@IBOutlet fileprivate weak var openFilesButton: NSButtonCell!
	/// Indicator
	@IBOutlet fileprivate weak var progressIndicator: NSProgressIndicator!
	/// Complete label
	@IBOutlet fileprivate weak var completeLabel: NSTextField!
    /// Keep Originals checkbox
	@IBOutlet fileprivate weak var keepOriginalsCheckbox: NSButton!
	/// Quality value
	@IBOutlet fileprivate weak var qualityValueLabel: NSTextField!
	/// Quality slider
	@IBOutlet fileprivate weak var qualitySlider: NSSlider!
	
	
	
	// MARK: - Private properties
	private var quality: Double = 0.9
	
	/// Processed images number
	fileprivate var processedImages: Int = 0 {
		didSet {
			self.completeLabel.stringValue = "\(self.processedImages)" + NSLocalizedString("of", comment: "conjunction") + "\(self.totalImages)"
			
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
		
		self.openFilesButton.isEnabled = true
		self.converterState = .launched
        
        keepOriginalsCheckbox.state = UserDefaultsManager.preferToRemoveOriginals ? .off : .on
		
		let preferredQuality = UserDefaultsManager.qualityPreference ?? 0.9
		qualityValueLabel.stringValue = "\(preferredQuality)"
		qualitySlider.maxValue = 1
		qualitySlider.minValue = 0.1
		qualitySlider.doubleValue = preferredQuality
		quality = preferredQuality
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func slider(_ sender: Any) {
		quality = round(qualitySlider.doubleValue * 100) / 100
		UserDefaultsManager.qualityPreference = quality
		qualityValueLabel.stringValue = "\(quality)"
	}
	
}


// MARK: - Actions
extension ViewController {
    
    /// Keep Original Files checkbox checked/unchecked
    ///
    /// - Parameter sender: sender
    @IBAction func keepOriginalsCheckboxTouched(_ sender: Any) {
        UserDefaultsManager.preferToRemoveOriginals = (keepOriginalsCheckbox.state == .off)
    }
	
	/// Open files button touched
	///
	/// - Parameter sender: NSButton
	@IBAction func openFilesButtonTouched(_ sender: Any) {
		
		totalImages = 0
		processedImages = 0
		
		let panel = NSOpenPanel.init()
		panel.allowsMultipleSelection = true
		panel.canChooseDirectories = true
		panel.canChooseFiles = true
		panel.isFloatingPanel = true
		panel.allowedFileTypes = FileType.allowedImageTypes + FileType.directoryTypes
		
		panel.beginSheetModal(for: self.view.window!) { [weak self] (result) in
			guard let self = self else { return }
			guard result == .OK, panel.urls.isEmpty == false else { return }
			
            self.processItems(panel.urls, deletingOriginals: UserDefaultsManager.preferToRemoveOriginals)
		}
	}
	
    /// Determine file types in a list and process each item accordingly
    ///
    /// - Parameter urls: [URL]
    /// - Parameter deletingOriginals: Boolean flag to indicate whether images should be preserved in their original format after conversion
    func processItems(_ urls: [URL], deletingOriginals: Bool) {
        converterState = .converting
        totalImages = 0
        processedImages = 0
        
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "me.spaceinbox.jpgtoheifconverter")
        
        for url in urls {
            
            switch FileType(url) {
            case .image:        convertImage(url, group: group, queue: serialQueue, deletingOriginals: deletingOriginals)
            case .json:         updateContentsFile(url, group: group, queue: serialQueue)
            case .directory:    processFolder(url, group: group, queue: serialQueue, deletingOriginals: deletingOriginals)
            case .invalid:      continue
            }

        }
        
        group.notify(queue: .main, execute: { [weak self] in
            guard let self = self else { return }
            self.converterState = .complete
        })
        
    }
    
    /// Traverse directories and convert any images to .heic
    ///
    /// - Parameter url: the file path to be processed
    /// - Parameter group: the DispatchGroup managing conversion work
    /// - Parameter queue: the serial queue to contain conversion work
    /// - Parameter deletingOriginals: Boolean flag to indicate whether images should be preserved in their original format after conversion
    func processFolder(_ url: URL, group: DispatchGroup, queue: DispatchQueue, deletingOriginals: Bool) {
        guard case .directory = FileType(url) else { return }
        
        
        let subPaths = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey])

        var excludes: [URL] = []
        
        while let path = subPaths?.nextObject() as? URL {
            if !excludes.lazy.map({ path.contains($0) }).filter({ $0 }).isEmpty {
                continue
            }

            switch FileType(path) {
            case .image:
                convertImage(path, group: group, queue: queue, deletingOriginals: deletingOriginals)
                continue
            case .json:
                updateContentsFile(path, group: group, queue: queue)
            case .directory, .invalid:
                /* subdirectories' contents are also part of the enumerated sequence, so the directories themselves can be ignored */
                var shouldPass = false
                if path.pathExtension.lowercased() == "imageset" {
                    if let subPaths = try? FileManager.default.subpathsOfDirectory(atPath: path.relativePath) {
                        shouldPass = subPaths
                            .map({ path.appendingPathComponent($0) })
                            .map({ ($0, FileType($0)) })
                            .filter({ $0.1 == FileType.image })
                            .map({ $0.0 })
                            .compactMap({ url in
                                try? Data(contentsOf: url)
                            })
                            .map({ $0.count })
                            .filter({ $0 > 1024*100 })
                            .isEmpty
                    }
                    
                    if
                        !shouldPass,
                        let json = try? JSONSerialization.jsonObject(with: Data(contentsOf: path.appendingPathComponent("Contents.json")), options: .mutableLeaves) as? JSON,
						let images = json["images"] as? [[String: Any]] {
                        if !images.lazy.map({ !$0.lazy.filter({ $0.key.lowercased() == "resizing" }).isEmpty }).filter({ $0 }).isEmpty {
                            shouldPass = true
                        }
                    }
                }
                
                if shouldPass {
                    excludes.append(path)
                }
                
                continue
            }
            
        }
        
    }
    
    /// Convert a valid image to .heic
    ///
    /// - Parameter imageUrl: the file path to be converted
    /// - Parameter group: the DispatchGroup managing conversion work
    /// - Parameter queue: the serial queue to contain conversion work
    /// - Parameter deletingOriginals: Boolean flag to indicate whether images should be preserved in their original format after conversion
    func convertImage(_ imageUrl: URL, group: DispatchGroup, queue: DispatchQueue, deletingOriginals: Bool) {
        
        totalImages += 1
        
        group.enter()
        queue.async { [weak self] in
            
            guard let self = self else { return }
            
            guard case .image = FileType(imageUrl) else { return }
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
            
			let options = [kCGImageDestinationLossyCompressionQuality: self.quality]
			CGImageDestinationAddImageAndMetadata(destination, image, imageMetadata, options as CFDictionary)
            CGImageDestinationFinalize(destination)
            
            if deletingOriginals {
                try? FileManager.default.removeItem(at: imageUrl)
            }
            
            DispatchQueue.main.async {
                self.processedImages += 1
            }
            
            group.leave()
        }
        
    }
    
}

private extension ViewController {
	/// Update the contents.json file in an imageset to reflect new file type
	///
	/// - Parameter url: the file path to be processed
	/// - Parameter group: the DispatchGroup managing conversion work
	/// - Parameter queue: the serial queue to contain conversion work
	func updateContentsFile(_ url: URL, group: DispatchGroup, queue: DispatchQueue) {
		guard case .json = FileType(url) else { return }
		
		group.enter()
		queue.async { [weak self] in
			
			do {
				try self?.updateJSONContents(url)
			} catch let error {
				print(error)
			}
			
			group.leave()
		}
		
	}
	
	/// Attempt to translate a file path into JSON, process it, and overwrite the file with the result
	func updateJSONContents(_ url: URL) throws {
		guard let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url), options: .mutableLeaves) as? JSON else { return }
		let processed = try JSONSerialization.data(withJSONObject: processJSON(json), options: .prettyPrinted)
		try processed.write(to: url)
		
	}
	
	/// Traverse a json object, changing only the path extension of values keyed for filename
	func processJSON(_ json: JSON) -> JSON {
		var json = json
		for (k, v) in json {
			if k == "filename", let value = v as? String {
				for type in FileType.allowedImageTypes {
					let newValue = value.replacingOccurrences(of: ".\(type)", with: ".heic")
					if newValue != value {
						json[k] = newValue
					}
				}
			} else if let value = v as? JSON {
				json[k] = processJSON(value)
			} else if let values = v as? [JSON] {
				json[k] = values.compactMap({ return processJSON($0) })
			}
		}
		
		return json
	}
}
