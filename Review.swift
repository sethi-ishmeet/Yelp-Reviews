//
//  Review.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-25.
//  Copyright © 2016 Ishmeet. All rights reserved.
//

import Foundation
import UIKit

protocol ReviewClassDelegate {
    func didUpdateUserImage(row: Int)
}

class Review {
    var rating: Double!
    var userName: String!
    var userImageURL: String! {
        didSet {
            downloadFrom(link: userImageURL) { (image) in
                self.userImage = image
            }
        }
    }
    var userImage: UIImage! {
        didSet {
            delegate.didUpdateUserImage(row: self.row)
        }
    }
    var review: String!
    
    var row: Int!
    
    var delegate: ReviewClassDelegate!
    
    func downloadFrom(link: String, completion: @escaping (UIImage) -> Void) {
        guard let url = URL(string: link) else {
            print("image url error")
            completion(#imageLiteral(resourceName: "imageNA"))
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print("photo data task error")
                completion(#imageLiteral(resourceName: "imageNA"))
                return
            }
            completion(UIImage(data: data!)!)
            return
        }.resume()
    }
    
}
