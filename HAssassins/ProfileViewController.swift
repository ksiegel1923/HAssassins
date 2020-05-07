//
//  ProfileViewController.swift
//  HAssassins
//
//  Created by Ben Altschuler on 11/26/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseFirestore

class ProfileViewController: UIViewController, CLLocationManagerDelegate {
    
    //All the labels that appear on the view controllers
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var profileKills: UILabel!
    @IBOutlet var aliveLabel: UILabel!
    @IBOutlet var gamePlaying: UILabel!
    
    //Declaring the variables used throughout the code
    var user:User? //the user that signed into the app
    var timer = Timer()
    var locationManager: CLLocationManager?
    var db: Firestore! //declaring the database
    var indicator = UIActivityIndicatorView()
    var games: [Game] = [] //an array of all the different games that exist
    var users = [User] () //an array of all the users playing
    var userImages: [String: UIImage] = [:] //a dictionary that maps a user to their profile picture
    var countAlivePlayers = 0 //variable that will count the number of alive players in the game
    var newGame = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore() //connecting the database to firebase
        activityIndicator()
        profileName.text = user?.name //set the label of the profile name to the user's name
        indicator.startAnimating() //have the loading icon appear until the photo downloads
        //Displaying the user's profile image:
        if let url = URL(string: user!.url){
            URLSession.shared.dataTask(with: url, completionHandler: { (data,response, error) in
                if error != nil {
                    //print(error)
                    return
                }
                DispatchQueue.main.async {
                    self.indicator.stopAnimating()
                    self.profilePicture.image = UIImage(data: data!)
                    
                }
            }).resume()
        }
        
        locationManager = CLLocationManager()//Iniliaze the location maneger
        locationManager?.delegate = self //Set the delegatee of the location maneger to this viewController
        locationManager?.requestAlwaysAuthorization() //Ask the phone to be able to always get location
        
