//
//  StudyBuddy.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 3/5/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import UIKit
import FirebaseDatabase

class StudyBuddy: Equatable  {
    
    let className: String
    let checkIn: String
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
    let id: Int
    
    init(className: String, checkIn: String, lat: CLLocationDegrees, lon: CLLocationDegrees, id: Int) {
        self.className = className
        self.checkIn = checkIn
        self.lat = lat
        self.lon = lon
        self.id = id
    }

    static func == (lhs: StudyBuddy, rhs: StudyBuddy) -> Bool {
        return lhs.id == rhs.id
    }
    
}
