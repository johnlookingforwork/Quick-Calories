//
//  ImageProcessor.swift
//  QuickCalories
//
//  Created by John N on 2/20/26.
//

import UIKit

enum ImageProcessorError: LocalizedError {
    case compressionFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidImage:
            return "Invalid image format"
        }
    }
}

struct ImageProcessor {
    
    /// Maximum dimension (width or height) for processed images
    /// Balances quality vs API cost. OpenAI recommends <= 2048px
    static let maxDimension: CGFloat = 1024
    
    /// JPEG compression quality (0.0 - 1.0)
    /// 0.8 provides good balance between size and quality
    static let compressionQuality: CGFloat = 0.8
    
    /// Process an image for OpenAI Vision API
    /// - Parameter image: Original UIImage
    /// - Returns: Base64 encoded JPEG string with data URI prefix
    static func processForVisionAPI(_ image: UIImage) throws -> String {
        // Resize to max dimension
        let resizedImage = resize(image, maxDimension: maxDimension)
        
        // Convert to JPEG data
        guard let jpegData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw ImageProcessorError.compressionFailed
        }
        
        // Convert to base64
        let base64String = jpegData.base64EncodedString()
        
        // Return with data URI prefix
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    /// Resize image maintaining aspect ratio
    /// - Parameters:
    ///   - image: Original image
    ///   - maxDimension: Maximum width or height
    /// - Returns: Resized UIImage
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resize needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            // Landscape or square
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Portrait
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /// Estimate the approximate token cost for an image
    /// Based on OpenAI's pricing: vision tokens = (width * height) / 750
    /// - Parameter image: Image to estimate
    /// - Returns: Approximate token count
    static func estimateTokenCost(_ image: UIImage) -> Int {
        let size = image.size
        let pixels = size.width * size.height
        return Int(pixels / 750)
    }
    
    /// Get human-readable file size
    /// - Parameter image: Image to measure
    /// - Returns: Formatted string (e.g., "1.2 MB")
    static func formattedFileSize(_ image: UIImage) -> String? {
        guard let jpegData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        let bytes = jpegData.count
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
