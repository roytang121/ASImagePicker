//
//  AsyncImageCellNode.swift
//  AsyncDisplayGallery
//
//  Created by Roy Tang on 14/12/2016.
//  Copyright © 2016 Leaf Studio. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Photos

class AsyncImageCellNode: ASCellNode {
  
  var imageNode: ASImageNode!
  var assetLocalDescription: String?
  var itemSize: CGSize!
  
  var asset: PHAsset!
  weak var imageManager: PHCachingImageManager?
  
  var imageData: Data?
  
  override init() {
    super.init()
    
    self.automaticallyManagesSubnodes = true
    
    imageNode = ASImageNode()
    imageNode.placeholderFadeDuration = 0.2
    imageNode.clipsToBounds = true
    
    self.imageNode.isLayerBacked = true
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let ratioSpec = ASRatioLayoutSpec(ratio: 1.0, child: imageNode)
    
    let targetSize = CGSize(width: itemSize.width * UIScreen.main.scale, height: itemSize.height * UIScreen.main.scale)
    self.fetchAsset(asset: self.asset, imageManager: imageManager, withSize: targetSize)
    return ratioSpec
  }
  
  override func didEnterPreloadState() {
    super.didEnterPreloadState()
    
    guard let _data = self.imageData else { return }
    
    self.setImageWithData(data: _data)
  }
  
  override func didEnterDisplayState() {
    super.didEnterDisplayState()
    
//    self.fetchAsset(asset: self.asset, imageManager: self.imageManager, withSize: self.itemSize)
  }
  
  override func didExitPreloadState() {
    super.didExitPreloadState()
    
    setImageWithData(data: nil)
  }
  
  override func didExitVisibleState() {
    super.didExitVisibleState()
    
  }
  
  deinit {
    print("deinit node")
    self.imageNode.image = nil
    self.imageData = nil
    self.asset = nil
  }
  
  open func fetchAsset(asset: PHAsset, imageManager: PHImageManager?, withSize thumbnailSize: CGSize) {
    if self.imageNode.image == nil {
      
      let decodeImageOptions = PHImageRequestOptions()
      decodeImageOptions.resizeMode = .exact
      decodeImageOptions.deliveryMode = .opportunistic
      decodeImageOptions.isSynchronous = true
      
      imageManager?.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: decodeImageOptions, resultHandler: { (result, _) in
         
//        self.imageNode.image = result
        self.imageNode.image = result
        
        if let _image = result {
          self.imageData = UIImageJPEGRepresentation(_image, 0.4)
        }
      })
    }
  }
  
  open func fetchAssetData(asset: PHAsset, imageManager: PHImageManager, withSize thumbnailSize: CGSize) {
    
    imageManager.requestImageData(for: asset, options: nil) { (_data, _, _, _) in
      self.imageData = _data
      
      self.setImageWithData(data: _data)
    }
  }
  
  public func setImageWithData(data: Data?) {
    
    DispatchQueue.global().async {
      guard let _data = data else { self.imageNode.image = nil; return }
      self.imageNode.image = UIImage(data: _data)
    }
  }
}

extension UIImage {
  static func fromColor(color: UIColor) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(color.cgColor)
    context?.addRect(rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
}

extension ASImageNode {
//  open override func placeholderImage() -> UIImage? {
//    return UIImage.fromColor(color: UIColor.lightGray)
//  }
}
