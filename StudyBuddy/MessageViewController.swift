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
    func getCheckedIn()->Bool
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

extension MessageViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMessage = messages[indexPath.row]
        delegate?.messageSelected(selectedMessage)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if messages.count == 0{
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = "No New Requests"
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
            return 1
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.MessageCell, for: indexPath) as! MessageCell
        cell.configureForMessage(messages[indexPath.row])
        let isCheckedIn = delegate?.getCheckedIn()
        if (cell.buddyMessage.text == "Accepted!" || cell.buddyMessage.text == "Request Sent!" || cell.buddyMessage.text == "Declined") || (isCheckedIn == false) {
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let accept = UITableViewRowAction(style: .normal, title: "Accept") { action, index in
            let alert = UIAlertController(title: "Accept Request?", message: "Send a Custom Message!", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "Sure! See you soon."
            }
            
            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                let message = textField?.text
                
                self.database.child("Messages").child(self.messages[index.row].firstBuddyID).child(self.messages[index.row].secondBuddyID).updateChildValues(["messages": "Accepted!", "sentFrom": self.messages[index.row].secondBuddyID, "sentFromImage": self.messages[index.row].buddyImage])
                
                self.database.child("Messages").child(self.messages[index.row].secondBuddyID).child(self.messages[index.row].firstBuddyID).updateChildValues(["messages":message, "sentTo": self.messages[index.row].firstBuddyID])
                
                self.messages.remove(at: index.row)
                tableView.deleteRows(at: [index], with: UITableViewRowAnimation.automatic)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                print("Cancel")
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        accept.backgroundColor = .green
        
        let decline = UITableViewRowAction(style: .normal, title: "Decline") { action, index in
            let alert = UIAlertController(title: "Decline Request?", message: "Leave an Explanation Why", preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = "Sorry, ran out of room at the table."
            }
            
            alert.addAction(UIAlertAction(title: "Decline", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                let message = textField?.text
                
                self.database.child("Messages").child(self.messages[index.row].firstBuddyID).child(self.messages[index.row].secondBuddyID).updateChildValues(["messages": "Declined", "sentFrom": self.messages[index.row].secondBuddyID, "sentFromImage": self.messages[index.row].buddyImage])
                
                self.database.child("Messages").child(self.messages[index.row].secondBuddyID).child(self.messages[index.row].firstBuddyID).updateChildValues(["messages":message, "sentTo": self.messages[index.row].firstBuddyID])
                
                self.messages.remove(at: index.row)
                tableView.deleteRows(at: [index], with: UITableViewRowAnimation.automatic)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {[weak alert] (_) in
                print("Cancel")
            }))
            
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