        scheduledTimerWithTimeInterval() //Start a timer that gets the users location every 60 seconds
    }
    override func viewDidAppear(_ animated: Bool) {
        //Reset the information about the user each time they go to the profile page
        profileKills.text = "Number of Kills: \(user!.numberKills)"
        if user?.isAlive == true{
            aliveLabel.text = "Alive"
        }
        else {
            aliveLabel.text = "Dead"
        }
        countAlivePlayers = 0
        //Load the users from firebase:
        loadDataFirebase(){ (tempUsers) in
            self.users = tempUsers
            //Count how many players are alive in the game
            for user in self.users{
                if user.isAlive == true {
                    self.countAlivePlayers += 1
                }
            }
            if (self.countAlivePlayers>1 && self.newGame == true){
                self.user?.winNotification=false
            }
            //If you are the only player alive then have an alert telling you that you win
            if (self.countAlivePlayers == 1 && self.user?.isAlive == true && self.user?.winNotification==false){
                let alert = UIAlertController(title: "Congrats", message: "You Won!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.user?.winNotification = true //this boolean makes it so that the alert only appears once
            }
            //If you were killed, have an alert telling you that you were killed
            if (self.user?.isAlive == false && self.user?.loseNotification==false){
                let alert2 = UIAlertController(title: "Sorry", message: "You have been killed", preferredStyle: .alert)
                alert2.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert2, animated: true)
                self.user?.loseNotification = true //boolean to make sure the alert only appears once
            }
            if let nav1View = self.tabBarController!.viewControllers?[1] as? UINavigationController{
                if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{
                    aliveView.user = self.user
                }
            }
            if let nav2View = self.tabBarController!.viewControllers?[2] as? UINavigationController{
                if let leaderboardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{
                    leaderboardView.user = self.user
                }
            }
            
        }
        //Load all the games from firebase
        loadGamesFirebase(){ (tempGames) in
            self.games = tempGames //need to fill the games array with the games from the database
            //Display which game the user is playing in
            for game in self.games{
                if game.id == self.user?.gameId {
                    self.gamePlaying.text = "Game: \(game.name)"
                }
            }
        }
    }
    
    //Function that loads the users from the database
    //We needed to add a completion handler because it takes awhile to grab the information
    func loadDataFirebase(completionHandler: @escaping(([User]) -> Void)){
        var tempUsers : [User] = [] //array of users that will be filled in
        db.collection("users").getDocuments(){
            querySnapshot, error in
            if let error = error{
                print(error.localizedDescription)
                completionHandler([])
            }else{
                //set temp users empty
                tempUsers = []
                //Loop through all the documents in the querySnapshot (each document will have the data for a user)
                for doc in querySnapshot!.documents{
                    //Create a game using the Game initalizaer with the dictionary data contained within doc (doc.data())
                    var tempUser = User(dictionary: doc.data())
                    //Make sure the user is in the same game as the current user.
                    if tempUser?.gameId == self.user?.gameId{
                        //Set the id of the tempUser to the docuemtnID
                        tempUser!.id = doc.documentID
                        //Check if the images dictionary already has information for tempUser!
                        if self.userImages[tempUser!.id!] == nil{
                            //Get image
                            if let url = URL(string: tempUser!.url){
                                URLSession.shared.dataTask(with: url, completionHandler: { (data,response, error) in
                                    if error != nil {
                                        print(error?.localizedDescription)
                                        return
                                    }
                                    DispatchQueue.main.async {
                                        self.userImages[tempUser!.id!] = UIImage(data: data!)
                                        if let nav1View = self.tabBarController!.viewControllers?[1] as? UINavigationController{
                                            if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{
                                            }
                                        }
                                        
                                        
                                    }
                                }).resume()
                            }
                        }
                        tempUsers.append(tempUser!) //add this new user to the array
                    }
                    
                }
                completionHandler(tempUsers) //have the completion handler return the array
            }
        }
    }
    
    //Load the games from the database
    //We are also using a completion handler here
    func loadGamesFirebase(completionHandler: @escaping (([Game]) -> Void)){
        var tempGames: [Game] = [] //an array that will be filled in with all the games
        db.collection("games").getDocuments(){
            querySnapshot, error in
            if let error = error{ //if there is an error downloading the info from the database
                print(error.localizedDescription)
                completionHandler([])
            }else{
                //Set tempGames = []
                tempGames = []
                //Loop through all the documents in the querySnapshot (each document will have the data for a user)
                for doc in querySnapshot!.documents{
                    //Clreate a game
                    if var tempGame = Game(dictionary: doc.data()){
                        //Set id of game
                        tempGame.id = doc.documentID
                        //Add game
                        tempGames.append(tempGame)
                    }
                }
                completionHandler(tempGames) //the completion handler will return an array of all the games
            }
        }
    }
    //Function to have the indicator show up
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.gray
        indicator.center = CGPoint(x: self.profilePicture.frame.midX, y: self.profilePicture.frame.minY)
        self.profilePicture.addSubview(indicator)
        
    }
    //Function that seets a timer to send the location every hour
    func scheduledTimerWithTimeInterval(){
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: Selector("updateLocation"), userInfo: nil, repeats: true)
    }
    
    @objc
    //This function updates the location of the user in the database using the location manager on the phone
    func updateLocation(){
        //If the location value of the location Mangaer is not null we will begin sending the current location to the database.
        if let location = self.locationManager?.location{
            //We get the "users" collecetion from the database and choose the document with the id of the current user.
            //We then set the lattitude and longitude fields of this user in the database, adding a mergeFields argumeent to the database to only override thelattitude and lonngitude fields.
            self.db.collection("users").document(self.user!.id!).setData([
                "lattitude": String(describing: location.coordinate.latitude),
                "longitude": String(describing: location.coordinate.longitude)
            ], mergeFields: ["lattitude", "longitude"]) { (error:Error?) in
                //If there is an error while trying to set data to the database
                if let error = error{
                    print("\(error.localizedDescription)")
                }else{
                    print("Success Updating Location")
                }
            }
        }
    }
    
    //The location manager function checks to determine weater the user has given acess to the app to use the phones location
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            //If the user has given access always we can begin getting location, whenever we please.
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    print("GETTING Location")
                }
            }
        }
    }
}
