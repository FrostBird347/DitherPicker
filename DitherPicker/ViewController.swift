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
	var ChosenPalette: String = "";
	var PickerImageList: [NSImage] = [];
	
	//When the app starts:
	// - Load settings
	// - Load the correct colour picker
	override func viewDidLoad() {
		super.viewDidLoad();
		
		Settings.LoadSettings();
		
		switch Settings.Picker {
			case 0:
				PickerImage = #imageLiteral(resourceName: "PickerFull-HSV");
				PickerColour.isEnabled = false;
				PickerColour.isBordered = false;
			case 1:
				PickerImage = #imageLiteral(resourceName: "PickerFull-HSV-Invert");
				BrightnessSlider.floatValue = 0;
				PickerColour.isEnabled = false;
				PickerColour.isBordered = false;
			case 2:
				PickerImage = #imageLiteral(resourceName: "PickerFull-HSL");
				BrightnessSlider.floatValue = 145;
			default:
				PickerImage = NSImage(named: NSImage.cautionName)!;
		}
		
		PickerIndex = Int(BrightnessSlider.intValue);
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
		//Colour preview should already be accurate, but just incase we should update it
		UpdateColourPreview();
		
		//https://stackoverflow.com/a/32345031
		let HexR: Int = Int(round(PickerColour.color.redComponent * 0xFF));
		let HexG: Int = Int(round(PickerColour.color.greenComponent * 0xFF));
		let HexB: Int = Int(round(PickerColour.color.blueComponent * 0xFF));
		let HexString: String = String(NSString(format: "#%02X%02X%02X", HexR, HexG, HexB));
		
		//Clipboard must be cleared before we can copy
		NSPasteboard.general.clearContents();
		NSPasteboard.general.setString(HexString, forType: NSPasteboard.PasteboardType.string);
		
		NSSound(named: NSSound.Name("Pop"))!.play();
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
			NSLog("New palette specified!");
			
			ChosenPalette = sender.stringValue;
			UpdatePicker();
		}
	}
	
	@IBAction func UpdatePointer(_ sender: NSPressGestureRecognizer) {
		//When the pointer is first set, enable the copy button
		if (PointerElement.frame.origin.x < 0) {
			CopyButton.isEnabled = true;
		}
		
		//Get the click location, making sure to clamp it at the image bounds
		let RawLocation:NSPoint = sender.location(in: MainView);
		PointerElement.frame.origin.x = min(max(RawLocation.x, 5), 754) - 15;
		PointerElement.frame.origin.y = min(max(RawLocation.y, 5), 754) - 15;
		
		let LastPickerX: Int = PickerX;
		let LastPickerY: Int = PickerY;
		
		//Offset click position to place the circle in the middle
		PickerX = Int(round(PointerElement.frame.origin.x + 10));
		PickerY = Int(round(749 - (PointerElement.frame.origin.y + 10)));
		
		if (LastPickerX != PickerX || LastPickerY != PickerY) {
			//NSLog(PickerX.description + "," + PickerY.description);
			UpdateColourPreview();
		}
		
		PointerElement.image = #imageLiteral(resourceName: "Pointer-Normal");
	}
	
	@IBAction func FindColour(_ sender: NSColorWell) {
		//When the pointer is first set, enable the copy button
		if (PointerElement.frame.origin.x < 0) {
			CopyButton.isEnabled = true;
		}
		
		let targetColour: NSColor = sender.color.usingColorSpace(NSColorSpace.genericRGB)!;
		
		switch Settings.Picker {
			//HSV
			case 0:
				BrightnessSlider.floatValue = Float(round((targetColour.redComponent + targetColour.greenComponent + targetColour.blueComponent) * 255 / 3));
				NSLog("Not implemented yet!");
			//HSV Inverted
			case 1:
				NSLog("Not implemented yet!");
			//HSL
			case 2:
				//Get image tile
				BrightnessSlider.floatValue = Float(round(targetColour.hueComponent * 255));
				PickerIndex = Int(round(targetColour.hueComponent * 255));
				DisplayedPicker.image = PickerImageList[PickerIndex];
				
				//Get picker pos
				PickerX = Int(round(targetColour.saturationComponent * 749));
				PickerY = Int(round(targetColour.brightnessComponent * 749));
				PointerElement.frame.origin.x = min(max(CGFloat(PickerX), 5), 754) - 15;
				PointerElement.frame.origin.y = min(max(CGFloat(PickerY), 5), 754) - 15;
				PickerY = 749 - PickerY;
				
			default:
				NSLog("Can't find any colours with an unknown picker!");
		}
		//Update the picker incase something went wrong above
		UpdateColourPreview();
		
		if (round(sender.color.redComponent * 0xFF) != round(targetColour.redComponent * 0xFF) || round(sender.color.greenComponent * 0xFF) != round(targetColour.greenComponent * 0xFF) || round(sender.color.blueComponent * 0xFF) != round(targetColour.blueComponent * 0xFF)) {
			PointerElement.image = #imageLiteral(resourceName: "Pointer-Imprecise");
		} else {
			PointerElement.image = #imageLiteral(resourceName: "Pointer-Normal");
		}
	}
	
	//Calculate currently selected colour
	func UpdateColourPreview() {
		//Figure out where the current tile is
		let XShift: Int = (PickerIndex % 16) * 750;
		let YShift: Int  = Int(floor(Float(PickerIndex) / 16)) * 750;
		
		PickerColour.color = (NormalPickerBitmap!.colorAt(x: PickerX + XShift, y: PickerY + YShift))!;
	}
	
	//Very slow function that uses GIMP to apply a colour palette to the picker texture
	func UpdatePicker() {
		NSLog("Saving normal picker texture to temporary location...");
		
		let PickerRaw: Data = (NormalPickerBitmap!.tiffRepresentation)!;
		
		let directory: String = NSTemporaryDirectory();
		let fileName: String = NSUUID().uuidString + ".tiff";
		let fullURL: URL = NSURL.fileURL(withPathComponents: [directory, fileName])!;
		
		do {
			try PickerRaw.write(to: fullURL);
		} catch {}
		
		//The texture is 12000x12000 and gimp is slow to load and save files
		//I won't use alternatives such as imagemagick because dither is applied differently
		NSLog("Applying new palette to the texture... (this will take a while)");
		
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
		
		NSLog("GIMP arguments: [\n\t'" + task.arguments!.joined(separator: "',\n\t'") + "'\n]");
		task.launch()
		
		let data = pipe.fileHandleForReading.readDataToEndOfFile();
		let output = String(data: data, encoding: .utf8)!
		
		NSLog("Applied palette, output below:\n" + output);
		NSLog("Loading new texture...");
		
		var ConvertedPicker: Data? = nil;
		do {
			ConvertedPicker = try Data(contentsOf: fullURL);
		} catch {}
		LoadPicker(FullPicker: NSImage(data: ConvertedPicker!)!);
		
		NSLog("Removing temporary file...");
		do {
			let fileManager = FileManager.init();
			try fileManager.removeItem(at: fullURL);
		} catch {}
		
		NSLog("Done!");
	}
	
	func LoadPicker(FullPicker: NSImage) {
		NSLog("Updating picker texture...");
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
		
		DisplayedPicker.image = PickerImageList[PickerIndex];
	}
	
}
