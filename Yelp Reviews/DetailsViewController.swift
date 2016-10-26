//
//  DetailsViewController.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-25.
//  Copyright © 2016 Ishmeet. All rights reserved.
//

import UIKit
import MapKit


class DetailsViewController: UIViewController {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var apiManager: APIManager!
    var business: Business!
    var cellIdentifiers: [[String]]!
    @IBOutlet var detailsTableView: UITableView!
    
    @IBOutlet var lblErrorTitle: UILabel!
    @IBOutlet var lblErrorMessage: UILabel!
    
    var retryTap: UITapGestureRecognizer!
    
    let sectionHeaders = ["Basic Details", "Location", "More", "Photos", "Reviews"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cellIdentifiers = [[String]]()
        cellIdentifiers.removeAll()
        
        detailsTableView.rowHeight = UITableViewAutomaticDimension
        detailsTableView.estimatedRowHeight = 50
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.title = business.Name
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.white
        ]
        
        searchBusinessOnYelp(business: business)
    }
    
    func showActivityIndicator() {
        self.activityIndicator.startAnimating()
        self.detailsTableView.isHidden = true
    }
    
    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.detailsTableView.isHidden = false
    }
    
    func searchBusinessOnYelp(business: Business) -> Void {
        showActivityIndicator()
        
        apiManager.searchYelpBusiness(business: business) { (result, error) in
            DispatchQueue.main.async {
                self.hideActivityIndicator()
            }
            
            if error != nil {
                DispatchQueue.main.async {
                    self.showErrorMessage()
                }
                return
            }
            
            self.business = result
            self.createCellIdentifiers()
            DispatchQueue.main.async {
                self.detailsTableView.reloadData()
                self.business.reviews = [Review]()
                self.searchReviewsOnYelp(business: business)
            }
        }
    }
    
    func searchReviewsOnYelp(business: Business) -> Void {
        
        apiManager.searchYelpReviews(business: business, delegate: self) { (result, error) in
            if error != nil {
                print("error in review")
                return
            }
            
            self.business = result
            self.appendReviewIdentifier()
            
            DispatchQueue.main.async {
                
                self.detailsTableView.reloadData()
            }
        }
    }
    
    func showErrorMessage() {
        lblErrorTitle.isHidden = false
        lblErrorMessage.isHidden = false
        
        self.detailsTableView.isHidden = true
        
        retryTap = UITapGestureRecognizer(target: self, action: #selector(DetailsViewController.retrySearch))
        self.view.addGestureRecognizer(retryTap)
    }
    
    func hideErrorMessage() {
        lblErrorTitle.isHidden = true
        lblErrorMessage.isHidden = true
        self.view.removeGestureRecognizer(retryTap)
    }
    
    func retrySearch() {
        hideErrorMessage()
        searchBusinessOnYelp(business: business)
    }
}

