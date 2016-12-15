//
//  ViewController.swift
//  AsyncDisplayGallery
//
//  Created by Roy Tang on 14/12/2016.
//  Copyright © 2016 Leaf Studio. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    let presentButton = UIBarButtonItem(title: "Present", style: .done, target: self, action: #selector(self.presentButtonPressed(sender:)))
    
    self.navigationItem.rightBarButtonItem = presentButton
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func presentButtonPressed(sender: AnyObject) {
    let vc = AsyncDisplayImagePickerController()
    self.navigationController?.pushViewController(vc, animated: true)
  }


}

