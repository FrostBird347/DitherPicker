//
//  AppDelegate.swift
//  DitherPicker
//
//  Created by FrostBird on 7/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Cocoa;
import Preferences;

extension PreferencePane.Identifier {
	static let Palette = Identifier("Palette")
}

struct Settings {
	//Placeholder setting values
	//specify echo as gimp-console path so nothing goes too horribly wrong in the event that these values somehow remain
	static var Picker: Int = 0;
	static var Dither: Int = 0;
	static var Path: String = "/bin/echo";
	
	//Contains the actual default values
	static func LoadSettings() {
		if (UserDefaults.standard.object(forKey: "Picker") == nil) {
			UserDefaults.standard.set(2, forKey: "Picker");
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
		
		if (Settings.Picker < 0 || Settings.Picker > 4) {
			NSLog("Unknown picker value set!");
			UserDefaults.standard.removeObject(forKey: "Picker");
			NSLog("Reset the saved picker option, however the program will still attempt to run with the invalid picker once (and likely crash).");
		}
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
		preferencesWindowController.show();
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		//Print ascii art version of the logo
		NSLog("\n  D  I  T  H  E  R  \n             ::.    \n            /:::/   \n           ':::,    \n       .−−−/ /      \n     .'   / /.      \n   .'    ; /  '.    \n   :     ·'    :    \n   :           :    \n    '.       .'     \n      '.___.'       \n                    \n  P  I  C  K  E  R  ");
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	//Terminate the app after the last window is closed
	//Main window can't be re-opened when it's closed, so this will make it clearer to the user
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true;
	}


}

