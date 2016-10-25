//
//  ListViewController.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-20.
//  Copyright © 2016 Ishmeet. All rights reserved.
//

import UIKit
import CoreLocation

class ListViewController: UIViewController {
    
    @IBOutlet var listTableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var searchBar: UISearchBar!
    
    @IBOutlet var lblErrorTitle: UILabel!
    @IBOutlet var lblErrorMessage: UILabel!
    var retryTapGestureRecognizer: UITapGestureRecognizer!
    
    var isSearchActive: Bool = false
    var businesses = [NSDictionary]()
    var autoCompleteResults = [[NSDictionary]]()
    let apiManager = APIManager()
    var locationManager: CLLocationManager!
    var autoCompleteDataTask: URLSessionDataTask!
    let autoCompleteHeaders: [String] = ["Terms", "Businesses", "Categories"]
    var searchTerm = "chinese"
    let defaultSortBy = "best_match"
    
    // default to 88 Queen's Quay W location
    var location = CLLocation(latitude: CLLocationDegrees(floatLiteral: 43.6411095), longitude: CLLocationDegrees(floatLiteral: -79.3786642))
    var isSearchingYelp: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autoCompleteResults.removeAll()
        businesses.removeAll()
        
        listTableView.tableFooterView = UIView()
        navigationController?.navigationBar.isTranslucent = false
        
        retrieveLocation()
    }
    
    func searchYelp(term: String, sort_by: String) {
        showActivityIndicator()
        isSearchingYelp = true
        apiManager.searchYelp(parameter: term, sort_by: sort_by, location: location) { (result, error) in
            if error != nil {
                print("error")
                print(error)
                DispatchQueue.main.async {
                    self.showErrorMessage()
                }
                return
            }
            print(result)
            
            self.businesses.removeAll()
            self.businesses = result?["businesses"] as! [NSDictionary]
            DispatchQueue.main.async {
                self.hideActivityIndicator()
                self.listTableView.reloadData()
            }
        }
    }
    
    func addSearchBar() {
        searchBar = UISearchBar()
        searchBar.sizeToFit()
        searchBar.placeholder = "Search Here"
        
        searchBar.isTranslucent = false
        searchBar.searchBarStyle = .prominent
        searchBar.barTintColor = UIColor(red: 255 / 255 , green: 127 / 255, blue: 0 / 255, alpha: 0.5)
        
        searchBar.delegate = self
        searchBar.returnKeyType = .done
        self.navigationItem.titleView = searchBar
    }
    
    func showActivityIndicator() {
        listTableView.isHidden = true
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        listTableView.isHidden = false
        activityIndicator.stopAnimating()
    }
    
    func showErrorMessage() {
        self.lblErrorTitle.isHidden = false
        self.lblErrorMessage.isHidden = false
        
        self.listTableView.isHidden = true
        self.activityIndicator.stopAnimating()
        
        retryTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ListViewController.retrySearch))
        self.view.addGestureRecognizer(retryTapGestureRecognizer)
    }
    
    func hideErrorMessage() {
        self.lblErrorTitle.isHidden = true
        self.lblErrorMessage.isHidden = true
        self.view.removeGestureRecognizer(retryTapGestureRecognizer)
    }
    
    func retrySearch() {
        hideErrorMessage()
        searchYelp(term: searchTerm, sort_by: defaultSortBy)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showSortCriteria") {
            let dest = (segue.destination as! UINavigationController).viewControllers.first as! SelectSortCriteriaTableViewController
            dest.delegate = self
        }
    }
    @IBAction func btnSort_Click(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showSortCriteria", sender: self)
    }
}


