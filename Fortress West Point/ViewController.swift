//
//  ViewController.swift
//  Fortress West Point
//
//  Created by C3T Hacker on 11/27/17.
//  Copyright © 2017 C3T Hacker. All rights reserved.
//

import UIKit
//import SpriteKit
//import ARKit
import GoogleMaps
import MapKit
import CoreLocation
import Alamofire

class hotSpot: NSObject {
    let name: String?
    let location: CLLocationCoordinate2D
    let zoom: Float
    
    init(name: String, location: CLLocationCoordinate2D, zoom: Float) {
        self.name = name
        self.location = location
        self.zoom = zoom
    }
}

class ViewController: UIViewController, /*ARSKViewDelegate*/CLLocationManagerDelegate {
    
    @IBOutlet var Map: MKMapView!
    
    var mapView: GMSMapView?
    
    var currentHotSpot: hotSpot?
    
    let destinations = [hotSpot(name: "Suppt's Box", location: CLLocationCoordinate2DMake(41.393375,-73.956181), zoom: 15),hotSpot(name: "Trophy Point", location: CLLocationCoordinate2DMake(41.395894,-73.955781), zoom: 16),hotSpot(name: "Chapel", location: CLLocationCoordinate2DMake(41.390504,-73.959925),zoom: 14)]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        GMSServices.provideAPIKey("AIzaSyASG3frXynPghBgPWCYElmFktpCMoeA7EQ")
        
        let camera = GMSCameraPosition.camera(withLatitude: 41.390733, longitude: -73.954404, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView?.settings.compassButton = true
        mapView?.settings.myLocationButton = true
        mapView?.isMyLocationEnabled = true
        
        
        let currentLocation = CLLocationCoordinate2DMake(41.390733,-73.954404)
        let marker = GMSMarker(position:currentLocation)
        marker.title = "Trophy Point"
        marker.snippet = "FWP"
        marker.map = mapView
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next",style: .plain, target:self, action: #selector(moron))
        //view = mapView
        view = mapView
        //view.insertSubview(mapView!, at:0)
        //view.insertSubview(button, at: 1)
        //self.view.addSubview(button)
        
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json"){
                mapView?.mapStyle = try GMSMapStyle(contentsOfFileURL:styleURL)
            }
            else {
                NSLog("Unable to find style.json")
            }
        }catch{
            NSLog("One or more of the map styles failed to load")
            }
    
        
            
        }
    @objc func moron(){
        
        if currentHotSpot == nil {
            currentHotSpot = destinations.first
            
            mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
            
            let marker = GMSMarker(position: currentHotSpot!.location)
            marker.title = currentHotSpot?.name
            marker.map = mapView
        }
        else {
            if var index = destinations.index(of: currentHotSpot!) {
                if index == 2 {index = 0}
                else {index = index + 1}
                currentHotSpot = destinations[index]
                
                mapView?.camera = GMSCameraPosition.camera(withTarget: currentHotSpot!.location, zoom: currentHotSpot!.zoom)
                
                //////// N A V I G A T I O N ///////////////
                
                
                
                
                
                let marker = GMSMarker(position: currentHotSpot!.location)
                marker.title = currentHotSpot?.name
                marker.map = mapView
            }
            
            
            
        }
    }
    func drawPath(startLoacation: CLLocation, endLocation: CLLocation){
        let origin = "\(startLoacation.coordinate.latitude),\(startLoacation.coordinate.longitude)"
        let destination = "\(endLocation.coordinate.latitude).\(endLocation.coordinate.longitude)"
        let my_key = "AIzaSyASG3frXynPghBgPWCYElmFktpCMoeA7EQ"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)7&destination=\(destination)&mode=walking&key=\(my_key)"
        
        Alamofire.request(url).responseJSON{ respose in
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            for route in routes{
                let routeOverviewPolyline = route["overview_polyline"].dictionary
                let points  = routeOverviewPolyline?["points"]?.stringValue
                let path = GSMPath.init(fromEncodedPath: points!)
                let polyline = GSMPolyline.init(path: path)
                polyline.strokeWidth = 4
                polyline.strokeColor = UIColor.red
                polyline.map = self.mapView
            }
        }
    }
        
        
        
        
       /* // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
    }*/
    
    /*override func viewWillAppear(_ animated: Bool) {
        //super.viewWillAppear(animated)
        
        // Create a session configuration
        //let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        //Map.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //super.viewWillDisappear(animated)
        
        // Pause the view's session
        //Map.session.pause()
    }
    */
    override func didReceiveMemoryWarning() {
        //super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSKViewDelegate
    
    /*func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        let labelNode = SKLabelNode(text: "👾")
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        return labelNode;
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }*/
}
