
import UIKit
import SceneKit
import ARKit
import FLAnimatedImage

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
    
    var textBox:SCNNode!
    //textbox node
    var textBoxMode:Bool = false
    
    
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
    
    @IBOutlet weak var loadText: UIButton!
    
    @IBOutlet weak var loadGuide: FLAnimatedImageView!
    
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
        if textBoxMode == true {
            self.textBox.removeFromParentNode()
            self.textBoxMode = false
        }
        
//        self.ARObjectName = "art.scnassets/carbine/Carbine.dae"
//        self.nodeName = "Carbine"
        
        sceneView.session.add(anchor: ARAnchor(transform: self.lastTransform))
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
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
        
        let path1 : String = Bundle.main.path(forResource: "art.scnassets/tapheregif2", ofType: "gif")!
        let url = URL(fileURLWithPath: path1)
        let gifData = NSData(contentsOf: url)
        let imageData1 = FLAnimatedImage(animatedGIFData: gifData! as Data)
        loadGuide.animatedImage = imageData1
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
        guard let nodeToRotate2 = self.textBox else { return }
        
        
        let translation = gesture.translation(in: gesture.view!)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        newAngleY += currentAngleY
        
        nodeToRotate.eulerAngles.y = newAngleY
        nodeToRotate2.eulerAngles.y = newAngleY
        
        if(gesture.state == .ended) { currentAngleY = newAngleY }
        
        print(nodeToRotate.eulerAngles)
    }
    
    /// scales an object based on UIPinchGesture
    ///
    /// - Parameter gesture: UIPinchGesture
    @IBAction func scaleObject(_ gesture: UIPinchGestureRecognizer) {
        
        guard let nodeToScale = self.LastARObject else { return }
        guard let nodeToScale2 = self.textBox else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            let dis = Float(gesture.scale)
            let CS = nodeToScale.scale
            let CS2 = nodeToScale2.scale
            let newScale = SCNVector3((CS.x)*(dis), (CS.y)*(dis), (CS.z)*(dis))
            let newScale2 = SCNVector3((CS2.x)*(dis), (CS2.y)*(dis), (CS2.z)*(dis))
            nodeToScale.scale = newScale
            nodeToScale2.scale = newScale2
            gesture.scale = 1.0
        }
        
        print(nodeToScale.scale)
    }
    
    @IBAction func getTextBox(_ sender: Any) {
        if textBoxMode == true {
            self.textBox.removeFromParentNode()
            self.textBoxMode = false
        }
        else {
            guard let nodeToText = self.LastARObject else { return }
        let plane = SCNPlane(width: CGFloat(nodeToText.scale.x * 0.8), height: CGFloat(nodeToText.scale.y * 0.5))
        
        plane.cornerRadius = plane.width / 8
        
        //let spriteKitScene = SKScene(fileNamed: "helloworld")
        let imageMaterial = UIImage(named: "art.scnassets/cannon/cannon_wood.jpg")
        plane.firstMaterial?.diffuse.contents = imageMaterial
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(nodeToText.scale.x, nodeToText.scale.y + 0.1, nodeToText.scale.z)
        
        self.textBox = planeNode
        self.textBoxMode = true
        nodeToText.parent?.addChildNode(self.textBox)
        }
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
                let modelScene = SCNScene(named:self.ARObjectName)!
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero
                let plane = SCNPlane(width: CGFloat(0), height: CGFloat(0))
                let planeNode = SCNNode(geometry: plane)
                planeNode.position = SCNVector3Make(0,0,0)
                self.textBox = planeNode
                
                // Sets global var to have the name of the last object that was rendered
                self.lastObjectName = self.nodeName
                // Sets global var to store the last object rendered, to store multiple objects simply make it a queue
                self.LastARObject = modelClone
                // sets global var to true
                self.objectPresent = true
                self.loadText.isHidden = false
                self.loadObject.isHidden = false
                self.loadGuide.isHidden = true
                
                // Add model as a child of the node
                node.addChildNode(planeNode)
                node.addChildNode(modelClone)
                
                
                
            }
        }
        
    }
}



