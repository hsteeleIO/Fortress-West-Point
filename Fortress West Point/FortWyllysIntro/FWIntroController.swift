//
//  FWIntro.swift
//  Fortress West Point
//
//  Created by Daniel An on 1/23/19.
//  Copyright © 2019 C3T Hacker. All rights reserved.
//


import UIKit
import SpriteKit
import GameplayKit

class FWIntroController: UIViewController {
    
    @IBOutlet weak var fortwyllys: UIImageView!
    @IBOutlet weak var scrollbox: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollbox.clipsToBounds = true;
        scrollbox.layer.cornerRadius = 10.0;
        scrollbox.layer.borderColor = UIColor.gray.cgColor
        scrollbox.layer.borderWidth = 1
        scrollbox.layer.shadowColor = UIColor.black.cgColor
        scrollbox.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        scrollbox.layer.shadowOpacity = 1.0
        scrollbox.layer.shadowRadius = 2.0
        
        fortwyllys.layer.borderColor = UIColor.gray.cgColor
        fortwyllys.layer.borderWidth = 1
        fortwyllys.layer.shadowColor = UIColor.black.cgColor
        fortwyllys.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        fortwyllys.layer.shadowOpacity = 1.0
        fortwyllys.layer.shadowRadius = 2.0
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "FWIntroScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
