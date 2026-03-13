//
//  ImageMetadataExtractor.swift
//  QuickCalories
//
//  Created by John N on 3/13/26.
//

import UIKit
import ImageIO

struct CameraMetadata: Codable {
    let deviceModel: String
    let cameraLensType: String?
    let focalLength: Double?
    let focalLength35mmEquivalent: Int?
    let aperture: Double?
    let imageWidth: Int
    let imageHeight: Int
    let pixelDensity: Double?
    
    var formattedDescription: String {
        var parts: [String] = [deviceModel]
        
        if let lens = cameraLensType {
            parts.append(lens)
        }
        if let focal = focalLength35mmEquivalent {
            parts.append("\(focal)mm")
        }
        if let aperture = aperture {
            parts.append("f/\(String(format: "%.1f", aperture))")
        }
        
        return parts.joined(separator: ", ")
    }
}

struct ImageMetadataExtractor {
    
    static func extractMetadata(from image: UIImage) -> CameraMetadata? {
        let exifData = extractEXIF(from: image)
        let deviceModel = currentDeviceModel()
        let imageSize = image.size
        
        return CameraMetadata(
            deviceModel: deviceModel,
            cameraLensType: exifData?.lensType,
            focalLength: exifData?.focalLength,
            focalLength35mmEquivalent: exifData?.focalLength35mm,
            aperture: exifData?.aperture,
            imageWidth: Int(imageSize.width),
            imageHeight: Int(imageSize.height),
            pixelDensity: image.scale * 72
        )
    }
    
    private static func extractEXIF(from image: UIImage) -> EXIFData? {
        guard let imageData = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        
        guard let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
            return nil
        }
        
        let focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double
        let focalLength35mm = exif[kCGImagePropertyExifFocalLenIn35mmFilm as String] as? Int
        let aperture = exif[kCGImagePropertyExifFNumber as String] as? Double
        
        var lensType: String?
        if let focal35 = focalLength35mm {
            switch focal35 {
            case 0..<20: lensType = "Ultra Wide"
            case 20..<35: lensType = "Wide"
            case 35..<75: lensType = "Standard"
            default: lensType = "Telephoto"
            }
        }
        
        return EXIFData(
            focalLength: focalLength,
            focalLength35mm: focalLength35mm,
            aperture: aperture,
            lensType: lensType
        )
    }
    
    private static func currentDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return deviceName(for: identifier)
    }
    
    private static func deviceName(for identifier: String) -> String {
        switch identifier {
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        default:
            return UIDevice.current.model
        }
    }
}

private struct EXIFData {
    let focalLength: Double?
    let focalLength35mm: Int?
    let aperture: Double?
    let lensType: String?
}
