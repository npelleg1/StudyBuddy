//
//  Message.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 3/5/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import UIKit

class Message {
    
    var buddyImage: String
    var message: String
    var firstBuddyID: String
    var secondBuddyID: String
    
    init(buddyImage: String, message: String, firstBuddyID: String, secondBuddyID: String) {
        self.buddyImage = buddyImage
        self.message = message
        self.firstBuddyID = firstBuddyID
        self.secondBuddyID = secondBuddyID
    }
    
    init(){
        self.buddyImage = ""
        self.message = ""
        self.firstBuddyID = ""
        self.secondBuddyID = ""
    }
    
}
