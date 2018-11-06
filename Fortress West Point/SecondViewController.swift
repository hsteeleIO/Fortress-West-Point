
import UIKit
import SceneKit
import ARKit

class SecondViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var nodeModel:SCNNode!
    
    // Catch information provided from Google Maps ViewController
    var nodeName:String = ""
    var ARObjectName:String = ""
    var start:Bool = true
    
    @objc func onCloseButton(_sender:AnyObject){
        self.dismiss(animated:true,completion:nil )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // captures screen Size of the device
        let screenSize = UIScreen.main.bounds
        
        // captures the width of the device
        let screenWidth = screenSize.width
        
        // captures the height of the device
        let screenHeight = screenSize.height
        
        let closeButton = UIButton(frame : CGRect(x:screenWidth * 0.85,y:screenHeight * 0.05,width:screenWidth * 0.11,height:screenHeight * 0.06))
        closeButton.addTarget(self, action:#selector(self.onCloseButton) , for: .touchUpInside)
        let closeButtonImage = UIImage(named:"exit.png")
        closeButton.setImage(closeButtonImage, for: UIControlState.normal)
        closeButton.layer.cornerRadius = closeButton.frame.size.width/1.8
        closeButton.clipsToBounds = true
        closeButton.backgroundColor = UIColor.white
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.antialiasingMode = .multisampling4X
        
        // Create a new scene
        let scene = SCNScene(named: ARObjectName)
        
        // Set the scene to the view
        sceneView.scene = scene!
        self.view.addSubview(closeButton)
        
        //self.initialize()
    }
    
    func initialize() {
        let modelScene = SCNScene(named:ARObjectName)!
        self.nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: sceneView)
        
        // Let's test if a 3D Object was touch
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }
        
        // No object was touched? Try feature points
        if start == false {
            self.initialize()
        let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)
        
        if let hit = hitResultsFeaturePoints.first {
            
            // Get the rotation matrix of the camera
            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            
            // Combine the matrices
            let finalTransform = simd_mul(hit.worldTransform, rotate)
            sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
        }
        }
        start = false
        
    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                let modelScene = SCNScene(named:self.ARObjectName)!
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero
                
                // Add model as a child of the node
                node.addChildNode(modelClone)
            }
        }
    }
}



