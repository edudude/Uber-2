//
//  MainVC.swift
//  Uber
//
//  Created by Johnny Perdomo on 6/25/18.
//  Copyright © 2018 Johnny Perdomo. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MainVC: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapKitView: MKMapView!
    @IBOutlet weak var destinationView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var carTypeDetailView: UIView!
    @IBOutlet weak var etaLbl: UILabel!
    @IBOutlet weak var fareLbl: UILabel!
    @IBOutlet weak var maxSizeLbl: UILabel!
    @IBOutlet weak var requestRideBtn: UIButton!
    @IBOutlet weak var enterDestinationLbl: UILabel!
    
    var carType = CarType.uberPool
    
    var locationManager = CLLocationManager()
    
    var currentLocationLatitude = CLLocationDegrees()
    var currentLocationLongitude = CLLocationDegrees()
    var destinationLocationLatitude = CLLocationDegrees()
    var destinationLocationLongitude = CLLocationDegrees()

    let regionRadius: Double = 1000
    
    
    var pickedLocations: [NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        mapKitView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        checkLocationAuthorization()
        
        requestRideBtn.layer.cornerRadius = 15
        destinationView.layer.cornerRadius = 10
        segmentControl.layer.cornerRadius = 20
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        locationManager.startUpdatingLocation()
        

        fetchPickedLocation()
        
        if enterDestinationLbl.text != "Enter Destination" {
            convertAddress()
            mapRoute()
        }
        
        
    }
    
    func configureCarType(etaLbl: String, fareLbl: String, maxSizeLabel: String) {
        self.etaLbl.text = etaLbl
        self.fareLbl.text = fareLbl
        self.maxSizeLbl.text = maxSizeLabel
    }
    
    
    
    @IBAction func enterLocationBtnPressed(_ sender: Any) {
        let pickDestinationVC = storyboard?.instantiateViewController(withIdentifier: "PickDestinationVC")
        present(pickDestinationVC!, animated: true, completion: nil)
        
        if mapKitView.overlays.count > 0 {
            mapKitView.removeOverlays(mapKitView.overlays)
        }
        //delete picked location core data
        
    }
    @IBAction func requestRideBtnPressed(_ sender: Any) {
        print("Request Ride")
    }
    
    @IBAction func carTypePicked(_ sender: Any) {
        if segmentControl.selectedSegmentIndex == 0 {
            configureCarType(etaLbl: "2 Min", fareLbl: "$3.00 +", maxSizeLabel: "1 Person")
            carType = .uberPool

        } else if segmentControl.selectedSegmentIndex == 1 {
            configureCarType(etaLbl: "3 Min", fareLbl: "$8.00 +", maxSizeLabel: "2 People")
            carType = .uberX
            
        } else if segmentControl.selectedSegmentIndex == 2 {
            configureCarType(etaLbl: "5 Min", fareLbl: "$15.00 +", maxSizeLabel: "4 People")
            carType = .uberLux

        }
    }
    
    func mapRoute() {
        
        let sourceLocation = CLLocationCoordinate2D(latitude: currentLocationLatitude, longitude: currentLocationLongitude)
        let destinationLocation = CLLocationCoordinate2D(latitude: destinationLocationLatitude, longitude: destinationLocationLongitude)
        //
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        //
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        //
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.title = "Pick Up Location"
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate.latitude = location.coordinate.latitude
            sourceAnnotation.coordinate.longitude = location.coordinate.longitude
        }
        
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = "\(enterDestinationLbl.text ?? "Drop Off Location")" //provide a default value just in case address text isn't available
        
        //custom annotation
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        //
        self.mapKitView.showAnnotations([sourceAnnotation, destinationAnnotation], animated: true)
        //
        let directionRequest = MKDirectionsRequest() //The start and end points of a route, along with the planned mode of transportation.
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        
        //
        directions.calculate { (response, error) in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            self.mapKitView.add(route.polyline, level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapKitView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = #colorLiteral(red: 0.2980392157, green: 0.631372549, blue: 0.9254901961, alpha: 1)
        renderer.lineWidth = 4.0
        
        return renderer
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        
        
        currentLocationLatitude = (location?.coordinate.latitude)!
        currentLocationLongitude = (location?.coordinate.longitude)!
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance((location?.coordinate)!, regionRadius * 2.0 , regionRadius * 2.0 ) // we have to multiply the regionradius by 2.0 because it's only one direction but we want 1000 meters in both directions;we're gonna set how wide we want the radius to be around the center location
        mapKitView.setRegion(coordinateRegion, animated: true) //to set it
        
        locationManager.stopUpdatingLocation()
    }
    
    
    func checkLocationAuthorization() {
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapKitView.showsUserLocation = true
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
    }
    
    func convertAddress() {
        let geoCoder = CLGeocoder() //An interface for converting between geographic coordinates and place names.
        
        geoCoder.geocodeAddressString(enterDestinationLbl.text!) { (placemarks, error) in
            
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else {
                    return
            }
            
            self.destinationLocationLatitude = location.coordinate.latitude
            self.destinationLocationLongitude = location.coordinate.longitude
            print(location.coordinate.latitude)
            print(location.coordinate.longitude)
        }
        
    }
    
    
    
}

extension MainVC { //core data
    func fetchPickedLocation() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext //need a managed object
        let fetchRequest = NSFetchRequest <NSManagedObject>(entityName: "PickedLocation")
        
        do {
            pickedLocations = try managedContext.fetch(fetchRequest)
            
            if pickedLocations.count > 0 {
                for result in pickedLocations {
                    let address = result.value(forKey: "address") as! String
                    enterDestinationLbl.text = "\(address)"
                    enterDestinationLbl.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    print("fetch picked location success")
                }
            } else {
                print("no picked location core data objects")
            }
        } catch {
            print("Could not fetch. \(error.localizedDescription)")
        }
        
    }
}





