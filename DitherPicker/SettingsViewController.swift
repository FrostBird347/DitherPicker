//
//  SettingsViewController.swift
//  DitherPicker
//
//  Created by FrostBird on 8/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Cocoa
import Preferences

//I wouldn't be surprised if there was an actual api for loading and reading values
//I didn't try to wrap my head around how the example settings panel works in this regard
//Instead I just added a button to save the settings and relaunch the app
class SettingsViewController: NSViewController, PreferencePane {
	let preferencePaneIdentifier = PreferencePane.Identifier.Palette
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(named: NSImage.colorPanelName)!
	
	@IBOutlet var ColourSelection: NSPopUpButton!
	@IBOutlet var DitherSelection: NSPopUpButton!
	@IBOutlet var GIMPPath: NSTextField!
	
	override var nibName: NSNib.Name? { "SettingsViewController" }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Setup stuff here
		ColourSelection.selectItem(at: Settings.Picker);
		DitherSelection.selectItem(at: Settings.Dither);
		GIMPPath.stringValue = Settings.Path;
	}
	
	@IBAction func UpdateSettings(_ sender: NSButton) {
		//Storing the values incase something goes horribly wrong (e.g values being nil)
		//That way there is no chance of the values somehow still being saved
		Settings.Picker = ColourSelection.indexOfSelectedItem;
		Settings.Dither = DitherSelection.indexOfSelectedItem;
		Settings.Path = GIMPPath.stringValue;
		
		UserDefaults.standard.set(Settings.Picker, forKey: "Picker");
		UserDefaults.standard.set(Settings.Dither, forKey: "Dither");
		UserDefaults.standard.set(Settings.Path, forKey: "GIMPPath");
		
		//https://github.com/sindresorhus/Settings/blob/v1.0.1/Example/util.swift
		NSWorkspace.shared.launchApplication(withBundleIdentifier: Bundle.main.bundleIdentifier!, options: .newInstance, additionalEventParamDescriptor: nil, launchIdentifier: nil);
		NSApp.terminate(nil);
	}
}
