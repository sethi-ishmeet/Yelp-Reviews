//
//  APIManager.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-21.
//  Copyright © 2016 Ishmeet. All rights reserved.

import Foundation
import CoreLocation
import UIKit

class APIManager {
    
    private var access_token: String!
    private let client_id: String = "7oGiuyv8MVGjHKg8vhImMQ"
    private let client_secret: String = "ETmOYtpUPsdi3QcCD5dfsPeaaREPZ2NvBgabGlGO5VV2zNe8bEU1O5lP7rV5xxpi"
    
    private func getAccessToken(completionHandler: @escaping (NSError?) -> Void) {
        let url = NSURL(string: "https://api.yelp.com/oauth2/token")
        let request = NSMutableURLRequest(url: url as! URL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        
        let postBody = "grant_type=client_credentials&client_id=" + client_id + "&client_secret=" + client_secret
        let postData = NSMutableData(data: postBody.data(using: String.Encoding.utf8)!)
        
        request.httpBody = postData as Data
        
        let apiError = NSError(domain: "Could not obtain access_token from Yelp server.", code: 300, userInfo: nil)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if (error != nil) {
                completionHandler(error as NSError?)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                guard let _ = json["access_token"] else {
                    completionHandler(apiError)
                    return
                }
                
                self.access_token = (json["access_token"] as! String)
                completionHandler(nil)
                return
            } catch let err as NSError {
//                print(err)
                completionHandler(apiError)
                return
            }
        }
        task.resume()
    }
    
