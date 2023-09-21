//
//  Public.swift
//  DitherPicker
//
//  Created by FrostBird on 19/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Foundation;
import SQOI;

func _qoi_linker_fix() {
	let testA: Any? = SQOI.qoi_padding;
	//Should be unreachable code
	if (testA == nil) {
		NSLog("???")
	}
}

func RawPickerToQOI(Input: Data) -> Data {
	
	_qoi_linker_fix();
	
	var desc = qoi_desc(width: 12000, height: 12000, channels: 4, colorspace: 0);
	var size = Int32(Input.count);
	
	let InputPointer = Input.withUnsafeBytes({ $0.baseAddress });
	let Output = qoi_encode(InputPointer, &desc, &size);
	defer {
		Output?.deallocate();
	}
	
	return Data(bytes: Output!, count: Int(size));
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
