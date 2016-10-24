//
//  APIManager.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-21.
//  Copyright © 2016 Ishmeet. All rights reserved.

import Foundation
import CoreLocation
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
                print(err)
                completionHandler(apiError)
                return
            }
        }
        task.resume()
    }
    
    func searchYelp(parameter: String, location: CLLocation, completion: @escaping (NSDictionary?, NSError?) -> Void) {
        let limit = "10"
        let locale = "en_CA"
        let apiError = NSError(domain: "Could not obtain business information from Yelp server.", code: 300, userInfo: nil)
        
        
        if access_token == nil {
            getAccessToken(completionHandler: { (tokenError) in
                if (tokenError != nil) {
                    print("error in access token retrieval")
                    completion(nil, tokenError)
                    return
                }
                self.searchYelp(parameter: parameter, location: location, completion: completion)
            })
        } else {
            let searchString = "?term=" + parameter + "&latitude=" + String(location.coordinate.latitude) + "&longitude=" + String(location.coordinate.longitude) + "&locale=" + locale + "&limit=" + limit
            let url = URL(string: "https://api.yelp.com/v3/businesses/search" + searchString)
            let request = NSMutableURLRequest(url: url!)
            request.httpMethod = "GET"
            request.addValue("Bearer " + self.access_token, forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
                if error != nil {
                    print("error in search data task")
                    completion(nil, error as NSError?)
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                    guard let _ = json["businesses"] else {
                        print("jhfgsd")
                        completion(nil, apiError)
                        return
                    }
                    completion(json, nil)
                    return
                } catch let err as NSError {
                    print(err)
                    completion(nil, err)
                    return
                }
            }).resume()
        }
    }
}