// UISearchBar delegate and helper Methods
extension ListViewController : UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text != "" {
            isSearchActive = true
            autoCompleteSearch(searchText: searchText)
        } else {
            isSearchActive = false
            listTableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        self.searchBar.resignFirstResponder()
    }
    
    func autoCompleteSearch(searchText: String) {
        showActivityIndicator()
        let locale = "en_CA"
        let searchString = "?text=" + searchText + "&latitude=" + String(location.coordinate.latitude) + "&longitude=" + String(location.coordinate.longitude) + "&locale=" + locale
        
        let url = URL(string: "https://api.yelp.com/v3/autocomplete" + searchString.replacingOccurrences(of: " ", with: ""))
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue("Bearer " + apiManager.getAccessToken(), forHTTPHeaderField: "Authorization")
        
        if autoCompleteDataTask != nil {
            autoCompleteDataTask.suspend()
        }
        autoCompleteResults.removeAll()
        autoCompleteDataTask = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
                print("error in autocomplete data task")
                self.isSearchActive = false
                DispatchQueue.main.async {
                    self.listTableView.reloadData()
                }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
//                print(json)
                
                self.autoCompleteResults.removeAll()
                if let _ = json["terms"] as? [NSDictionary] {
                    self.autoCompleteResults.append(json["terms"] as! [NSDictionary])
                }
                
                if let _ = json["businesses"] as? [NSDictionary] {
                    self.autoCompleteResults.append(json["businesses"] as! [NSDictionary])
                }
                if let _ = json["categories"] as? [NSDictionary] {
                    self.autoCompleteResults.append(json["categories"] as! [NSDictionary])
                }
                
                DispatchQueue.main.async {
                    self.listTableView.reloadData()
                    self.hideActivityIndicator()
                }
                
                return
            } catch let err as NSError {
                print(err)
                return
            }
        })
        autoCompleteDataTask.resume()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        isSearchActive = false
        listTableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        isSearchActive = false
        listTableView.reloadData()
    }
    
}

// Table View Delegate, Data Source and helper methods
extension ListViewController : UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isSearchActive {
            isSearchActive = false
            
            if let _ = autoCompleteResults[indexPath.section][indexPath.row]["text"] as? String {
                let term = (autoCompleteResults[indexPath.section][indexPath.row]["text"] as! String).replacingOccurrences(of: " ", with: "")
                searchTerm = term
                searchYelp(term: term, sort_by: defaultSortBy)
            }
            
            // revisit this to perform better search for business
            if let _ = autoCompleteResults[indexPath.section][indexPath.row]["name"] as? String {
                searchTerm = autoCompleteResults[indexPath.section][indexPath.row]["id"] as! String
                searchYelp(term: autoCompleteResults[indexPath.section][indexPath.row]["id"] as! String, sort_by: defaultSortBy)
            }
            
