//
//  Public.swift
//  DitherPicker
//
//  Created by FrostBird on 19/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Foundation;
import SQOI;

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

func _qoi_linker_fix() {
	let testA: Any? = SQOI.qoi_padding;
	//Should be unreachable code
	if (testA == nil) {
		NSLog("???")
	}
}

func RawPickerToQOI(Input: Data) -> Data {
	var desc = qoi_desc(width: 12000, height: 12000, channels: 4, colorspace: 0);
	var size = Int32(Input.count);
	
	let InputPointer = Input.withUnsafeBytes({ $0.baseAddress });
	let Output = qoi_encode(InputPointer, &desc, &size);
	defer {
		Output?.deallocate();
	}
	
	return Data(bytes: Output!, count: Int(size));
}

func QOIToRawPicker(Input: Data) -> Data {
	var desc = qoi_desc(width: 0, height: 0, channels: 4, colorspace: 0);
	
	let InputPointer = Input.withUnsafeBytes({ $0.baseAddress });
	let Output = SQOI.qoi_decode(InputPointer, Int32(Input.count), &desc, Int32(4));
	defer {
		Output?.deallocate();
	}
	
	return Data(bytes: Output!, count: 12000 * 12000 * 4);
}

func LZMA(ShouldCompress: Bool, Input: Data) -> Data {
	
	NSLog("Saving LZMA input to temporary file...");
	let directory: String = NSTemporaryDirectory();
	let inputFile: URL = NSURL.fileURL(withPathComponents: [directory, NSUUID().uuidString + ".in"])!;
	let outputFile: URL = NSURL.fileURL(withPathComponents: [directory, NSUUID().uuidString + ".out"])!;
	try! Input.write(to: inputFile);
	
	var execMode = "d";
	if (ShouldCompress) {
		execMode = "e";
	}
	
	let task: Process = Process();
	let pipe: Pipe = Pipe();
	task.standardOutput = pipe;
	task.standardError = pipe;
	task.standardInput = nil;
	task.launchPath = Bundle.main.url(forResource: "lzma_alone", withExtension: "")!.path;
	
	task.arguments = [execMode, inputFile.path, outputFile.path];
	
	NSLog("Running LZMA...");
	task.launch();
	NSLog("Output below:\n" + String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!);
	NSLog("Reading data...");
	let output: Data = try! Data(contentsOf: outputFile);
	
	NSLog("Removing temporary files...");
	do {
		let fileManager = FileManager.init();
		try fileManager.removeItem(at: inputFile);
		try fileManager.removeItem(at: outputFile);
	} catch {}
	
	return output;
}
