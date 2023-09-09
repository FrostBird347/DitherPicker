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
	var PickerImage: NSImage = NSImage(named: NSImage.statusUnavailableName)!;
	var PickerBitmap: NSBitmapImageRep? = nil;
	var NormalPickerBitmap: NSBitmapImageRep? = nil;
	var CurrentColour: NSColor = NSColor.clear;
	var PickerIndex: Int = 0;
	var ChosenPalette: String = "Default";
	var PickerImageList: [NSImage] = [];
	
	
	override func viewDidLoad() {
		super.viewDidLoad();
		
		Settings.LoadSettings();
		
		switch Settings.Picker {
			case 0:
				PickerImage = #imageLiteral(resourceName: "PickerFull-HSI");
			case 1:
				PickerImage = #imageLiteral(resourceName: "PickerFull-HSY");
				BrightnessSlider.floatValue = 0;
			case 2:
				PickerImage = #imageLiteral(resourceName: "PickerFull-HSL");
			default:
				PickerImage = NSImage(named: NSImage.cautionName)!;
		}
		
		
		// Do any additional setup after loading the view.
		NSLog("viewDidLoad");
		LoadPicker(FullPicker: PickerImage);
		
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
		
		//https://stackoverflow.com/a/32345031
		let HexR: Int = Int(round(PickerColour.color.redComponent * 0xFF));
		let HexG: Int = Int(round(PickerColour.color.greenComponent * 0xFF));
		let HexB: Int = Int(round(PickerColour.color.blueComponent * 0xFF));
		let HexString: String = String(NSString(format: "#%02X%02X%02X", HexR, HexG, HexB));
		
		NSPasteboard.general.setString(HexString, forType: NSPasteboard.PasteboardType.string);
	}
	
	@IBAction func UpdateBrightness(_ sender: NSSliderCell) {
		let tempValue: Int = Int(sender.intValue);
		
		if (tempValue != PickerIndex) {
			PickerIndex = tempValue;
			UpdateColourPreview();
			DisplayedPicker.image = PickerImageList[PickerIndex];
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
		let XShift: Int = (PickerIndex % 16) * 750;
		let YShift: Int  = Int(floor(Float(PickerIndex) / 16)) * 750;
		
		PickerColour.color = (NormalPickerBitmap?.colorAt(x: PickerX + XShift, y: PickerY + YShift))!;
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
		task.arguments?.append("(gimp-image-convert-indexed 1 " + String(Settings.Dither) + " 4 0 FALSE FALSE \"" + ChosenPalette + "\")");
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
		DisplayedPicker.image = PickerImageList[Int(BrightnessSlider.intValue)];
	}
	
}
