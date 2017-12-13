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
import SwiftyJSON
import Alamofire


class hotSpot: NSObject {
    let name: String?
    let location: CLLocationCoordinate2D
    let zoom: Float
    let  id: String
    
    init(name: String, location: CLLocationCoordinate2D, zoom: Float, id:String) {
        self.name = name
        self.location = location
        self.zoom = zoom
        self.id = id
    }
}

class ViewController: UIViewController, /*ARSKViewDelegate*/CLLocationManagerDelegate {
    
    @IBOutlet var Map: MKMapView!
    
    ///Initilaize Global Values///
    
    var mapView: GMSMapView? /// Map that you see on the screen
    
    var currentHotSpot: hotSpot? /// our made hotspot that describes places on the map
    
    
    /// array of hotspots
    let destinations = [hotSpot(name: "US Academy Library", location: CLLocationCoordinate2DMake(41.391478,-73.955650), zoom: 15, id:"ChIJvx7sOJLMwokRofBbRROtFlE"),hotSpot(name: "Great Chain", location: CLLocationCoordinate2DMake(41.395894,-73.955781), zoom: 15, id:"ChIJS8U8b5TMwokRCbyC2Zsw3TY"),hotSpot(name: "Chapel", location: CLLocationCoordinate2DMake(41.390504,-73.959925),zoom: 15, id:"ChIJTxwGqfLMwokRFHcT7xYczcc")]

    
    var polyline: GMSPolyline? /// GMS path used for navigation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Our google API key
        GMSServices.provideAPIKey("AIzaSyASG3frXynPghBgPWCYElmFktpCMoeA7EQ")
        
        
        ///Initial Map view centered on our classroom in thayer
        let camera = GMSCameraPosition.camera(withLatitude: 41.390733, longitude: -73.954404, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView?.settings.compassButton = true
        mapView?.settings.myLocationButton = true
        mapView?.isMyLocationEnabled = true
        view = mapView
        
        ///Display Next button on the top right of the screen
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next",style: .plain, target:self, action: #selector(nextHotSpot))
        ///Display Draw button on the top left of the screen
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Navigate",style: .plain, target:self, action: #selector(draw))
        
       
        ///customizing our map with the style.json file from our project directory
        ///style.json file comes from customizing googleMaps website
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
    
    /// rotates thorugh the destination array
    /// clears all the previous overlays including markers and polyline paths
    /// puts markers for current hotspot
    @objc func nextHotSpot(){
        
        /// Erase old paths
        self.mapView?.clear()
        
        ///pick current hotSpot
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
                let marker = GMSMarker(position: currentHotSpot!.location)
                marker.title = currentHotSpot?.name
                marker.map = mapView
            }
        }
    }
    
    /// draws the polyline path from the current location to the destination
    @objc func drawPath(destination: String){
        let origin = mapView?.myLocation ?? CLLocation(latitude:41.389148,longitude:-73.956231)///defaults to grant turnaround
        let my_key = "AIzaSyASG3frXynPghBgPWCYElmFktpCMoeA7EQ"
        
        ///constructing url for googleMaps Directions API
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin="+String(origin.coordinate.latitude)+","+String(origin.coordinate.longitude)+"&destination=place_id:\(destination)&mode=walking&key=\(my_key)"
        
        ///Send constructed url to google and parse received JSON file
        Alamofire.request(url).responseJSON{ respose in
            
            do {
                let json = try JSON(data: respose.data!) ///serializing JSON
                let routes = json["routes"].arrayValue ///getting routes array
                for route in routes{ /// go through all the possible paths, in our case should be just one
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points  = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    self.polyline = GMSPolyline.init(path: path)
                    self.polyline?.strokeWidth = 4
                    self.polyline?.strokeColor = UIColor.red
                    self.polyline?.map = self.mapView
                }
            }
            catch{
                ///DO SOME ERROR MESSAGE HERE OR OTHER ERROR HANDLING ////
                NSLog("DID NOT GET JSON FILE")
            }
        }
    }
    
    ///invokes drawPath function for Navigate button
    @IBAction func draw(_sender: UIButton){
        self.drawPath(destination:(currentHotSpot?.id)!)
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
