//
//  AppDelegate.swift
//  DitherPicker
//
//  Created by FrostBird on 7/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Cocoa
import Preferences

extension PreferencePane.Identifier {
	static let Palette = Identifier("Palette")
}

struct Settings {
	static var Picker: Int = 0;
	static var Dither: Int = 0;
	static var Path: String = "/bin/echo";
	
	static func LoadSettings() {
		if (UserDefaults.standard.object(forKey: "Picker") == nil) {
			UserDefaults.standard.set(0, forKey: "Picker");
		}
		if (UserDefaults.standard.object(forKey: "Dither") == nil) {
			UserDefaults.standard.set(2, forKey: "Dither");
		}
		if (UserDefaults.standard.object(forKey: "GIMPPath") == nil) {
			UserDefaults.standard.set("/Applications/GIMP-2.10.app/Contents/MacOS/gimp-console", forKey: "GIMPPath");
		}
		
		Settings.Picker = UserDefaults.standard.integer(forKey: "Picker");
		Settings.Dither = UserDefaults.standard.integer(forKey: "Dither");
		Settings.Path = UserDefaults.standard.string(forKey: "GIMPPath")!;
	}
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	lazy var preferencesWindowController = PreferencesWindowController(
		preferencePanes: [
			SettingsViewController()
		]
	)
	
	@IBAction
	func preferencesMenuItemActionHandler(_ sender: NSMenuItem) {
		preferencesWindowController.show()
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		//Eh, no harm in running it here as well
		Settings.LoadSettings();
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true;
	}


}

