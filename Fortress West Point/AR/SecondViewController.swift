
import UIKit
import SceneKit
import ARKit

class SecondViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //configuration.planeDetection = .horizontal
    
    let objectList = [
        Gobjects(name: "Castle", ARObject:"art.scnassets/castle/castle.dae",node:"Castle"),
        Gobjects(name: "Clinton Hat", ARObject:"art.scnassets/hat/clinton.dae",node:"Clinton2"),
        Gobjects(name: "COL Tadeusz Kościuszko Map", ARObject:"art.scnassets/map/kucz.dae",node:"Map"),
        Gobjects(name: "LT Thomas Machin Quill",  ARObject:"art.scnassets/Quill/machin.dae", node:"Machin1"),
        Gobjects(name:"Townsend Anvil", ARObject:"art.scnassets/hammerAnvil/hammerAnvil2.dae", node:"Townsend1"),
        Gobjects(name: "Musket", ARObject:"art.scnassets/carbine/Carbine.dae", node:"Carbine")]
    
    @IBOutlet var sceneView: ARSCNView!
    var nodeModel: SCNNode!
    
    // Catch information provided from Google Maps ViewController
    // The node name as seen in the node inspector
    var nodeName:String = "Castle"
    // Initialized as the fort (for now stand in castle object), needed to be the full path name
    var ARObjectName:String = "art.scnassets/castle/castle.dae"
    // Global object anchor
    var anchor:ARAnchor!
    // Global object Variable (will only allow one object on the scene at a time)
    var LastARObject:SCNNode!
    // Last object rendered name
    var lastObjectName:String = "Castle"
    // Global variable storing the last 3d transform
    var lastTransform:simd_float4x4!
    // Variable for determining if an object is present
    var objectPresent:Bool = false
    
    //global var for storing current angle of object
    var currentAngleY: Float = 0.0
    //global var for storing current scale of object
    var currentScale: Float = 1.0
    
    @IBAction func CloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func onCloseButton(_sender:AnyObject){
        self.dismiss(animated:true,completion:nil)
        //let vc = segue.destination as? SecondViewController
        //self.unwind(for: vc, towardsViewController: TitleViewController)
    }
    /////picker////
    @IBOutlet weak var objectPicker: UIPickerView!
    
    @IBOutlet weak var curObject: UILabel!
    
    @IBOutlet weak var loadObject: UILabel!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return objectList[row].name
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return objectList.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        curObject.text = objectList[row].name
        nodeName = objectList[row].node
        ARObjectName = objectList[row].ARObject
    }
    
    @IBAction func SwitchObject(_ sender: UIButton) {
        self.LastARObject.removeFromParentNode()
        
//        self.ARObjectName = "art.scnassets/carbine/Carbine.dae"
//        self.nodeName = "Carbine"
        
        sceneView.session.add(anchor: ARAnchor(transform: self.lastTransform))
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
        //let scene = SCNScene(named: ARObjectName)
        let scene = SCNScene(named: "art.scnassets/GameScene.scn")!
        // Set the scene to the view
        sceneView.scene = scene
        //self.view.addSubview(closeButton)
        
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
        if self.objectPresent == false {
        
            // Let's test if a 3D Object was touch
            var hitTestOptions = [SCNHitTestOption: Any]()
            hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
            let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        
            if let hit = hitResults.first {
                if let node = getParent(hit.node) {
                    node.removeFromParentNode()
                    self.objectPresent = false
                    return
                }
            }
        }
        
        // No object was touched? Try feature points
        if self.objectPresent == false {
            let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)
        
            if let hit = hitResultsFeaturePoints.first {
            
                // Get the rotation matrix of the camera
                let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            
                // Combine the matrices
                let finalTransform = simd_mul(hit.worldTransform, rotate)
                // set global variable
                self.lastTransform = finalTransform
                
                sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            }
        }
    }
    
    /// Rotates An Object On It's YAxis
    ///
    /// - Parameter gesture: UIPanGestureRecognizer
    @IBAction func rotateObject(_ gesture: UIPanGestureRecognizer) {
        
        guard let nodeToRotate = self.LastARObject else { return }
        
        let translation = gesture.translation(in: gesture.view!)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        newAngleY += currentAngleY
        
        nodeToRotate.eulerAngles.y = newAngleY
        
        if(gesture.state == .ended) { currentAngleY = newAngleY }
        
        print(nodeToRotate.eulerAngles)
    }
    
    /// scales an object based on UIPinchGesture
    ///
    /// - Parameter gesture: UIPinchGesture
    @IBAction func scaleObject(_ gesture: UIPinchGestureRecognizer) {
        
        guard let nodeToScale = self.LastARObject else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            let dis = Float(gesture.scale)
            let CS = nodeToScale.scale
            let newScale = SCNVector3((CS.x)*(dis), (CS.y)*(dis), (CS.z)*(dis))
            nodeToScale.scale = newScale
            gesture.scale = 1.0
        }
        
        print(nodeToScale.scale)
    }
    
    // Looks for the parent of the node it was sent, if that node's name matches the last
    // object which was rendered then it returns that node
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == lastObjectName {
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
                let t = DispatchTime.now()
                let modelScene = SCNScene(named:self.ARObjectName)!
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero
                
                // Sets global var to have the name of the last object that was rendered
                self.lastObjectName = self.nodeName
                // Sets global var to store the last object rendered, to store multiple objects simply make it a queue
                self.LastARObject = modelClone
                // sets global var to true
                self.objectPresent = true
                
                self.loadObject.isHidden = false
                
                // Add model as a child of the node
                node.addChildNode(modelClone)
                let a = DispatchTime.now()
                let f = (a.rawValue - t.rawValue)
                print("TEST ", f)
            }
        }
        
    }
}



