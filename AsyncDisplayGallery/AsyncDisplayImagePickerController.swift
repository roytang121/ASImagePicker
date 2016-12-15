//
//  AsyncDisplayImagePickerController.swift
//  AsyncDisplayGallery
//
//  Created by Roy Tang on 14/12/2016.
//  Copyright © 2016 Leaf Studio. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import Photos
import PhotosUI
import UIKit

class AsyncDisplayImagePickerController: ASViewController<ASDisplayNode> {
  
  var collectionNode: ASCollectionNode!
  var collectionViewLayout: UICollectionViewFlowLayout!
  
  var fetchResult: PHFetchResult<PHAsset>?
  
  var imageManager = PHCachingImageManager()
  
  var batchFetchContext: ASBatchContext?
  
  var page = 1
  
  var pageSize = 50
  
  var imageSizeWithScale: CGSize = CGSize(
    width: (UIScreen.main.bounds.width / 4.0),
    height: (UIScreen.main.bounds.width / 4.0))
  
  var pageBound: Int {
    return page * pageSize
  }
  
  init() {
    collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.sectionInset = UIEdgeInsets.zero
    collectionViewLayout.minimumLineSpacing = 0
    collectionViewLayout.minimumInteritemSpacing = 0
    
    let width = UIScreen.main.bounds.width / 4.0
    collectionViewLayout.itemSize = CGSize(width: width, height: width)
    
    collectionNode = ASCollectionNode(collectionViewLayout: collectionViewLayout)
    
    super.init(node: collectionNode)
    
    collectionNode.delegate = self
    collectionNode.dataSource = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.collectionNode.view.prefetchDataSource = self
//    var param = self.collectionNode.tuningParameters(for: .preload)
//    param.leadingBufferScreenfuls = 1
//    param.trailingBufferScreenfuls = 1
//    self.collectionNode.setTuningParameters(param, for: .preload)
    
    PHPhotoLibrary.shared().register(self)
    
    if self.fetchResult == nil {
      let allPhotosOptions = PHFetchOptions()
      allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
    }
  }
  
  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
    
    self.imageManager.stopCachingImagesForAllAssets()
    self.fetchResult = nil
  }
}

extension AsyncDisplayImagePickerController: ASCollectionDelegate, ASCollectionDataSource, UICollectionViewDataSourcePrefetching {
  func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
    
    guard let fetchCount = self.fetchResult?.count else { return 0 }
    
    if fetchCount > self.page * pageSize {
      return self.page * pageSize
    } else {
      return self.fetchResult?.count ?? 0
    }
  }
  
  func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
    guard let asset = self.fetchResult?.object(at: indexPath.item) else {
      return {
        return ASCellNode()
      }
    }
    
    return {
      let cell = AsyncImageCellNode()
      cell.itemSize = self.imageSizeWithScale
      cell.asset = asset
      cell.imageManager = self.imageManager
      return cell
    }
  }
  
  
  func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
    
    DispatchQueue.main.sync {
      context.beginBatchFetching()
      let startIndex = self.pageBound
      self.page += 1
      
      var insertedIndexs = [IndexPath]()
      (startIndex ..< self.pageBound).forEach { (i) in
        let insertIndexPath = IndexPath(item: i, section: 0)
        insertedIndexs.append(insertIndexPath)
      }
      
      self.collectionNode.insertItems(at: insertedIndexs)
      context.completeBatchFetching(true)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    
//    guard let _fetchResult = self.fetchResult else { return }
//    
//    let addAssets = indexPaths.map { indexPath in
//      _fetchResult.object(at: indexPath.item)
//    }
//    
//    imageManager.startCachingImages(for: addAssets, targetSize: imageSizeWithScale, contentMode: .aspectFill, options: nil)
//    
//    indexPaths.forEach { (indexPath) in
//      if let node = self.collectionNode.nodeForItem(at: indexPath) as? AsyncImageCellNode {
//        let asset = _fetchResult.object(at: indexPath.item)
//        self.imageManager.requestImage(for: asset, targetSize: self.imageSizeWithScale, contentMode: .aspectFill, options: nil, resultHandler: { (result, _) in
//          node.imageNode.image = result
//        })
//      }
//    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    guard let _fetchResult = self.fetchResult else { return }
    
    let removedAssets = indexPaths.map { indexPath in
      _fetchResult.object(at: indexPath.item)
    }
    
    imageManager.stopCachingImages(for: removedAssets, targetSize: imageSizeWithScale, contentMode: .aspectFill, options: nil)
//
//    print("stopCaching")
//    print(removedAssets.count)
//    
//    indexPaths.forEach { (indexPath) in
//      if let node = self.collectionNode.nodeForItem(at: indexPath) as? AsyncImageCellNode {
//        node.imageNode.image = nil
//      }
//    }
  }
  
  func collectionNode(_ collectionNode: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
    
  }
  
  func collectionNode(_ collectionNode: ASCollectionNode, didEndDisplayingItemWith node: ASCellNode) {
//    if let _imageNode = node as? AsyncImageCellNode {
//      _imageNode.imageNode.image = nil
//    }
//    if let indexPath = self.collectionNode.indexPath(for: node) {
//      imageManager.stopCachingImages(for: [fetchResult!.object(at: indexPath.item)], targetSize: imageSizeWithScale, contentMode: .aspectFill, options: nil)
//    }
  }
}

// MARK: PHPhotoLibraryChangeObserver
extension AsyncDisplayImagePickerController: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    
    guard let fetchResult = self.fetchResult else {
      return
    }
    
    guard let changes = changeInstance.changeDetails(for: fetchResult)
      else { return }
    
    // Change notifications may be made on a background queue. Re-dispatch to the
    // main queue before acting on the change as we'll be updating the UI.
    DispatchQueue.main.sync {
      // Hang on to the new fetch result.
      self.fetchResult = changes.fetchResultAfterChanges
      if changes.hasIncrementalChanges {
        
        // check if changes happen within pages
        var changedIndexesInRange: [IndexPath] = []
        var removedIndexesInRange: [IndexPath] = []
        var insertedIndexesInRange: [IndexPath] = []
        
        changes.changedIndexes?.forEach({ (index) in
          if index < self.pageBound {
            changedIndexesInRange.append(IndexPath(item: index, section: 0))
          }
        })
        
        changes.insertedIndexes?.forEach({ (index) in
          if index < self.pageBound {
            insertedIndexesInRange.append(IndexPath(item: index, section: 0))
          }
        })
        
        changes.removedIndexes?.forEach({ (index) in
          if index < self.pageBound {
            removedIndexesInRange.append(IndexPath(item: index, section: 0))
          }
        })
        
        
        // If we have incremental diffs, animate them in the collection view.
        collectionNode.performBatchUpdates({
          // For indexes to make sense, updates must be in this order:
          // delete, insert, reload, move
          if let removed = changes.removedIndexes, removed.count > 0 {
            self.collectionNode.deleteItems(at: removedIndexesInRange)
          }
          if let inserted = changes.insertedIndexes, inserted.count > 0 {
            self.collectionNode.insertItems(at: insertedIndexesInRange)
          }
          if let changed = changes.changedIndexes, changed.count > 0 {
            self.collectionNode.reloadItems(at: changedIndexesInRange)
          }
          changes.enumerateMoves { fromIndex, toIndex in
            self.collectionNode.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                    to: IndexPath(item: toIndex, section: 0))
          }
        })
      } else {
        // Reload the collection view if incremental diffs are not available.
        collectionNode!.reloadData()
      }
      
      self.batchFetchContext?.completeBatchFetching(true)
      self.batchFetchContext = nil
    }
  }
}
