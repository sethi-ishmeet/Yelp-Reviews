//
//  ReviewTableViewCell.swift
//  Yelp Reviews
//
//  Created by Ishmeet Singh Sethi on 2016-10-25.
//  Copyright © 2016 Ishmeet. All rights reserved.
//

import UIKit

class ReviewTableViewCell: UITableViewCell {

    @IBOutlet var userImageView: UIImageView!
    
    @IBOutlet var lblUserName: UILabel!
    
    @IBOutlet var lblUserReview: UILabel!
    
    
    @IBOutlet var imgStar1: UIImageView!
    @IBOutlet var imgStar2: UIImageView!
    @IBOutlet var imgStar3: UIImageView!
    @IBOutlet var imgStar4: UIImageView!
    @IBOutlet var imgStar5: UIImageView!
}
