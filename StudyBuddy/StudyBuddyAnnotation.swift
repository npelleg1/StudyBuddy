//
//  StudyBuddyAnnotation.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 3/4/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import Foundation
import MapKit

class StudyBuddyAnnotation: NSObject, MKAnnotation {
    var coordinate = CLLocationCoordinate2D()
    var buddyID: Int
    var title: String?
    var subtitle: String?
    var image: String
    
    init(coordinate: CLLocationCoordinate2D, buddyID: Int, subject: String, time: String, image: String){
        self.coordinate = coordinate
        self.buddyID = buddyID
        self.title = subject
        self.subtitle = time
        self.image = image
    }
}
