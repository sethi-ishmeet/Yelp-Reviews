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
    var businesses = [NSDictionary]()
    
    
    let apiManager = APIManager()
    var locationManager: CLLocationManager!
    
    // default to 88 Queen's Quay W location
    var location = CLLocation(latitude: CLLocationDegrees(floatLiteral: 43.6411095), longitude: CLLocationDegrees(floatLiteral: -79.3786642))
    
    var isSearchingYelp: Bool = false
    
    override func viewDidLoad() {
        businesses.removeAll()
        super.viewDidLoad()
        retrieveLocation()
    }
    
    func searchYelp() {
        isSearchingYelp = true
        apiManager.searchYelp(parameter: "Ethiopian", location: location) { (result, error) in
            if error != nil {
                print("error")
                print(error)
                return
            }
            print(result)
            self.businesses.removeAll()
            self.businesses = result?["businesses"] as! [NSDictionary]
            DispatchQueue.main.async {
                self.listTableView.reloadData()
            }
        }
    }
}


// Table View Delegate, Data Source and helper methods
extension ListViewController : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.businesses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "business")! as! BusinessTableViewCell
        cell.lblBusinessName.text = (businesses[indexPath.row]["name"] as! String)
        cell.lblPrice.text = businesses[indexPath.row]["price"] as? String
        cell.businessImage.downloadFrom(link: businesses[indexPath.row]["image_url"] as! String)
        cell.lblBusinessAddress.text = getAddress(address: businesses[indexPath.row]["location"] as! NSDictionary)
        cell.lblCategory.text = getCategories(categories: businesses[indexPath.row]["categories"] as! [NSDictionary])
        
        if let coordinates = businesses[indexPath.row]["coordinates"] as? NSDictionary {
            cell.lblDistance.text = getDistance(coordinates: coordinates)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125.0
    }
    
    func getAddress(address: NSDictionary) -> String {
        var addressString = ""
        if let _ = address["address1"] as? String {
            addressString += address["address1"] as! String + ", "
        }
        
        if let _ = address["city"] as? String {
            addressString += address["city"] as! String + ", "
        }
        
        if let _ = address["state"] as? String {
            addressString += address["state"] as! String + ", "
        }
        
        if let _ = address["country"] as? String {
            addressString += address["country"] as! String + " "
        }
        
        if let _ = address["zip_code"] as? String {
            addressString += address["zip_code"] as! String
        }
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
    
    func retrieveLocation() -> Void {
        locationManager = CLLocationManager()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            searchYelp()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations[0]
        locationManager.stopUpdatingLocation()
        if !isSearchingYelp {
            searchYelp()
        }
        return
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        if !isSearchingYelp {
            searchYelp()
        }
    }
}


extension UIImageView {
    func downloadFrom(link: String) {
        guard let url = URL(string: link) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
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
