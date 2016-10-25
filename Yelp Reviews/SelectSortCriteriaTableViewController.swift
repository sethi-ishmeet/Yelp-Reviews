//
//  SelectSortCriteriaTableViewController.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-24.
//  Copyright © 2016 Ishmeet. All rights reserved.
//

import UIKit

protocol SortCriteriaTableViewControllerDelegate {
    func didSelectSortCriteria(type: String)
}

class SelectSortCriteriaTableViewController: UITableViewController {

    var delegate: SortCriteriaTableViewControllerDelegate!
    let sortTypes = ["best_match", "rating", "review_count", "distance"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.white
        ]
    }

    @IBAction func btnCancel_Click(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate.didSelectSortCriteria(type: sortTypes[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
    
}