    func searchYelp(parameter: String, sort_by: String, location: CLLocation, delegate: BusinessClassDelegate, completion: @escaping ([Business]?, NSError?) -> Void) {
        let limit = "10"
        let locale = "en_CA"
        let apiError = NSError(domain: "Could not search given parameter on Yelp server.", code: 300, userInfo: nil)
        
        if access_token == nil {
            getAccessToken(completionHandler: { (tokenError) in
                if (tokenError != nil) {
//                    print("error in access token retrieval")
                    completion(nil, tokenError)
                    return
                }
                self.searchYelp(parameter: parameter, sort_by: sort_by, location: location, delegate: delegate, completion: completion)
            })
        } else {
            let searchString = "?term=" + parameter + "&latitude=" + String(location.coordinate.latitude) + "&longitude=" + String(location.coordinate.longitude) + "&locale=" + locale + "&limit=" + limit + "&sort_by=" + sort_by
            let url = URL(string: "https://api.yelp.com/v3/businesses/search" + searchString)
            let request = NSMutableURLRequest(url: url!)
            request.httpMethod = "GET"
            request.addValue("Bearer " + self.access_token, forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
                if error != nil {
//                    print("error in search data task")
                    completion(nil, error as NSError?)
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                    guard let _ = json["businesses"] else {
                        completion(nil, apiError)
                        return
                    }
                    
                    let businesses: [Business] = self.createBusinessArray(allBusinesses: json["businesses"] as! [NSDictionary], delegate: delegate)
                    completion(businesses, nil)
                    return
                } catch let err as NSError {
//                    print(err)
                    completion(nil, err)
                    return
                }
            }).resume()
        }
    }
    
    func createBusinessArray(allBusinesses: [NSDictionary], delegate: BusinessClassDelegate) -> [Business] {
        var businesses: [Business] = [Business]()
        
        for business in allBusinesses {
            let item = Business()
            
            item.delegate = delegate
            
            item.id = business["id"] as! String
            item.Name = business["name"] as! String
            
            if let _ = business["price"] as? String {
                item.price = business["price"] as! String
            } 
            
            if let img_url = business["image_url"] as? String {
                if img_url.contains("o.jpg") {
                    item.image_url = img_url.replacingOccurrences(of: "o.jpg", with: "ls.jpg")
                } else {
                    item.image_url = img_url
                }
            }
            
            if let _ = business["coordinates"] as? NSDictionary {
                item.location = CLLocation(latitude: (business["coordinates"] as! NSDictionary)["latitude"] as! Double, longitude: (business["coordinates"] as! NSDictionary)["longitude"] as! Double)
            }
            
            if let _ = business["location"] as? NSDictionary {
                item.address = getAddress(address: business["location"] as! NSDictionary)
                item.fullAddress = getFullAddress(address: business["location"] as! NSDictionary)
            }
            
            if let _ = business["categories"] as? [NSDictionary] {
                item.categories = getCategories(categories: business["categories"] as! [NSDictionary])
            }
            
            if let _ = business["rating"] as? Double {
                item.rating = business["rating"] as! Double
            }
            
            if let _ = business["review_count"] as? Int {
                item.review_count = business["review_count"] as! Int
            }
            businesses.append(item)
        }
        
        return businesses
    }
    
    func getCategories(categories: [NSDictionary]) -> String {
        var catText = ""
        for category in categories {
            catText += category["title"] as! String + ", "
        }
        return catText.substring(to: catText.index(catText.endIndex, offsetBy: String.IndexDistance.init(exactly: -2)!))
    }
    
    func getAddress(address: NSDictionary) -> String {
        var addressString = ""
        if let _ = address["address1"] as? String {
            addressString += address["address1"] as! String
        }
        
        if let _ = address["city"] as? String {
            addressString += ", " + (address["city"] as! String)
        }
        return addressString
    }
    
    func getFullAddress(address: NSDictionary) -> String {
        var addressString = ""
        if let _ = address["address1"] as? String {
            addressString += address["address1"] as! String
        }
        
        if let _ = address["city"] as? String {
            addressString += ", " + (address["city"] as! String)
        }
        
        if let _ = address["state"] as? String {
            addressString += ", " + (address["state"] as! String)
        }
        
//        if let _ = address["country"] as? String {
//            addressString += ", " + (address["country"] as! String)
//        }
        
        if let _ = address["zip_code"] as? String {
            addressString += " " + (address["zip_code"] as! String)
        }
        return addressString
    }
    
    func searchYelpBusiness(business: Business, completion: @escaping (Business?, NSError?) -> Void) {
        let apiError = NSError(domain: "Could not search given business ID on Yelp server.", code: 300, userInfo: nil)
        
        let url = URL(string: "https://api.yelp.com/v3/businesses/" + business.id)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue("Bearer " + self.access_token, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
//                print("error in search data task")
                completion(nil, error as NSError?)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
//                print(json)
                guard let _ = json["id"] else {
                    completion(nil, apiError)
                    return
                }
                
                
                
                business.id = json["id"] as! String
                business.Name = json["name"] as! String
                
                if let _ = json["price"] as? String {
                    business.price = json["price"] as! String
                }
                
                if let img_url = json["image_url"] as? String {
                if img_url.contains("o.jpg") {
                    business.image_url = img_url.replacingOccurrences(of: "o.jpg", with: "ls.jpg")
                } else {
                    business.image_url = json["image_url"] as! String
                }
                }
                
                if let _ = json["coordinates"] as? NSDictionary {
                    business.location = CLLocation(latitude: (json["coordinates"] as! NSDictionary)["latitude"] as! Double, longitude: (json["coordinates"] as! NSDictionary)["longitude"] as! Double)
                }
                
                if let _ = json["location"] as? NSDictionary {
                    business.address = self.getAddress(address: json["location"] as! NSDictionary)
                    business.fullAddress = self.getFullAddress(address: json["location"] as! NSDictionary)
                }
                
                if let _ = json["categories"] as? [NSDictionary] {
                    business.categories = self.getCategories(categories: json["categories"] as! [NSDictionary])
                }
                
                if let _ = json["rating"] as? Double {
                    business.rating = json["rating"] as! Double
                }
                
                if let _ = json["review_count"] as? Int {
                    business.review_count = json["review_count"] as! Int
                }
                
                
                
                if let _ = json["phone"] as? String {
                    business.phone = json["phone"] as! String
                }
                
                if let photos = json["photos"] as? [String] {
                    var urls = [String]()
                    for photo in photos {
                        if photo.contains("o.jpg") {
                            urls.append(photo.replacingOccurrences(of: "o.jpg", with: "ls.jpg"))
                        } else {
                            urls.append(photo)
                        }
                    }
                    business.image_urls = urls
                }
                
                if let allHours = (json["hours"] as? [NSDictionary]) {
                    if let hours = allHours[0]["open"] as? [NSDictionary] {
                        business.hours = hours
                    }
                }
                completion(business, nil)
                return
            } catch let err as NSError {
//                print(err)
                completion(nil, err)
                return
            }
        }).resume()
    }
    
    func searchYelpReviews(business: Business, delegate: ReviewClassDelegate, completion: @escaping(Business?, NSError?) -> Void) {
        let apiError = NSError(domain: "Could not search reviews for given business ID on Yelp server.", code: 300, userInfo: nil)
        
        let url = URL(string: "https://api.yelp.com/v3/businesses/" + business.id + "/reviews")
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "GET"
        request.addValue("Bearer " + self.access_token, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            if error != nil {
//                print("error in review data task")
                completion(nil, error as NSError?)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
//                print(json)
                guard let _ = json["reviews"] else {
                    completion(nil, apiError)
                    return
                }
                
                if let reviews = json["reviews"] as? [NSDictionary] {
                    
                    for i in 0..<reviews.count {
                        let item = Review()
                        item.rating = reviews[i]["rating"] as! Double
                        item.row = i
                        item.delegate = delegate
                        
                        if let user = reviews[i]["user"] as? NSDictionary {
                            
                            if let imageUrl = user["image_url"] as? String {
                                if imageUrl.contains("o.jpg") {
                                    item.userImageURL = imageUrl.replacingOccurrences(of: "o.jpg", with: "ls.jpg")
                                } else {
                                    item.userImageURL = imageUrl
                                }
                            } else {
                                item.userImageURL = "invalid url"
                            }
                            
                            if let userName = user["name"] as? String {
                                item.userName = userName
                            }
                        }
                        
                        if let text = reviews[i]["text"] as? String {
                            item.review = text
                        }
                        
                        business.reviews.append(item)
                    }
                }
                completion(business, nil)
                return
            } catch let err as NSError {
//                print(err)
                completion(nil, err)
                return
            }
        }).resume()
    }
    
    func getAccessToken() -> String? {
        return access_token
    }
}
