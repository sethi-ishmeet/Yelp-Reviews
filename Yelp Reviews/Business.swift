//
//  Business.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-25.
//  Copyright © 2016 Ishmeet. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

protocol BusinessClassDelegate {
    func didUpdateBusinessImage(id: String)
}

class Business {
    var id: String!
    var Name: String!
    var price: String!
    
    var image_url: String! {
        didSet {
            self.downloadFrom(link: image_url) { (image) in
                self.image = image
            }
        }
    }
    var image: UIImage! {
        didSet {
            if delegate != nil {
                DispatchQueue.main.async {
                    self.delegate.didUpdateBusinessImage(id: self.id)
                }
            }
            
        }
    }
    
    var location: CLLocation!
    var address: String!
    var fullAddress: String!
    var categories: String!
    var rating: Double!
    var review_count: Int!
    
    var images: [UIImage] = [UIImage]()
    var image_urls: [String]! {
        didSet {
            self.images.removeAll()
            
            for i in 0..<image_urls.count {
                downloadFrom(link: image_urls[i], completion: { (image) in
                    self.images.append(image)
                })
            }
            
            if image_urls.count == 0 {
                self.images.append(#imageLiteral(resourceName: "imageNA"))
            }
            
        }
    }
    
    var phone: String!
    
    var hours: [NSDictionary]! {
        didSet {
            let date = NSDate()
            let calendar = NSCalendar.current
            var component = calendar.component(.weekday, from: date as Date)
            if component == 1 {
                component = 6
            } else {
                component -= 2
            }
            
            for hour in hours {
                if (hour["day"] as! Int) == component {
                    var formatter = DateFormatter()
                    formatter.dateFormat = "HHmm"
                    
                    let startTime = formatter.date(from: hour["start"] as! String)
                    let endTime = formatter.date(from: hour["end"] as! String)
                    
                    formatter = DateFormatter()
                    formatter.dateFormat = "hh:mm a"
                    
                    if self.hoursToday != nil {
                        self.hoursToday = self.hoursToday +
                            "\n" +
                            formatter.string(from: startTime!) + " - " + formatter.string(from: endTime!)
                    } else {
                        self.hoursToday = formatter.string(from: startTime!) + " - " + formatter.string(from: endTime!)
                    }
//                    print(self.hoursToday)
                }
            }
            
            if hoursToday == nil {
                hoursToday = "Not Available"
            }
            
        }
    }
    
    var hoursToday: String!
    
    var reviews: [Review] = [Review]()
    
    var delegate: BusinessClassDelegate!
    
    func downloadFrom(link: String, completion: @escaping (UIImage) -> Void) {
        guard let url = URL(string: link) else {
//            print("image url error")
            completion(#imageLiteral(resourceName: "imageNA"))
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
//                print("photo data task error")
                completion(#imageLiteral(resourceName: "imageNA"))
                return
            }
            completion(UIImage(data: data!)!)
        }.resume()
    }
}
