//
//  ViewController.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 2/16/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

@objc
protocol ViewControllerDelegate {
    @objc optional func toggleLeftPanel()
    @objc optional func toggleRightPanel()
    @objc optional func collapseSidePanels()
}


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var delegate: ViewControllerDelegate?
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 1000
    var uLocation: CLLocation!
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    var buddies = Array<StudyBuddy>()
    var messages = Array<Message>()
    var buddyID: String! = nil
    var checkedIn = false
    let imageArray = ["green_lantern.png", "brown_fire.png", "yellow_anchor.png", "black_boat.png", "orange_balloon.png", "grey_boot.png", "red_socks.png", "pink_binoculars.png", "purple_canoe.png", "blue_compass.png"]
    let genIndex: Int = Int(arc4random_uniform(10))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef.child("StudyBuddies"))
        
        checkInButton.layer.cornerRadius = 25
        
        buddyID = "\(self.appDelegate.buddyID)"
        
        locationManager.delegate = self
        
        self.geoFireRef.child("StudyBuddies").observeSingleEvent(of: .value, with: { snapshot in
            let subject = snapshot.hasChild(self.buddyID)
            if subject == false{
                self.checkInButton.setTitle("Check In", for: UIControlState.normal)
                self.checkedIn = false
            }else{
                self.checkInButton.setTitle("Check Out", for: UIControlState.normal)
                self.checkedIn = true
            }
        })
        
        mapView.showsScale = true
        mapView.showsBuildings  = true
        mapView.showsCompass = true
        mapView.showsPointsOfInterest = true
    }
    
    @IBOutlet weak var mapSegmentedControl: UISegmentedControl!
    @IBAction func indexChanged(_ sender: Any) {
        switch mapSegmentedControl.selectedSegmentIndex{
            case 0:
                mapView.mapType = .standard
            case 1:
                mapView.mapType = .hybridFlyover
            default:
                break;
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    func locationAuthStatus(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            mapView.showsUserLocation = true
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius*2, regionRadius*2)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse{
            mapView.showsUserLocation = true
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation){
        uLocation = userLocation.location!
        if mapHasCenteredOnce == false{
            centerMapOnLocation(location: uLocation)
            mapHasCenteredOnce = true
            showBuddiesOnMap(location: uLocation)
            loadMessagesForBuddy()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 1
        let identifier = "StudyBuddyAnnotation"
        
        // 2
        if annotation is StudyBuddyAnnotation {
            // 3
            let SBannotation = annotation as! StudyBuddyAnnotation
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                //4
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
                
                // 5
                let btn  = UIButton(type: .contactAdd)
                let image = UIImage(named: "chat")
                btn.setImage(image, for: .normal)
                annotationView!.rightCalloutAccessoryView = btn
                annotationView!.detailCalloutAccessoryView = UIImageView(image: UIImage(named: SBannotation.image))
            } else {
                // 6
                annotationView!.annotation = annotation
            }
            
            return annotationView
        }
        
        // 7
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //1. Create the alert controller.
        let annotation = view.annotation as! StudyBuddyAnnotation
        let alert = UIAlertController(title: "StudyBuddy Request", message: "Send a Request!", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.accessibilityHint = "Send a StudyBuddy Request!"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let message = textField?.text
            let id = "\(annotation.buddyID)"
            self.geoFireRef.child("Messages").child(id).child(self.buddyID).updateChildValues(["messages": message, "sentFrom": self.buddyID, "sentFromImage": self.imageArray[self.genIndex]])
            self.geoFireRef.child("Messages").child(self.buddyID).child(id).updateChildValues(["messages":"Request Sent!", "sentTo": id, "sentToImage": annotation.image])
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
            print("Cancel")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool){
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showBuddiesOnMap(location: loc)
        loadMessagesForBuddy()
    }
    
    @IBOutlet weak var checkInButton: UIButton!
    @IBAction func checkInButton(_ sender: UIButton) {
        if self.checkedIn == false{
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Check In", message: "Please Enter Class Name", preferredStyle: .alert)
                
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.accessibilityHint = "Class Number"
            }
                
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "Check In", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                // get the current date and time
                let currentDateTime = Date()
                    
                // initialize the date formatter and set the style
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                formatter.dateStyle = .long
                    
                let ID = self.appDelegate.buddyID
                    
                self.addBuddyToStudyBuddies(forLocation: self.uLocation, withID: ID, withSubject: (textField?.text!)!, checkedIn: formatter.string(from: currentDateTime))
                    
                    sender.setTitle("Check Out", for: .normal)
                    self.checkedIn = true
                }))
            
            var timer = Timer.scheduledTimer(timeInterval: 43200, target: self, selector: #selector(self.checkOutMethod), userInfo: nil, repeats: false);
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                print("Cancel")
            }))
                
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }else{
            checkOutMethod()
        }
    }
    
    func checkOutMethod(){
        self.geoFireRef.child("Messages").child(self.buddyID).removeValue { (error, ref) in
            if error != nil {
                print("error \(error)")
            }
        }
        geoFireRef.child("Messages").observe(FIRDataEventType.value, with: { (snapshot) in
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                let newObj = rest.children
                while let rest1 = newObj.nextObject() as? FIRDataSnapshot {
                    if rest1.key == self.buddyID {
                        self.geoFireRef.child("Messages").child(rest.key).child(rest1.key).removeValue{ (error, ref) in
                        }
                    }
                }
            }
        })
        self.geoFireRef.child("StudyBuddies").child(self.buddyID).removeValue { (error, ref) in
            if error != nil {
                print("error \(error)")
            }else{
                self.checkInButton.setTitle("Check In", for: .normal)
                var count: Int = 0
                for buddy in self.buddies{
                    if buddy.id == Int(self.buddyID){
                        self.buddies.remove(at: count)
                    }
                    count += 1
                }
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.checkedIn = false
                self.showBuddiesOnMap(location: self.uLocation)
                self.loadMessagesForBuddy()
            }
        }
    }

    func addBuddyToStudyBuddies(forLocation location: CLLocation, withID buddyId: Int, withSubject subject: String, checkedIn time: String){
        self.buddyID = "\(buddyId)"
        geoFire.setLocation(location, forKey: self.buddyID)
        geoFireRef.child("StudyBuddies").child(self.buddyID).updateChildValues(["subject": subject, "checkInTime": time, "image": imageArray[self.genIndex]])
    }
    
    func showBuddiesOnMap(location: CLLocation){
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.buddies.removeAll()
        let circleQuery = geoFire!.query(at: location, withRadius: 3)
        _ = circleQuery?.observe(GFEventType.keyEntered, with: {
            (key, location) in
            if let key = key{
                if let location = location{
                    self.geoFireRef.observeSingleEvent(of: .value, with: { snapshot in
                        let subject = snapshot.childSnapshot(forPath: "StudyBuddies/"+key+"/subject").value as! String
                        let time = snapshot.childSnapshot(forPath: "StudyBuddies/"+key+"/checkInTime").value as! String
                        let imageStr = snapshot.childSnapshot(forPath: "StudyBuddies/"+key+"/image").value as! String
                        let anno = StudyBuddyAnnotation(coordinate: location.coordinate, buddyID: Int(key)!, subject: subject, time: time, image: imageStr)
                        self.mapView.addAnnotation(anno)
                        let newBuddy = StudyBuddy(className: subject, checkIn: time, lat: location.coordinate.latitude, lon: location.coordinate.longitude, id: Int(key)!, image:imageStr)
                        if !self.buddies.contains(newBuddy)
                        {
                            self.buddies.append(newBuddy)
                        }
                    })
                }
            }
        })
    }
    
    func loadMessagesForBuddy(){
        self.messages.removeAll()
        let refHandle = geoFireRef.child("Messages/"+self.buddyID).observe(FIRDataEventType.value, with: { (snapshot) in
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                let newobj=rest.children
                var newMessage = Message()
                while let rest1 = newobj.nextObject() as? FIRDataSnapshot {
                    if rest1.key == "messages" {
                        if rest1.value as! String == "Request Sent!"{
                            newMessage.message = "Request Sent!"
                        } else if rest1.value as! String == "Accepted!"{
                            newMessage.message = "Accepted!"
                        } else{
                            newMessage.message = rest1.value as! String
                        }
                    }else if rest1.key == "sentToImage"{
                        newMessage.buddyImage = rest1.value as! String
                    }else if rest1.key == "sentFromImage"{
                        newMessage.buddyImage = rest1.value as! String
                    }
                }
                newMessage.firstBuddyID = self.buddyID
                newMessage.secondBuddyID = rest.key
                var isInTable = false
                for var mess in self.messages{
                    if mess.secondBuddyID == newMessage.secondBuddyID{
                        mess.message = newMessage.message
                        isInTable = true
                    }
                }
                if isInTable == false{
                    self.messages.append(newMessage)
                }
            }
        })
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        delegate?.toggleRightPanel?()
    }
    
    @IBAction func buddiesTapped(_ sender: Any) {
        delegate?.toggleLeftPanel?()
    }
    
}

extension ViewController: SidePanelViewControllerDelegate {
    func animalSelected(_ animal: StudyBuddy) {
        let centerLocation = CLLocation(latitude: animal.lat, longitude: animal.lon)
        centerMapOnLocation(location: centerLocation)
        delegate?.collapseSidePanels?()
    }
}

extension ViewController: MessageViewControllerDelegate{
    internal func getCheckedIn() -> Bool {
        return self.checkedIn
    }

    func messageSelected(_ message: Message) {
    }
}


