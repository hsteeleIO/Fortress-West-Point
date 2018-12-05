

import UIKit
import GoogleMaps
import MapKit
import CoreLocation
import SwiftyJSON
import Alamofire
import AVFoundation


///////// Global Variables //////////

// variable used to determine whether to show sidebar or not
var sideBarOn = false

// captures screen Size of the device
let screenSize = UIScreen.main.bounds

// captures the width of the device
let screenWidth = screenSize.width

// captures the height of the device
let screenHeight = screenSize.height

// Google GMS Services API key. It is neccessary to use geolocation features of the app
let googleAPIkey = "AIzaSyASG3frXynPghBgPWCYElmFktpCMoeA7EQ"

// Class for AR Location hotspots
class hotspot: NSObject {
    let name: String?
    let location: CLLocationCoordinate2D
    let zoom: Float
    let ARObject: String
    let node: String
    
    init(name: String, location: CLLocationCoordinate2D, zoom: Float, ARObject:String, node: String) {
        self.name = name
        self.location = location
        self.zoom = zoom
        self.ARObject = ARObject
        self.node = node
    }
}

class Gobjects: NSObject {
    let name: String?
    let ARObject: String
    let node: String
    
    init(name: String, ARObject:String, node: String) {
        self.name = name
        self.ARObject = ARObject
        self.node = node
    }
}

