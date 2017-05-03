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
        
        // read database to see if this user is checked in based on its buddyID
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
    
    // code to control the segmented control for the map view
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
    
    // enter locationAuth process when the view appears
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    // if authorized, show location. Otherwise, request authorization via pop-up screen
    func locationAuthStatus(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            mapView.showsUserLocation = true
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // centers map view above a passed-in location
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius*2, regionRadius*2)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    // called when user first installs app and approves the request for location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse{
            mapView.showsUserLocation = true
        }
    }

    // when the user moves, call this function to keep map and messages up-to-date
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation){
        uLocation = userLocation.location!
        if mapHasCenteredOnce == false{
            centerMapOnLocation(location: uLocation)
            mapHasCenteredOnce = true
            showBuddiesOnMap(location: uLocation)
            loadMessagesForBuddy()
        }
    }
    
    // code which controls the annotations (pins) on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "StudyBuddyAnnotation"
        if annotation is StudyBuddyAnnotation {
            let SBannotation = annotation as! StudyBuddyAnnotation
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
                let btn  = UIButton(type: .contactAdd)
                let image = UIImage(named: "chat")
                btn.setImage(image, for: .normal)
                annotationView!.rightCalloutAccessoryView = btn
                annotationView!.detailCalloutAccessoryView = UIImageView(image: UIImage(named: SBannotation.image))
            } else {
                annotationView!.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    // code for when an annotation is tapped and displays the callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation as! StudyBuddyAnnotation
        let alert = UIAlertController(title: "StudyBuddy Request", message: "Send a Request!", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Write a Custom Message"
        }
        
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let message = textField?.text
            let id = "\(annotation.buddyID)"
            
            // Messaging functionality is achieved by updating both the sender and receiver's Firebase
            // data; The first ID in the function calls refer to the buddyID of the user who will view
            // this message, and the second buddyID is for the other user
            self.geoFireRef.child("Messages").child(id).child(self.buddyID).updateChildValues(["messages": message, "sentFrom": self.buddyID, "sentFromImage": self.imageArray[self.genIndex]])
        self.geoFireRef.child("Messages").child(self.buddyID).child(id).updateChildValues(["messages":"Request Sent!", "sentTo": id, "sentToImage": annotation.image])
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
            print("Cancel")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // called when the user scrolls on the map, keeps map and messsages up to date
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool){
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showBuddiesOnMap(location: loc)
        loadMessagesForBuddy()
    }
    
    // code controlling the check-in/check-out button
    @IBOutlet weak var checkInButton: UIButton!
    @IBAction func checkInButton(_ sender: UIButton) {
        if self.checkedIn == false{
            let alert = UIAlertController(title: "Check In", message: "Please Enter Class Name and Floor Number", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Class Name"
            }
            alert.addTextField{(textField2) in
                textField2.placeholder = "Enter Floor Number"
            }
            alert.addAction(UIAlertAction(title: "Check In", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                let textField2 = alert?.textFields![1]
                let currentDateTime = Date()
                let floorNumber = textField2?.text
                let formatter = DateFormatter()
                formatter.timeStyle = .medium
                formatter.dateStyle = .long
                let ID = self.appDelegate.buddyID
                self.addBuddyToStudyBuddies(forLocation: self.uLocation, withID: ID, withSubject: (textField?.text!)!, checkedIn: formatter.string(from: currentDateTime), onFloor: floorNumber!)
                sender.setTitle("Check Out", for: .normal)
                self.checkedIn = true
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                print("Cancel")
            }))
            
            self.present(alert, animated: true, completion: nil)
        }else{
            checkOutMethod()
        }
    }
    
    // this function specifically handles checking out a StudyBuddy. It deletes the StudyBuddy, removes
    // the buddy's requests and replies, and removes all messages sent to the buddy on other devices
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

    // this code specifically adds a new StudyBuddy to the Firebase backend
    func addBuddyToStudyBuddies(forLocation location: CLLocation, withID buddyId: Int, withSubject subject: String, checkedIn time: String, onFloor floor: String){
        self.buddyID = "\(buddyId)"
        geoFire.setLocation(location, forKey: self.buddyID)
        geoFireRef.child("StudyBuddies").child(self.buddyID).updateChildValues(["subject": subject, "checkInTime": time, "image": imageArray[self.genIndex], "count": 0, "floorNumber": floor])
    }
    
    // this code loads all Studybuddies, displays them on the map, and populates the needed data for the 
    // left side navigation when the "Buddies" button is pressed
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
                        let floor = snapshot.childSnapshot(forPath: "StudyBuddies/"+key+"/floorNumber").value as! String
                        let anno = StudyBuddyAnnotation(coordinate: location.coordinate, buddyID: Int(key)!, subject: subject, time: time, image: imageStr)
                        self.mapView.addAnnotation(anno)
                        let newBuddy = StudyBuddy(className: subject, checkIn: time, lat: location.coordinate.latitude, lon: location.coordinate.longitude, id: Int(key)!, image:imageStr, floorNumber: floor)
                        if !self.buddies.contains(newBuddy)
                        {
                            self.buddies.append(newBuddy)
                        }
                    })
                }
            }
        })
    }
    
    // this code controls loading the messages for a user, which is shown when a user presses on the 
    // "Requests" button
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

// code which controls when a StudyBuddy is pressed from the left table view
extension ViewController: SidePanelViewControllerDelegate {
    func buddySelected(_ buddy: StudyBuddy) {
        let centerLocation = CLLocation(latitude: buddy.lat, longitude: buddy.lon)
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


