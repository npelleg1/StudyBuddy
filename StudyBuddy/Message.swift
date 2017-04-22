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
    
    init(buddyImage: String, message: String) {
        self.buddyImage = buddyImage
        self.message = message
    }
    
    init(){
        self.buddyImage = ""
        self.message = ""
    }
    
}