            if let _ = autoCompleteResults[indexPath.section][indexPath.row]["title"] as? String {
                searchTerm = autoCompleteResults[indexPath.section][indexPath.row]["alias"] as! String
                searchYelp(term: autoCompleteResults[indexPath.section][indexPath.row]["alias"] as! String, sort_by: defaultSortBy)
            }
            self.searchBar.resignFirstResponder()
            return
        }
        
        self.performSegue(withIdentifier: "showBusinessDetails", sender: self)
        return
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearchActive {
            // return search result cell here
            let cell = tableView.dequeueReusableCell(withIdentifier: "autoCompleteResultCell")!
            
            if let _ = autoCompleteResults[indexPath.section][indexPath.row]["text"] as? String {
                cell.textLabel?.text = (autoCompleteResults[indexPath.section][indexPath.row]["text"] as! String)
            }
            
            if let _ = autoCompleteResults[indexPath.section][indexPath.row]["name"] as? String {
                cell.textLabel?.text = (autoCompleteResults[indexPath.section][indexPath.row]["name"] as! String)
            }
            
            if let _ = autoCompleteResults[indexPath.section][indexPath.row]["title"] as? String {
                cell.textLabel?.text = (autoCompleteResults[indexPath.section][indexPath.row]["title"] as! String)
            }
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "business")! as! BusinessTableViewCell
        cell.lblBusinessName.text = (businesses[indexPath.row]["name"] as! String)
        cell.lblPrice.text = businesses[indexPath.row]["price"] as? String
        cell.businessImage.downloadFrom(link: businesses[indexPath.row]["image_url"] as! String)
        cell.lblBusinessAddress.text = getAddress(address: businesses[indexPath.row]["location"] as! NSDictionary)
        cell.lblCategory.text = getCategories(categories: businesses[indexPath.row]["categories"] as! [NSDictionary])
        if let coordinates = businesses[indexPath.row]["coordinates"] as? NSDictionary {
            cell.lblDistance.text = getDistance(coordinates: coordinates)
        }
        getStarRating(cell: cell, rating: businesses[indexPath.row]["rating"] as! Double)
        cell.lblReviewCount.text = String(businesses[indexPath.row]["review_count"] as! Int) + " Reviews"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearchActive {
            return 44.0
        }
        return 125.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isSearchActive {
            return autoCompleteResults.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearchActive {
            return autoCompleteResults[section].count
        }
        return self.businesses.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearchActive {
            return autoCompleteHeaders[section]
        }
        return nil
    }
    
    func getStarRating(cell: BusinessTableViewCell, rating: Double) {
        var images = [UIImageView]()
        images.removeAll()
        images.append(cell.imgStar1)
        images.append(cell.imgStar2)
        images.append(cell.imgStar3)
        images.append(cell.imgStar4)
        images.append(cell.imgStar5)
        
        let flr = floor(rating)
        for i in 0..<Int(flr) {
            images[i].image = UIImage(named: "14x14_" + String(Int(flr)))
        }
        if rating.truncatingRemainder(dividingBy: flr) != 0.0 {
            images[Int(flr)].image = UIImage(named: "14x14_" + String(Int(flr)) + "-5")
            if Int(ceil(rating)) <= 4 {
                for i in Int(ceil(rating))...4 {
                    images[i].image = UIImage(named: "14x14_0")
                }
            }
        } else {
            if Int(flr) <= 4 {
                for i in Int(flr)...4 {
                    images[i].image = UIImage(named: "14x14_0")
                }
            }
        }
    }
    
    func getAddress(address: NSDictionary) -> String {
        var addressString = ""
        if let _ = address["address1"] as? String {
            addressString += address["address1"] as! String
        }
        
        if let _ = address["city"] as? String {
            addressString += ", " + (address["city"] as! String)
        }
//        
//        if let _ = address["state"] as? String {
//            addressString += ", " + address["state"] as! String
//        }
//        
//        if let _ = address["country"] as? String {
//            addressString += ", " + address["country"] as! String
//        }
//        
//        if let _ = address["zip_code"] as? String {
//            addressString += " " + address["zip_code"] as! String
//        }
        return addressString
    }
    
    func getCategories(categories: [NSDictionary]) -> String {
        var catText = ""
        for category in categories {
            catText += category["title"] as! String + ", "
        }
        return catText.substring(to: catText.index(catText.endIndex, offsetBy: String.IndexDistance.init(exactly: -2)!))
    }
    
    func getDistance(coordinates: NSDictionary) -> String {
        let businessLocation = CLLocation(latitude: CLLocationDegrees(floatLiteral: coordinates["latitude"] as! Double), longitude: CLLocationDegrees(floatLiteral: coordinates["longitude"] as! Double))
        let distance = businessLocation.distance(from: location) / 1000
        let rounded = Double(round(distance * 10) / 10)
        return String(rounded) + " km"
    }
}


// Location Services Delegate and helper Methods
extension ListViewController : CLLocationManagerDelegate {
    
    func retrieveLocation() {
        locationManager = CLLocationManager()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            searchYelp(term: searchTerm, sort_by: defaultSortBy)
            addSearchBar()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations[0]
        locationManager.stopUpdatingLocation()
        if !isSearchingYelp {
            searchYelp(term: searchTerm, sort_by: defaultSortBy)
            addSearchBar()
        }
        return
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        if !isSearchingYelp {
            searchYelp(term: searchTerm, sort_by: defaultSortBy)
            addSearchBar()
        }
    }
}


// Delegate and helper methods to implement sorting of results
extension ListViewController : SortCriteriaTableViewControllerDelegate {
    func didSelectSortCriteria(type: String) {
        if type == "review_count" {
            businesses.sort(by: { (a, b) -> Bool in
                return (a["review_count"] as! Int) > (b["review_count"] as! Int)
            })
            self.listTableView.reloadData()
            return
        }
        
        if type == "rating" {
            businesses.sort(by: { (a, b) -> Bool in
                return (a["rating"] as! Double) > (b["rating"] as! Double)
            })
            self.listTableView.reloadData()
            return
        }
        
        searchYelp(term: searchTerm, sort_by: type)
        
    }
    
    
}


// UIImageView Extension to download image from the given link
extension UIImageView {
    func downloadFrom(link: String) {
        guard let url = URL(string: link) else {
            print("image url error")
            self.image = #imageLiteral(resourceName: "imageNA")
            self.layer.cornerRadius = 5.0
            self.layer.masksToBounds = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print("photo data task error")
                self.image = #imageLiteral(resourceName: "imageNA")
                self.layer.cornerRadius = 5.0
                self.layer.masksToBounds = true
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data!)
                self.layer.cornerRadius = 5.0
                self.layer.masksToBounds = true
            }
        }.resume()
    }
}
