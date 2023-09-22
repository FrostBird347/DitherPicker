//
//  ViewController.swift
//  DitherPicker
//
//  Created by FrostBird on 7/9/23.
//  Copyright © 2023 FrostBird347. All rights reserved.
//

import Cocoa;

class ViewController: NSViewController {
	
	@IBOutlet var PointerElement: NSImageView!;
	@IBOutlet var MainView: NSView!;
	@IBOutlet var CopyButton: NSButton!;
	@IBOutlet var PaletteInput: NSTextField!;
	@IBOutlet var PickerColour: NSColorWell!;
	@IBOutlet var DisplayedPicker: NSImageView!;
	@IBOutlet var BrightnessSlider: NSSlider!;
	
	var PickerX: Int = 0;
	var PickerY: Int = 749;
	var PickerImage: NSImage = NSImage(named: NSImage.statusUnavailableName)!;
	var PickerBitmap: NSBitmapImageRep? = nil;
	var NormalPickerRaw: Data = Data();
	var NormalPickerQOI: Data = Data();
	var CurrentColour: NSColor = NSColor.clear;
	var PickerIndex: Int = 0;
	var ChosenPalette: String = "";
	var PickerImageList: [NSImage] = [];
	var PickerLookup: [Int] = [];
	let PickerNames: [String] = ["HSV", "HSV-Invert", "HSL", "RGB", "BGR"];
	
