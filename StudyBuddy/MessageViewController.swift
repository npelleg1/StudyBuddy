//
//  MessageViewController.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 3/5/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol MessageViewControllerDelegate {
    func messageSelected(_ message: Message)
}

class MessageViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var database: FIRDatabaseReference!
    var delegate: MessageViewControllerDelegate?
    var messages: Array<Message>!
    
    struct TableView {
        struct CellIdentifiers {
            static let MessageCell = "MessageCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        database = FIRDatabase.database().reference()
    }
}

extension MessageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMessage = messages[indexPath.row]
        delegate?.messageSelected(selectedMessage)
    }
}

// MARK: Table View Data Source

extension MessageViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.MessageCell, for: indexPath) as! MessageCell
        cell.configureForMessage(messages[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let accept = UITableViewRowAction(style: .normal, title: "Accept") { action, index in
            let alert = UIAlertController(title: "Accept Request?", message: "Send a Custom Message!", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.accessibilityHint = "Sure! See you soon."
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                let message = textField?.text
                self.database.child("Messages").child(self.messages[index.row].firstBuddyID).child(self.messages[index.row].secondBuddyID).updateChildValues(["messages": "Accepted!", "sentFrom": self.messages[index.row].secondBuddyID, "sentFromImage": self.messages[index.row].buddyImage])
                self.database.child("Messages").child(self.messages[index.row].secondBuddyID).child(self.messages[index.row].firstBuddyID).updateChildValues(["messages":message, "sentTo": self.messages[index.row].firstBuddyID])
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                print("Cancel")
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        accept.backgroundColor = .green
        
        let decline = UITableViewRowAction(style: .normal, title: "Decline") { action, index in
            let alert = UIAlertController(title: "Decline Request?", message: "Leave an Explanation Why", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.accessibilityHint = "Sorry, ran out of room at the table."
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                let message = textField?.text
                self.database.child("Messages").child(self.messages[index.row].firstBuddyID).child(self.messages[index.row].secondBuddyID).updateChildValues(["messages": "Declined", "sentFrom": self.messages[index.row].secondBuddyID, "sentFromImage": self.messages[index.row].buddyImage])
                self.database.child("Messages").child(self.messages[index.row].secondBuddyID).child(self.messages[index.row].firstBuddyID).updateChildValues(["messages":message, "sentTo": self.messages[index.row].firstBuddyID])
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                print("Cancel")
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
        decline.backgroundColor = .red
        
        return [accept, decline]
    }
    
}

class MessageCell: UITableViewCell{
    
    @IBOutlet weak var buddyImage: UIImageView!
    @IBOutlet weak var buddyMessage: UILabel!
    
    func configureForMessage(_ message: Message){
        buddyImage.image = UIImage(named: message.buddyImage)
        buddyMessage.text = message.message
    }
}
