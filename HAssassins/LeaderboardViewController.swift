//
//  LeaderboardViewController.swift
//  HAssassins
//
//  Created by Kara Siegel on 12/3/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController {
    var user: User? //the user that was clicked on the table view controller
    var place = 0 //the users place in the leaderboard (will receive info from the leaderboard table view controller)
    var userImage: UIImage? //the user's profile picture
    var indicator = UIActivityIndicatorView()
    
    //All the labels displayed on the storyboard
    @IBOutlet var userPicture: UIImageView!
    @IBOutlet var userName: UILabel!
    @IBOutlet var userKills: UILabel!
    @IBOutlet var userPlace: UILabel!
    @IBOutlet var userAlive: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator()
        //Setting all the labels on the storyboard to have the correct information about the user
        userName.text = user?.name
        userKills.text = "Number of Kills: \(user!.numberKills)"
        userPlace.text = "Place in Leaderboard: \(String(place))"
        
        //The text will show if the user is dead or alive
        if user?.isAlive == true{
            userAlive.text = "Alive"
        }
        else{
            userAlive.text = "Dead"
        }
        //Set the user image
        if userPicture.image != nil{
            userPicture.image = userImage
        }else{ //if the image has not loaded yet then show the loading spinning symbol so the user knows it is still loading
            indicator.startAnimating()
            if let url = URL(string: user!.url){
                URLSession.shared.dataTask(with: url, completionHandler: { (data,response, error) in
                    if error != nil {
                        print(error?.localizedDescription)
                        return
                    }
                    DispatchQueue.main.async {
                        //Stop animating once returned.
                        self.indicator.stopAnimating()
                        //Set the profile picture
                        self.userPicture.image = UIImage(data: data!)
                    }
                }).resume()
            }
        }
        
        
    }
    
    //Function so we can show the spinning loading symbol
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.gray
        indicator.center = CGPoint(x: self.userPicture.frame.midX, y: self.userPicture.frame.minY)
        self.userPicture.addSubview(indicator)
    }
}