class ViewController: UIViewController,CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    ////////// ViewController Class Variables //////////
    
    // Google Maps MapView presented when App Launches
    var mapView: GMSMapView?
    
    // holds the hotspot that is currently chosen
    var currentHotSpot: hotspot?
    
    // array of hotspots
    let destinations = [
        hotspot(name: "Grant Hall", location: CLLocationCoordinate2DMake(41.389992,-73.956481), zoom: 15, ARObject:"art.scnassets/hat/clinton.dae", node:"Clinton2"),
        hotspot(name: "Test Current Loc", location: CLLocationCoordinate2DMake(41.390314,-73.954821), zoom: 15, ARObject:"art.scnassets/hat/clinton.dae", node:"Clinton2"),
        hotspot(name: "Battle Monument", location: CLLocationCoordinate2DMake(41.394711,-73.956823), zoom: 15, ARObject:"art.scnassets/hat/clinton.dae",node:"Clinton2"),
        hotspot(name: "COL Tadeusz Kościuszko", location: CLLocationCoordinate2DMake(41.395069,-73.956590),zoom: 15, ARObject:"art.scnassets/map/kucz.dae",node:"_2"),
        hotspot(name: "LT Thomas Machin", location: CLLocationCoordinate2DMake(41.395379,-73.956327), zoom: 15, ARObject:"art.scnassets/Quill/machin.dae", node:"Machin1"),
        hotspot(name:"Townsend", location: CLLocationCoordinate2DMake(41.395564,-73.955671), zoom:15, ARObject:"art.scnassets/hammerAnvil/hammerAnvil2.dae", node:"Townsend"),
        hotspot(name: "Test Object", location: CLLocationCoordinate2DMake(41.395894,-73.955781), zoom: 15, ARObject:"art.scnassets/test/Pumpkin.dae", node:"Pumpkin")]
    
    // GMS path used to draw path
    var polyline: GMSPolyline?
    
    
    ////////// ViewController Class Functions //////////
    
    /////Picker View//////
    

 
    
    
    // Transition from Map to AR Mode
    @objc func performsegue(){
        performSegue(withIdentifier:"ARView", sender: self)
    }
    
    //Send AR Object name and Node name to the hotspot's AR mode ViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        
        if let vc = segue.destination as? SecondViewController {
            vc.ARObjectName = (currentHotSpot?.ARObject)!
            vc.nodeName = (currentHotSpot?.node)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Our google API key
        GMSServices.provideAPIKey(googleAPIkey)
        
        /*
           Initial Map view centered around user's current location,
           defaults to Thayer Hall if location services are unavailable.
        */
        let myLocation = mapView?.myLocation?.coordinate ?? CLLocation(latitude:41.390314,longitude:-73.954821).coordinate
        let camera = GMSCameraPosition.camera(withLatitude: myLocation.latitude, longitude: myLocation.longitude, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView?.settings.compassButton = true
        mapView?.settings.myLocationButton = true
        mapView?.isMyLocationEnabled = true
        view = mapView
        
        /*
           Customizing our map with the style.json file from our project directory
           style.json file comes from customizing googleMaps website
        */
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView?.mapStyle = try GMSMapStyle(contentsOfFileURL:styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load")
        }
        
        /////////// Setting Up Google Maps Launch Screen //////////
        
        let navButton = UIButton(frame : CGRect(x:screenWidth * 0.84,y:screenHeight * 0.40,width:screenWidth * 0.11,height:screenHeight * 0.06))
        navButton.addTarget(self, action:#selector(self.draw) , for: .touchUpInside)
        let navImage = UIImage(named:"walking.png")
        navButton.setImage(navImage, for: UIControlState.normal)
        navButton.backgroundColor=UIColor.white
        navButton.layer.cornerRadius = 10
        
        let ARButton = UIButton(frame : CGRect(x:screenWidth * 0.84,y:screenHeight * 0.50,width:screenWidth * 0.11,height:screenHeight * 0.06))
        ARButton.addTarget(self, action:#selector(self.OnGoButton) , for: .touchUpInside)
        let ARImage = UIImage(named:"ARImage.png")
        ARButton.setImage(ARImage, for: UIControlState.normal)
        ARButton.backgroundColor=UIColor.white
        ARButton.layer.cornerRadius = 10
        
        let sideBarButton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.05,width:screenWidth * 0.11,height:screenHeight * 0.06))
        sideBarButton.addTarget(self, action:#selector(self.alternateSideBar) , for: .touchUpInside)
        let sideBarImage = UIImage(named:"location.png")
        sideBarButton.setImage(sideBarImage, for: UIControlState.normal)
        sideBarButton.layer.cornerRadius = 10
        
        self.view.addSubview(navButton)
        self.view.addSubview(ARButton)
        self.view.addSubview(sideBarButton)
        
        
    }
    
    /*
       Rotates thorugh the destination array
       Clears all the previous overlays including markers and polyline paths
       Puts markers for current hotspot
    */
    @objc func nextHotSpot(){
        // Erase old paths
        self.mapView?.clear()
        
        //pick current hotSpot
        if currentHotSpot == nil {
            currentHotSpot = destinations.first
            
            mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
            
            let marker = GMSMarker(position: currentHotSpot!.location)
            marker.title = currentHotSpot?.name
            marker.map = mapView
        } else {
            if var index = destinations.index(of: currentHotSpot!) {
                if index == 5 {
                    index = 0
                } else {
                    index = index + 1
                }
                currentHotSpot = destinations[index]
                mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
                let marker = GMSMarker(position: currentHotSpot!.location)
                marker.title = currentHotSpot?.name
                marker.map = mapView
            }
        }
    }
    
    ////////// Side Bar Menu Buttons' Action Functions //////////
    
    @IBAction func selectLab(_sender: UIButton) {
        self.mapView!.clear()
        currentHotSpot = destinations[1]
        mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
        let marker = GMSMarker(position: currentHotSpot!.location)
        marker.title = currentHotSpot?.name
        marker.map = mapView
    }
    
    @IBAction func selectBattleMon(_sender: UIButton) {
        self.mapView!.clear()
        currentHotSpot = destinations[2]
        mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
        let marker = GMSMarker(position: currentHotSpot!.location)
        marker.title = currentHotSpot?.name
        marker.map = mapView
    }
    
    @IBAction func selectKosciuszko(_sender: UIButton) {
        self.mapView!.clear()
        currentHotSpot = destinations[3]
        mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
        let marker = GMSMarker(position: currentHotSpot!.location)
        marker.title = currentHotSpot?.name
        marker.map = mapView
    }
    
    @IBAction func selectMachin(_sender: UIButton) {
        self.mapView!.clear()
        currentHotSpot = destinations[4]
        mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
        let marker = GMSMarker(position: currentHotSpot!.location)
        marker.title = currentHotSpot?.name
        marker.map = mapView
    }
    
    @IBAction func selectTest(_sender: UIButton) {
        self.mapView!.clear()
        currentHotSpot = destinations[6]
        mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
        let marker = GMSMarker(position: currentHotSpot!.location)
        marker.title = currentHotSpot?.name
        marker.map = mapView
    }
    
    // Draws the polyline path from the current location to the destination
    @objc func drawPath(destination: CLLocationCoordinate2D) throws {
        let origin = mapView?.myLocation ?? CLLocation(latitude:41.389148,longitude:-73.956231)
        let my_key = googleAPIkey
        
        // Constructing url for googleMaps Directions API
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin="+String(origin.coordinate.latitude)+","+String(origin.coordinate.longitude)+"&destination="+String(destination.latitude)+","+String(destination.longitude)+"&mode=walking&key=\(my_key)"
        
        // Send constructed url to google and parse received JSON file
        Alamofire.request(url).responseJSON {
            respose in
                do {
                    // Serializing JSON
                    let json = try JSON(data: respose.data!)
                    
                    // Getting routes array
                    let routes = json["routes"].arrayValue
                    
                    // Go through all the possible paths, in our case should be just one
                    for route in routes {
                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                        let points  = routeOverviewPolyline?["points"]?.stringValue
                        let path = GMSPath.init(fromEncodedPath: points!)
                        self.polyline = GMSPolyline.init(path: path)
                        self.polyline?.strokeWidth = 4
                        self.polyline?.strokeColor = UIColor.red
                        self.polyline?.map = self.mapView
                    }
                } catch {
                    NSLog("DID NOT GET JSON FILE")
                }
            }
    }
    
    // Invokes drawPath function for Navigate button
    @IBAction func draw(_sender: UIButton){
        
        do {
            if currentHotSpot == nil {
                let alert = UIAlertController(title: "Naviagtion Alert", message: "Choose the location first from Side Bar Menu!",preferredStyle: .alert)
                alert.addAction(UIAlertAction(title:NSLocalizedString("OK", comment: "Default Action"), style: .`default`,handler:{ _ in NSLog("User clicked ")}))
                self.present(alert, animated: true, completion: nil)
            }  else {
                try self.drawPath(destination:(currentHotSpot?.location)!)
            }
        } catch {
            NSLog("Should not get here!")
        }
        
    }
    
    @IBAction func alternateSideBar(_sender:UIButton){
        let sideBarButton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.05,width:screenWidth * 0.11,height:screenHeight * 0.06))
        sideBarButton.addTarget(self, action:#selector(self.alternateSideBar) , for: .touchUpInside)
        let sideBarImage = UIImage(named:"location.png")
        sideBarButton.setImage(sideBarImage, for: UIControlState.normal)
        sideBarButton.layer.cornerRadius = 10
        
        ////////// Side Bar Buttons //////////
        
        let labButton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.12,width:screenWidth * 0.11,height:screenHeight * 0.06))
        labButton.addTarget(self, action:#selector(self.selectLab), for: .touchUpInside)
        let labButtonImage = UIImage(named:"lab.png")
        labButton.setBackgroundImage(labButtonImage, for: UIControlState.normal)
        labButton.layer.cornerRadius = 10
        labButton.semanticContentAttribute = .forceRightToLeft
        
        let battleMonButton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.20,width:screenWidth * 0.11,height:screenHeight * 0.06))
        battleMonButton.addTarget(self, action:#selector(self.selectBattleMon), for: .touchUpInside)
        let battleMonumentImage = UIImage(named:"battlemonument.png")
        battleMonButton.setBackgroundImage(battleMonumentImage, for: UIControlState.normal)
        battleMonButton.backgroundColor=UIColor.white
        battleMonButton.layer.cornerRadius = 10
        
        let kosciuszkoButton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.28,width:screenWidth * 0.11,height:screenHeight * 0.06))
        kosciuszkoButton.addTarget(self, action:#selector(self.selectKosciuszko), for: .touchUpInside)
        let koscImage = UIImage(named:"kosc.png")
        kosciuszkoButton.setBackgroundImage(koscImage, for: UIControlState.normal)
        kosciuszkoButton.backgroundColor=UIColor.white
        kosciuszkoButton.layer.cornerRadius = 10
        
        let machinButton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.36,width:screenWidth * 0.11,height:screenHeight * 0.06))
        machinButton.addTarget(self, action:#selector(self.selectMachin), for: .touchUpInside)
        let macenImage = UIImage(named:"macen.png")
        machinButton.setBackgroundImage(macenImage, for: UIControlState.normal)
        machinButton.backgroundColor=UIColor.white
        machinButton.layer.cornerRadius = 10
        
        let testbutton = UIButton(frame : CGRect(x:screenWidth * 0.05,y:screenHeight * 0.44,width:screenWidth * 0.11,height:screenHeight * 0.06))
        testbutton.addTarget(self, action:#selector(self.selectTest), for: .touchUpInside)
        let testImage = UIImage(named:"chain.png")
        testbutton.setBackgroundImage(testImage, for: UIControlState.normal)
        testbutton.backgroundColor=UIColor.white
        testbutton.layer.cornerRadius = 10
        
        let navButton = UIButton(frame : CGRect(x:screenWidth * 0.84,y:screenHeight * 0.40,width:screenWidth * 0.11,height:screenHeight * 0.06))
        navButton.addTarget(self, action:#selector(self.draw) , for: .touchUpInside)
        let navImage = UIImage(named:"walking.png")
        navButton.setImage(navImage, for: UIControlState.normal)
        navButton.backgroundColor=UIColor.white
        navButton.layer.cornerRadius = 10
        
        let ARButton = UIButton(frame : CGRect(x:screenWidth * 0.84,y:screenHeight * 0.50,width:screenWidth * 0.11,height:screenHeight * 0.06))
        ARButton.addTarget(self, action:#selector(self.OnGoButton) , for: .touchUpInside)
        let ARImage = UIImage(named:"ARImage.png")
        ARButton.setImage(ARImage, for: UIControlState.normal)
        ARButton.backgroundColor=UIColor.white
        ARButton.layer.cornerRadius = 10
        
        if sideBarOn == false {
            sideBarOn = true
            
            NSLog("SIDE BAR IS ::: True")
            
            self.view.addSubview(labButton)
            self.view.addSubview(battleMonButton)
            self.view.addSubview(kosciuszkoButton)
            self.view.addSubview(machinButton)
            self.view.addSubview(testbutton)
        } else {
            sideBarOn = false
            for testButtons in self.view.subviews {
                if testButtons.isKind(of: UIButton.self) {
                    testButtons.removeFromSuperview()
                }
            }
            self.view.addSubview(navButton)
            self.view.addSubview(ARButton)
            self.view.addSubview(sideBarButton)
            NSLog("SIDE BAR IS ::: False")
        }
    }

    // Function that deals with AR Camera button
    @IBAction func OnGoButton(_ sender: Any) {
        // Defaults to Thaeyr Hall 106
        //let mylocation = mapView?.myLocation ?? CLLocation(latitude:41.390314,longitude:-73.954821)
        
        // Checks if location is chosen
        if (currentHotSpot == nil){
            let alert = UIAlertController(title: "AR Camera Alert", message: "First choose location from Side Bar Menu !",preferredStyle: .alert)
            alert.addAction(UIAlertAction(title:NSLocalizedString("OK", comment: "Default Action"), style: .`default`,handler:{ _ in NSLog("User clicked ")}))
            self.present(alert, animated: true, completion: nil)
        } else {
            // Checks the distance between the user and the hotspot
            //let current_location = CLLocation(latitude:(currentHotSpot?.location.latitude)!,longitude:(currentHotSpot?.location.longitude)!)
            do {
//                 CHecks if the user is within 25m range
//
//                if (mylocation.distance(from: current_location) >= 2500000) {
//                    let alert = UIAlertController(title: "AR Camera Alert", message: "You are not within AR range!",preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title:NSLocalizedString("OK", comment: "Default Action"), style: .`default`,handler:{ _ in NSLog("User clicked ")}))
//                    self.present(alert, animated: true, completion: nil)
//                } else {
//                     Pops up the AR mode
                    performSegue(withIdentifier:"ARView", sender: self)
                //}
            }
        }
    }
}
