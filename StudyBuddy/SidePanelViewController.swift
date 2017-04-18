//
//  SidePanelViewController.swift
//  StudyBuddy
//
//  Created by Nick Pellegrino on 3/5/17.
//  Copyright © 2017 Nick Pellegrino. All rights reserved.
//

import UIKit

protocol SidePanelViewControllerDelegate {
    func animalSelected(_ studyBuddy: StudyBuddy)
}

class SidePanelViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: SidePanelViewControllerDelegate?
    
    var studyBuddies: Array<StudyBuddy>!
    
    struct TableView {
        struct CellIdentifiers {
            static let AnimalCell = "AnimalCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
    }
    
}

extension SidePanelViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAnimal = studyBuddies[indexPath.row]
        delegate?.animalSelected(selectedAnimal)
    }
}

// MARK: Table View Data Source

extension SidePanelViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studyBuddies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.AnimalCell, for: indexPath) as! AnimalCell
        cell.configureForAnimal(studyBuddies[indexPath.row])
        return cell
    }
    
}

class AnimalCell: UITableViewCell {
    
    @IBOutlet weak var imageNameLabel: UILabel!
    @IBOutlet weak var imageCreatorLabel: UILabel!
    
    func configureForAnimal(_ studyBuddy: StudyBuddy) {
        imageNameLabel.text = studyBuddy.className
        imageCreatorLabel.text = studyBuddy.checkIn
    }
    
}