	//When the app starts:
	// - Load settings
	// - Load the correct colour picker
	override func viewDidLoad() {
		super.viewDidLoad();
		
		Settings.LoadSettings();
		
		//use raw rgb data because xcode modifies the pixel values of the image, causing inconsistencies with the colour picker.
		NSLog("Extracting raw RGB data...");
		NormalPickerRaw = QOIToRawPicker(Input: LZMA(ShouldCompress: false, Input: NSDataAsset(name: "PickerFull-" + PickerNames[Settings.Picker])!.data));
		
		NSLog("Converting to CGImage...");
		let NormalPickerCI: CIImage = CIImage.init(bitmapData: NormalPickerRaw, bytesPerRow: 12000 * 4, size: CGSize.init(width: 12000, height: 12000), format: CIFormat.RGBA8, colorSpace: CGColorSpace.init(name: CGColorSpace.genericRGBLinear));
		let NormalPickerCG: CGImage = CIContext(options: nil).createCGImage(NormalPickerCI, from: NormalPickerCI.extent)!;
		
		switch Settings.Picker {
			case 0:
				BrightnessSlider.floatValue = 255;
			case 1:
				BrightnessSlider.floatValue = 0;
			case 2:
				BrightnessSlider.floatValue = 145;
			case 3:
				BrightnessSlider.floatValue = 255;
			case 4:
				BrightnessSlider.floatValue = 0;
			default:
				PickerColour.isEnabled = false;
				PickerColour.isBordered = false;
				PickerImage = NSImage(named: NSImage.cautionName)!;
		}
		PickerIndex = Int(BrightnessSlider.intValue);
		
		NSLog("Loading picker image...");
		LoadPicker(FullPicker: NormalPickerCG);
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
	
	//Runs when the user clicks on PointerElement
	@IBAction func UpdatePointerFallback(_ sender: NSPressGestureRecognizer) {
		UpdatePointer(sender);
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
		//Don't run at startup, because it freezes the program for quite a while
		if (PickerLookup.isEmpty) {
			//Load current picker's lookup table
			NSLog("RGB lookup array hasn't been loaded yet!");
			let PickerLookupRaw: Data = LZMA(ShouldCompress: false, Input: NSDataAsset(name: "PickerLookup-" + PickerNames[Settings.Picker])!.data);
			NSLog("Splitting raw data...");
			var PickerLookupRawString: String = String(data: PickerLookupRaw, encoding: .utf8)!;
			PickerLookupRawString.removeFirst();
			PickerLookupRawString.removeLast();
			let PickerLookupRawStrings: [String] = PickerLookupRawString.components(separatedBy: ",");
			NSLog("Converting relative values to absolute and building lookup array...");
			var LastX: Int = 0;
			var LastY: Int = 0;
			var iPL: Int = 0;
			var iPLPercent: Int = -20;
			let iPLMax: Int = PickerLookupRawStrings.count / 2;
			while (iPL < iPLMax) {
				if (iPL % Int(floor(Float(iPLMax) / Float(5))) == 0) {
					iPLPercent += 20;
					NSLog(String(iPLPercent) + "%% complete");
				}
				
				var currentX: Int = (LastX + Int(PickerLookupRawStrings[iPL])!) % 12000;
				if (currentX < 0) {
					currentX += 12000;
				}
				
				var currentY: Int = (LastY + Int(PickerLookupRawStrings[iPL + iPLMax])!) % 12000;
				if (currentY < 0) {
					currentY += 12000;
				}
				
				PickerLookup.append(currentX);
				PickerLookup.append(currentY);
				
				LastX = currentX;
				LastY = currentY;
				iPL += 1;
			}
			NSLog("Done!");
		}
		
		//When the pointer is first set, enable the copy button
		if (PointerElement.frame.origin.x < 0) {
			CopyButton.isEnabled = true;
		}
		
		var TargetColour: NSColor = sender.color;
		if (TargetColour.colorSpace.colorSpaceModel != NSColorSpace.Model.rgb) {
			TargetColour = TargetColour.usingColorSpace(NSColorSpace.genericRGB)!;
		}
		
		let TargetColourR: Int = Int(round(TargetColour.redComponent * 0xFF));
		let TargetColourG: Int = Int(round(TargetColour.greenComponent * 0xFF));
		let TargetColourB: Int = Int(round(TargetColour.blueComponent * 0xFF));
		
		let LookupIndex: Int = 2 * ( (TargetColourR * 256 * 256) + (TargetColourG * 256) + TargetColourB );
		let TargetX: Int = PickerLookup[LookupIndex];
		let TargetY: Int = PickerLookup[LookupIndex + 1];
		
		//Get slider level
		let SliderPos: Int = Int( floor(Float(TargetX) / 750) + ( floor(Float(TargetY) / 750) * 16 ) );
		BrightnessSlider.floatValue = Float(SliderPos);
		PickerIndex = SliderPos;
		DisplayedPicker.image = PickerImageList[PickerIndex];
		
		//Get pointer pos
		PickerX = TargetX % 750;
		PickerY = TargetY % 750;
		PickerY = 749 - PickerY;
		PointerElement.frame.origin.x = min(max(CGFloat(PickerX), 5), 754) - 15;
		PointerElement.frame.origin.y = min(max(CGFloat(PickerY), 5), 754) - 15;
		PickerY = 749 - PickerY;
		
		//Update the picker incase the selected colour doesn't exist on the picker
		UpdateColourPreview();
		
		//Make the picker show a different texture if the selected colour doesn't exist
		if (round(sender.color.redComponent * 0xFF) != round(TargetColour.redComponent * 0xFF) || round(sender.color.greenComponent * 0xFF) != round(TargetColour.greenComponent * 0xFF) || round(sender.color.blueComponent * 0xFF) != round(TargetColour.blueComponent * 0xFF)) {
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
		
		let channelCount: Int = 4;
		let RawIndex: Int = ( (PickerX + XShift) + (PickerY + YShift) * 12000) * channelCount;
		let RawPixelData: [UInt8] = [NormalPickerRaw[RawIndex], NormalPickerRaw[RawIndex + 1], NormalPickerRaw[RawIndex + 2], NormalPickerRaw[RawIndex + 3]];
		
		PickerColour.color = NSColor.init(red: CGFloat(RawPixelData[0]) / 0xFF, green: CGFloat(RawPixelData[1]) / 0xFF, blue: CGFloat(RawPixelData[2]) / 0xFF, alpha: 1);
	}
	
	//Very slow function that uses GIMP to apply a colour palette to the picker texture
	func UpdatePicker() {
		
		if (NormalPickerQOI.isEmpty) {
			NSLog("Converting raw RGB data to qoi...");
			NormalPickerQOI = RawPickerToQOI(Input: NormalPickerRaw);
		}
		
		NSLog("Saving normal picker texture to temporary location...");
		
		let directory: String = NSTemporaryDirectory();
		let fileName: String = NSUUID().uuidString + ".qoi";
		let fullURL: URL = NSURL.fileURL(withPathComponents: [directory, fileName])!;
		
		do {
			try NormalPickerQOI.write(to: fullURL);
		} catch {}
		
		//The texture is 12000x12000 and gimp is slow to load and save files
		//I won't use alternatives such as imagemagick because dither is applied differently
		//This issue has been improved a little by using QOI instead of tiff
		NSLog("Applying new palette to the texture... (this will take a while)");
		
		let task: Process = Process();
		let pipe: Pipe = Pipe();
		
		task.standardOutput = pipe;
		task.standardError = pipe;
		task.standardInput = nil;
		task.launchPath = "/Applications/GIMP-2.10.app/Contents/MacOS/gimp-console";
		task.arguments = ["-b", "(file-qoi-load 1 \"" + fullURL.path + "\" \"" + fullURL.path + "\")"];
		task.arguments?.append("-b");
		task.arguments?.append("(gimp-image-convert-indexed 1 " + String(Settings.Dither) + " 4 0 FALSE FALSE \"" + ChosenPalette + "\")");
		task.arguments?.append("-b");
		task.arguments?.append("(file-qoi-save 0 1 1 \"" + fullURL.path + "\" \"" + fullURL.path + "\")");
		task.arguments?.append("-b");
		task.arguments?.append("(gimp-quit 1)");
		
		NSLog("GIMP arguments: [\n\t'" + task.arguments!.joined(separator: "',\n\t'") + "'\n]");
		task.launch()
		
		let data = pipe.fileHandleForReading.readDataToEndOfFile();
		let output = String(data: data, encoding: .utf8)!;
		NSLog("Applied palette, output below:\n" + output);
		
		NSLog("Converting to raw RGB data...");
		var ConvertedPicker: Data? = nil;
		do {
			ConvertedPicker = QOIToRawPicker(Input: try Data(contentsOf: fullURL));
		} catch {}
		
		NSLog("Converting to CGImage...");
		let NormalPickerCI: CIImage = CIImage.init(bitmapData: ConvertedPicker!, bytesPerRow: 12000 * 4, size: CGSize.init(width: 12000, height: 12000), format: CIFormat.RGBA8, colorSpace: CGColorSpace.init(name: CGColorSpace.genericRGBLinear));
		let NormalPickerCG: CGImage = CIContext(options: nil).createCGImage(NormalPickerCI, from: NormalPickerCI.extent)!;
		LoadPicker(FullPicker: NormalPickerCG);
		
		NSLog("Removing temporary file...");
		do {
			let fileManager = FileManager.init();
			try fileManager.removeItem(at: fullURL);
		} catch {}
		
		NSLog("Done!");
	}
	
	func LoadPicker(FullPicker: CGImage) {
		NSLog("Updating picker texture...");
		PickerImageList.removeAll();
		
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
			CurrentPickerCG = FullPicker.cropping(to: Rect);
			CurrentPicker = NSImage(cgImage: CurrentPickerCG!, size: .zero);
			
			PickerImageList.append(CurrentPicker!);
			i += 1;
		}
		
		DisplayedPicker.image = PickerImageList[PickerIndex];
	}
	
}