// Delegate and helper methods to support UITableView
extension DetailsViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        detailsTableView.deselectRow(at: indexPath, animated: true)
        let cellIdentifier = cellIdentifiers[indexPath.section][indexPath.row] 
        
        switch cellIdentifier {
        case "directionsCell":
            let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            let placemark = MKPlacemark(coordinate: business.location.coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = business.Name
            mapItem.openInMaps(launchOptions: options)
            
        case "callCell":
            let phone = business.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
            if let url = URL(string: "tel://\(phone)") {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = cellIdentifiers[indexPath.section][indexPath.row]
        switch cellIdentifier {
        case "basicDetailsCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! BasicDetailsTableViewCell
            cell.lblBusinessName.text = business.Name
            getStarRating(cell: cell, rating: business.rating)
            if business.review_count != nil  {
                cell.lblReviewCount.text = String(business.review_count) + " Reviews"
            }
            cell.lblPrice.text = business.price
            cell.lblCategory.text = business.categories
            
            if business.hoursToday != nil {
                cell.lblTodayHours.text = business.hoursToday
            } else {
                cell.lblTodayHours.text = ""
            }
            
            return cell
            
        case "addressCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! AddressTableViewCell
            cell.lblAddress.text = business.fullAddress
            setMapLocation(mapView: cell.mapView, location: business.location)
            return cell
            
        case "directionsCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            return cell!
            
        case "callCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            return cell!
        
        case "hoursCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! HoursTableViewCell
            createHours(cell: cell)
            return cell
            
        case "photosCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! BusinessPhotosTableViewCell
            cell.photosCollectionView.delegate = self
            cell.photosCollectionView.dataSource = self
            cell.photosCollectionView.reloadData()
            return cell
            
        case "reviewCell":
            let cell = detailsTableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ReviewTableViewCell
            
            cell.userImageView.image = business.reviews[indexPath.row].userImage
            cell.userImageView.layer.cornerRadius = cell.userImageView.frame.size.width / 2;
            cell.userImageView.clipsToBounds = true;
            cell.userImageView.layer.borderWidth = 3.0
            cell.userImageView.layer.borderColor = UIColor.black.cgColor
            
            getReviewStarRating(cell: cell, rating: business.reviews[indexPath.row].rating)
            cell.lblUserName.text = business.reviews[indexPath.row].userName
            cell.lblUserReview.text = business.reviews[indexPath.row].review
            
            return cell
        default:
            break
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    func createHours(cell: HoursTableViewCell) {
        var labels = [UILabel]()
        labels.append(cell.lblMondayHours)
        labels.append(cell.lblTuesdayHours)
        labels.append(cell.lblWednesdayHours)
        labels.append(cell.lblThursdayHours)
        labels.append(cell.lblFridayHours)
        labels.append(cell.lblSaturdayHours)
        labels.append(cell.lblSundayHours)
        
        for i in 0..<labels.count {
            var time = ""
            for hour in business.hours {
                if (hour["day"] as! Int) == i {
                    var formatter = DateFormatter()
                    formatter.dateFormat = "HHmm"
                    
                    let startTime = formatter.date(from: hour["start"] as! String)
                    let endTime = formatter.date(from: hour["end"] as! String)
                    
                    formatter = DateFormatter()
                    formatter.dateFormat = "hh:mm a"
                    
                    
                    if time != "" {
                        time = time + "\n" + formatter.string(from: startTime!) + " - " + formatter.string(from: endTime!)
                    } else {
                        time = formatter.string(from: startTime!) + " - " + formatter.string(from: endTime!)
                    }
                }
            }
            
            if time != "" {
                labels[i].text = time
            } else {
                labels[i].text = "Not Available"
            }
        }
        
    }
    
    func setMapLocation(mapView: MKMapView, location: CLLocation) {
        let mySpan = 0.015
        let span = MKCoordinateSpan(latitudeDelta: mySpan, longitudeDelta: mySpan)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func getStarRating(cell: BasicDetailsTableViewCell, rating: Double) {
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
    
    func getReviewStarRating(cell: ReviewTableViewCell, rating: Double) {
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
    
    func createCellIdentifiers() {
        cellIdentifiers = [
            [
                "basicDetailsCell"
            ],
            [
                "addressCell"
            ],
            [
                "directionsCell", "callCell", "hoursCell"
            ],
            [
                "photosCell"
            ]
        ]
        
    }
    
    func appendReviewIdentifier() {
        if business.reviews.count != 0 {
            var reviewIdentifiers = [String]()
            for _ in 0..<business.reviews.count {
                reviewIdentifiers.append("reviewCell")
            }
            cellIdentifiers.append(reviewIdentifiers)
        }
        print(cellIdentifiers)
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cellIdentifiers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellIdentifiers[section].count
    }
}


// Delegate and helper methods to show Business photos
extension DetailsViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return business.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "businessPhoto", for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = business.images[indexPath.row]
        cell.imageView.layer.cornerRadius = 5.0
        cell.imageView.layer.masksToBounds = true
        return cell
    }
}

extension DetailsViewController : ReviewClassDelegate {
    
    func didUpdateUserImage(row: Int) {
        for cell in detailsTableView.visibleCells {
            if cell.reuseIdentifier == "reviewCell" && detailsTableView.indexPath(for: cell) != nil {
                let indexPath = detailsTableView.indexPath(for: cell)
                if indexPath?.row == row {
                    detailsTableView.beginUpdates()
                    detailsTableView.reloadRows(at: [detailsTableView.indexPath(for: cell)!], with: .none)
                    detailsTableView.endUpdates()
                }
            }
        }
    }
}
