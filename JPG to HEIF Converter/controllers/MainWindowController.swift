//
//  MainWindowController.swift
//  JPG to HEIF Converter
//
//  Created by Sergey Armodin on 21.05.2018.
//  Copyright © 2018 Sergey Armodin. All rights reserved.
//

import Cocoa


class MainWindowController: NSWindowController {
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		let appDelegate = NSApp.delegate as! AppDelegate
		appDelegate.mainWindowController = self
	}
	
}
