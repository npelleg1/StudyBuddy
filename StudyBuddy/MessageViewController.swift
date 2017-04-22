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
            static let SentRequestCell = "SentRequestCell"
            static let RequestResponseCell = "RequestResponseCell"
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 180.0;//Choose your custom row height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if messages[indexPath.row].message == "Request Sent!"{
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.SentRequestCell, for: indexPath) as! SentRequestCell
            cell.configureForMessage(messages[indexPath.row])
            return cell

        }else if messages[indexPath.row].message == "Accepted!"{
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.RequestResponseCell, for: indexPath) as! RequestResponseCell
            cell.configureForMessage(messages[indexPath.row])
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.MessageCell, for: indexPath) as! MessageCell
            cell.configureForMessage(messages[indexPath.row])
            return cell
        }
    }
    
}

class MessageCell: UITableViewCell{
    
    @IBOutlet weak var buddyImage: UIImageView!
    @IBOutlet weak var buddyMessage: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBAction func acceptButton(_ sender: Any) {
        print("HELLO")
    }
    @IBOutlet weak var declineButton: UIButton!
    @IBAction func declineButton(_ sender: Any) {
        print("GOODBYE")
    }
    
    func configureForMessage(_ message: Message){
        buddyImage.image = UIImage(named: message.buddyImage)
        buddyMessage.text = message.message
    }
}

class SentRequestCell: UITableViewCell{
    
    @IBOutlet weak var buddyImage: UIImageView!
    @IBOutlet weak var message: UILabel!
    
    func configureForMessage(_ inMessage: Message){
        message.text = "Request Sent!"
        buddyImage.image = UIImage(named: inMessage.buddyImage)
    }
    
}

class RequestResponseCell: UITableViewCell{
    
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var imageOfBuddy: UIImageView!
    
    func configureForMessage (_ inMessage: Message){
        message.text = "Accepted!"
        imageOfBuddy.image = UIImage(named: "green_latern.png")
    }
}
