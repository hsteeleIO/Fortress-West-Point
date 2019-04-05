
import UIKit
import SceneKit
import ARKit
import FLAnimatedImage

// extends the functionality of the SCNNode class to allow nodes to be highlighted
extension SCNNode {
    func setHighlighted( _ highlighted : Bool = true, _ highlightedBitMask : Int = 2 ) {
        categoryBitMask = highlightedBitMask
        for child in self.childNodes {
            child.setHighlighted()
        }
    }
    func setUnHighlighted( _ highlighted : Bool = true, _ highlightedBitMask : Int = 1 ) {
        categoryBitMask = highlightedBitMask
        for child in self.childNodes {
            child.setUnHighlighted()
        }
    }
}

// custom class for storing information about our graphic objects
class Gobjects: NSObject {
    let id: Int
    let name: String?
    let ARObject: String
    let node: String
    let high: Array<String>
    let highBool: Array<Bool>
    let boxSize: Int
    let location: SCNVector3
    let textbox: Array<String>
    let textBoxButtons: Array<String>
    
    init(id: Int, name: String, ARObject:String, node: String, high: Array<String>, highBool: Array<Bool>, boxSize: Int, location: SCNVector3, textbox: Array<String>, textBoxButtons: Array<String>) {
        self.id = id
        //name that appears above scroll wheel
        self.name = name
        //path to where object is stored
        self.ARObject = ARObject
        //name of overarching node to load
        self.node = node
        self.high = high
        self.highBool = highBool
        self.boxSize = boxSize
        self.location = location
        self.textbox = textbox
        self.textBoxButtons = textBoxButtons
    }
}

class SecondViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let objectList = [
        Gobjects(id: 0, name: "Fort", ARObject:"art.scnassets/fort/fort.dae", node:"fort", high:["Null-14_Instance-1", "Extrude-1", "Null-14_Instance-2"], highBool:[true, true, true], boxSize: 5, location:SCNVector3Make(0,0,0), textbox: ["musket4"], textBoxButtons: ["Location", "Why?", "Cannons"]),
        
        Gobjects(id: 1, name: "Battery", ARObject:"art.scnassets/battery/battery2.dae", node:"battery", high:["24"], highBool:[true], boxSize: 5, location:SCNVector3Make(0,0,0), textbox: ["musket4"], textBoxButtons: ["Purpose", "", ""]),
        
        Gobjects(id: 2, name: "Cannon", ARObject:"art.scnassets/cannon/cannon.dae", node:"cannon", high:["Lathe"], highBool:[true], boxSize: 5, location:SCNVector3Make(0.153,0.288,0.005), textbox: ["musket4"], textBoxButtons: ["Loading a Cannon", "", ""]),
        
        Gobjects(id: 3,name: "Musket", ARObject:"art.scnassets/musket/musket.dae", node:"musket", high:["", "flint_1", "butt_metal_1"], highBool:[true, true, true], boxSize: 5, location:SCNVector3Make(0,0.14,0), textbox: ["Firing", "Flint", "Stamp"], textBoxButtons: ["Firing", "Flint", "Stamp"]),
        
        Gobjects(id: 4, name: "Colonel's Uniform", ARObject:"art.scnassets/colonel/colonel.dae", node:"colonel", high:["blade-1", "handle"], highBool:[true, true], boxSize: 5, location:SCNVector3Make(0,0,0), textbox: ["musket4"], textBoxButtons: ["Red Sash", "Sword", "Epilets"]),
        
        Gobjects(id: 5, name: "Lieutenant's Uniform", ARObject:"art.scnassets/lieutenant/lieutenant.dae", node:"lieutenant", high:["Sphere"], highBool:[true], boxSize: 5, location:SCNVector3Make(0.181,0.316,0), textbox: ["musket4"], textBoxButtons: ["Red Sash", "Job", "Pay"]),
        
        Gobjects(id: 6, name: "Matross's Uniform  ", ARObject:"art.scnassets/mattross/matross.dae", node:"matross", high:["Tube-2"], highBool:[true], boxSize: 5, location:SCNVector3Make(0.181,0.316,0), textbox: ["musket4"], textBoxButtons: ["Powder Box", "Job", ""])]
    
    @IBOutlet var sceneView: ARSCNView!
    var nodeModel: SCNNode!
    
    // The node name as seen in the node inspector
    var nodeName:String = "musket"
    // Initialized as the fort (for now stand in castle object), needed to be the full path name
    var ARObjectName:String = "art.scnassets/musket/musket.dae"
    // Global object anchor
    var anchor:ARAnchor!
    // Global object Variable (will only allow one object on the scene at a time)
    var LastARObject:SCNNode!
    // Last object rendered name
    var lastObjectName:String = "Placeholder"
    // Global variable storing the last 3d transform
    var lastTransform:simd_float4x4!
    // Variable for determining if an object is present
    var objectPresent:Bool = false
    // Variable for determining whether highlight button has been hit
    var highlight:Bool = false
    
    var object:Gobjects!
    
    var objectId:Int = 0
    
    var textBox:SCNNode!
    //textbox node
    var textBoxMode:Bool = false
    //node that the user touched
    var touchedNode:SCNNode!
    //list of current highlights
    var highlightList:Array<String>!
    
    // images for picker view
    var imageArray = [UIImage]()
    
    //global var for storing current angle of object
    var currentAngleY: Float = 0.0
    //global var for storing current scale of object
    var currentScale: Float = 1.0
    
    @IBAction func CloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var curObject: UILabel!
    
    @IBOutlet weak var loadText1: UIButton!
    @IBOutlet weak var loadText2: UIButton!
    @IBOutlet weak var loadText3: UIButton!
    
    //allows the gif to be animated by setting it to a variable
    @IBOutlet weak var loadGuide: FLAnimatedImageView!
    
    /////picker////
    @IBOutlet weak var objectPicker: UIPickerView!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return objectList[row].name
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var myImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: pickerView.frame.height, height: pickerView.frame.height))
        myImageView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        
        myImageView.image = imageArray[row]
        
        return myImageView
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.height
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return objectList.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        curObject.text = objectList[row].name
        nodeName = objectList[row].node
        ARObjectName = objectList[row].ARObject
        objectId = objectList[row].id
        highlightList = objectList[row].high
        
    }
    
    //Highlights/unhighlights specific nodes in objects
    @IBAction func hightlight(_ sender: Any) {
        //highlights nodes
        if (highlight == false){
            let names = self.highlightList!
            for name in names {
                let item = self.LastARObject.childNode(withName: name, recursively: true)
                item?.setHighlighted()
            }
            self.highlight = true
        }
            
            //Unhighlights nodes
        else if (highlight == true){
            let names = self.highlightList!
            for name in names {
                let item = self.LastARObject.childNode(withName: name, recursively: true)
                item?.setUnHighlighted()
            }
            self.highlight = false
        }
        
        //connects to custom shader
        if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path)  {
                let dict2 = dict as! [String : AnyObject]
                let technique = SCNTechnique(dictionary:dict2)
                self.sceneView.technique = technique
            }
        }
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
        self.object = objectList[objectId]
        
        //sets the path for the gif that asks users to taps on the screen
        let path1 : String = Bundle.main.path(forResource: "art.scnassets/tapheregif2", ofType: "gif")!
        let url = URL(fileURLWithPath: path1)
        let gifData = NSData(contentsOf: url)
        let imageData1 = FLAnimatedImage(animatedGIFData: gifData! as Data)
        loadGuide.animatedImage = imageData1
        
        imageArray = [#imageLiteral(resourceName: "fort"), #imageLiteral(resourceName: "Battery"), #imageLiteral(resourceName: "Cannon"), #imageLiteral(resourceName: "musket"), #imageLiteral(resourceName: "Colonol"), #imageLiteral(resourceName: "lt"), #imageLiteral(resourceName: "matross")]
        let y = objectPicker.frame.origin.y
        objectPicker.transform = CGAffineTransform(scaleX: 1.0, y: 1.0);
        objectPicker.transform = CGAffineTransform(rotationAngle: -90 * (.pi/180)) // angle needs to be in radians
        objectPicker.frame = CGRect(x: 0, y: y+25, width: view.frame.width, height: 250)
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
        
        //setting this to test to false means it never tests when an object is present
        //This lets us see the name of the node being touched
        if self.objectPresent == true {
            
            // Let's test if a 3D Object was touched
            var hitTestOptions = [SCNHitTestOption: Any]()
            hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
            
            let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
            
            //testing name of node touched
            if let hit = hitResults.first {
                if let name = hit.node.name {
                    touchedNode = hit.node
                    print(name)
                    if (self.highlight == true){
                        if (object.high.contains(name)){
                            let index = object.high.firstIndex(of: name)
                            if (object.highBool[index!] == true){
                                touchedNode.setUnHighlighted()
                            }
                        }
                    }
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
                
                loadText1.setTitle(object.textBoxButtons[0], for: UIControl.State.normal)
                loadText2.setTitle(object.textBoxButtons[1], for: UIControl.State.normal)
                loadText3.setTitle(object.textBoxButtons[2], for: UIControl.State.normal)
                
                sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            }
        }
            
            // Switches between objects
        else if (self.lastObjectName != self.nodeName) {
            //remove the current object
            self.LastARObject.removeFromParentNode()
            //set the new object in the data structure
            self.object = objectList[objectId]
            if textBoxMode == true {
                //remove textbox
                self.textBox.removeFromParentNode()
                self.textBoxMode = false
            }
            
            //sets labels for text box buttons
            loadText1.setTitle(object.textBoxButtons[0], for: UIControl.State.normal)
            loadText2.setTitle(object.textBoxButtons[1], for: UIControl.State.normal)
            loadText3.setTitle(object.textBoxButtons[2], for: UIControl.State.normal)
            
            //actually spawn the object
            sceneView.session.add(anchor: ARAnchor(transform: self.lastTransform))
        }
    }
    
    /// Rotates An Object On It's YAxis
    ///
    /// - Parameter gesture: UIPanGestureRecognizer
    @IBAction func rotateObject(_ gesture: UIPanGestureRecognizer) {
        
        guard let nodeToRotate = self.LastARObject else { return }
        //guard let nodeToRotate2 = self.textBox else { return }
        
        
        let translation = gesture.translation(in: gesture.view!)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        newAngleY += currentAngleY
        
        nodeToRotate.eulerAngles.y = newAngleY
        //nodeToRotate2.eulerAngles.y = newAngleY
        
        if(gesture.state == .ended) { currentAngleY = newAngleY }
        
        //print(nodeToRotate.eulerAngles)
    }
    
    /// scales an object based on UIPinchGesture
    ///
    /// - Parameter gesture: UIPinchGesture
    @IBAction func scaleObject(_ gesture: UIPinchGestureRecognizer) {
        
        guard let nodeToScale = self.LastARObject else { return }
        guard let nodeToScale2 = self.textBox else { return }
        //let pos = object.boxSize
        if gesture.state == .began || gesture.state == .changed {
            let dis = Float(gesture.scale)
            let CS = nodeToScale.scale
            let CS2 = nodeToScale2.scale
            let newScale = SCNVector3((CS.x)*(dis), (CS.y)*(dis), (CS.z)*(dis))
            let newScale2 = SCNVector3((CS2.x)*(dis), (CS2.y)*(dis), (CS2.z)*(dis))
            nodeToScale.scale = newScale
            nodeToScale2.scale = newScale2
            nodeToScale2.position = SCNVector3Make(object.location.x, object.location.y, object.location.z)
            gesture.scale = 1.0
        }
        
        //print(nodeToScale.scale)
    }
    
    //loads text box next to object after button is tapped
    @IBAction func TextBoxButton(_ sender: UIButton, forEvent event: UIEvent) {
        if textBoxMode == true {
            self.textBox.removeFromParentNode()
            self.textBoxMode = false
        }
        else {
            guard let nodeToText = self.LastARObject else { return }
            let plane = SCNPlane(width: CGFloat(0.185), height: CGFloat(0.185))
            
            plane.cornerRadius = plane.width / 6.5
            //_ = object.boxSize
            let box = sender.currentTitle!
            if (box != ""){
                //let box = object.textbox[0]
                let spriteKitScene = SKScene(fileNamed: box)
                
                plane.firstMaterial?.diffuse.contents = spriteKitScene
                plane.firstMaterial?.isDoubleSided = true
                plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                
                let planeNode = SCNNode(geometry: plane)
                planeNode.position = SCNVector3Make(object.location.x, object.location.y, object.location.z)
                
                self.textBox = planeNode
                self.textBoxMode = true
                nodeToText.parent?.addChildNode(self.textBox)
            }
            
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
                
                //add empty plane to make sure rotate & scale functions don't crash
                let planeNode = SCNNode(geometry: plane)
                planeNode.name = "textbox"
                planeNode.position = SCNVector3Make(0,0,0)
                self.textBox = planeNode
                self.object = self.objectList[self.objectId]
                // Sets global var to have the name of the last object that was rendered
                self.lastObjectName = self.nodeName
                // Sets global var to store the last object rendered, to store multiple objects simply make it a queue
                self.LastARObject = modelClone
                // sets global var to true
                self.objectPresent = true
                
                //textboxbutton settings
                self.loadText1.isHidden = false
                self.loadText2.isHidden = false
                self.loadText3.isHidden = false
                
                self.loadGuide.isHidden = true
                
                // Add model as a child of the node
                node.addChildNode(planeNode)
                node.addChildNode(modelClone)
                
            }
        }
        
    }
}



