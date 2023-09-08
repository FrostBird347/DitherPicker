//
//  ViewController.swift
//  DitherPicker
//
//  Created by FrostBird on 7/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	
	@IBOutlet var PointerElement: NSImageView!
	@IBOutlet var MainView: NSView!
	@IBOutlet var CopyButton: NSButton!
	@IBOutlet var PaletteInput: NSTextField!
	@IBOutlet var PickerColour: NSColorWell!
	@IBOutlet var DisplayedPicker: NSImageView!
	@IBOutlet var BrightnessSlider: NSSlider!
	
	var PickerX: Int = 0;
	var PickerY: Int = 749;
	var SinglePickerImage: NSImage = #imageLiteral(resourceName: "Picker");
	var SinglePickerBitmap: NSBitmapImageRep? = nil;
	var PickerImage: NSImage = #imageLiteral(resourceName: "PickerFull");
	var PickerBitmap: NSBitmapImageRep? = nil;
	var NormalPickerBitmap: NSBitmapImageRep? = nil;
	var CurrentColour: NSColor = NSColor.clear;
	var ColourMult: CGFloat = 1;
	var ChosenPalette: String = "Default";
	var PickerImageList: [NSImage] = [];
	
	
	override func viewDidLoad() {
		super.viewDidLoad();
		
		

		// Do any additional setup after loading the view.
		NSLog("viewDidLoad");
		LoadPicker(FullPicker: PickerImage);
		
		let SinglePickerCG = SinglePickerImage.cgImage(forProposedRect: nil, context: nil, hints: nil);
		SinglePickerBitmap = NSBitmapImageRep(cgImage: SinglePickerCG!);
		
		let NormalPickerCG = PickerImage.cgImage(forProposedRect: nil, context: nil, hints: nil);
		NormalPickerBitmap = NSBitmapImageRep(cgImage: NormalPickerCG!);
		
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func CopyHex(_ sender: NSButton) {
		NSLog("CopyHex");
		UpdateColourPreview();
	}
	
	@IBAction func UpdateBrightness(_ sender: NSSliderCell) {
		let tempValue:CGFloat = CGFloat(sender.floatValue / 255);
		
		if (tempValue != ColourMult) {
			ColourMult = tempValue;
			UpdateColourPreview();
			DisplayedPicker.image = PickerImageList[Int(sender.intValue)];
		}
	}
	
	@IBAction func ProcessPalette(_ sender: NSTextField) {
		if (sender.stringValue != ChosenPalette) {
			NSLog("ProcessPalette");
			
			ChosenPalette = sender.stringValue;
			UpdatePicker();
		}
	}
	
	@IBAction func UpdatePointer(_ sender: NSPressGestureRecognizer) {
		
		//When the pointer is first clicked, enable the copy button
		if (PointerElement.frame.origin.x < 0) {
			CopyButton.isEnabled = true;
		}
		
		let RawLocation:NSPoint = sender.location(in: MainView);
		PointerElement.frame.origin.x = min(max(RawLocation.x, 5), 754) - 15;
		PointerElement.frame.origin.y = min(max(RawLocation.y, 5), 754) - 15;
		
		let LastPickerX: Int = PickerX;
		let LastPickerY: Int = PickerY;
		
		PickerX = Int(round(PointerElement.frame.origin.x + 10));
		PickerY = Int(round(749 - (PointerElement.frame.origin.y + 10)));
		
		if (LastPickerX != PickerX || LastPickerY != PickerY) {
			//NSLog(PickerX.description + "," + PickerY.description);
			UpdateColourPreview();
		}
	}
	
	func UpdateColourPreview() {
		CurrentColour = (SinglePickerBitmap?.colorAt(x: PickerX, y: PickerY))!;
		CurrentColour = CurrentColour.blended(withFraction: 1 - ColourMult, of: NSColor.black)!;
		PickerColour.color = CurrentColour;
	}
	
	func UpdatePicker() {
		NSLog("UpdatePicker");
		
		let PickerRaw: Data = (NormalPickerBitmap!.tiffRepresentation)!;
		
		let directory: String = NSTemporaryDirectory();
		let fileName: String = NSUUID().uuidString + ".tiff";
		let fullURL: URL = NSURL.fileURL(withPathComponents: [directory, fileName])!;
		
		do {
			try PickerRaw.write(to: fullURL);
		} catch {}
		
		let task: Process = Process();
		let pipe: Pipe = Pipe();
		
		
		task.standardOutput = pipe;
		task.standardError = pipe;
		task.standardInput = nil;
		task.launchPath = "/Applications/GIMP-2.10.app/Contents/MacOS/gimp-console"
		task.arguments = ["-b", "(file-tiff-load 1 \"" + fullURL.path + "\" \"" + fullURL.path + "\")"];
		task.arguments?.append("-b");
		task.arguments?.append("(gimp-image-convert-indexed 1 2 4 0 FALSE FALSE \"" + ChosenPalette + "\")");
		task.arguments?.append("-b");
		task.arguments?.append("(file-tiff-save 1 1 1 \"" + fullURL.path + "\" \"" + fullURL.path + "\" 2)");
		task.arguments?.append("-b");
		task.arguments?.append("(gimp-quit 1)");
		
		NSLog(task.arguments!.joined(separator: " "));
		
		task.launch()
		
		let data = pipe.fileHandleForReading.readDataToEndOfFile();
		let output = String(data: data, encoding: .utf8)!
		
		NSLog(output);
		
		var ConvertedPicker: Data? = nil;
		do {
			ConvertedPicker = try Data(contentsOf: fullURL);
		} catch {}
		LoadPicker(FullPicker: NSImage(data: ConvertedPicker!)!);
		
		
		do {
			let fileManager = FileManager.init();
			try fileManager.removeItem(at: fullURL);
		} catch {}
	}
	
	func LoadPicker(FullPicker: NSImage) {
		PickerImageList.removeAll();
		
		let PickerCG = FullPicker.cgImage(forProposedRect: nil, context: nil, hints: nil);
		PickerBitmap = NSBitmapImageRep(cgImage: PickerCG!);
		
		var i: Int = 0;
		var X: Int;
		var Y: Int;
		var Rect: CGRect;
		var CurrentPickerCG: CGImage?;
		var CurrentPicker: NSImage?;
		while (i < 256) {
			X = (i % 16);
			Y = Int(floor(Float(i) / 16));
			
			Rect = CGRect(x: X * 750, y: Y * 750, width: 750, height: 750);
			CurrentPickerCG = PickerCG!.cropping(to: Rect);
			CurrentPicker = NSImage(cgImage: CurrentPickerCG!, size: .zero);
			
			PickerImageList.append(CurrentPicker!);
			i += 1;
		}
		
		DisplayedPicker.image = PickerImageList[Int(BrightnessSlider.intValue)];
	}
	
}
