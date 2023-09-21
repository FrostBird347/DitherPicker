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
		_qoi_linker_fix();
	}
	
	//Terminate the app after the last window is closed
	//Main window can't be re-opened when it's closed, so this will make it clearer to the user
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true;
	}


}

