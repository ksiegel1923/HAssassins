//
//  LogInViewController.swift
//  HAssassins
//
//  Created by Ben Altschuler on 11/26/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseFirestore

class LogInViewController: UIViewController, CLLocationManagerDelegate {
    
    //All the labels on the view controller
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var signIn: UIButton!
    @IBOutlet weak var signUp: UIButton!
    @IBOutlet weak var password: UITextField!
    
    var db: Firestore! //declaring the databse
    var userArray = [User] () //an array of all the users playing that will be filled in from the database
    var userPlaying: User? //the user that logs in
    var locationManager: CLLocationManager? //location of the user
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore() //connect the database to firebase
        loadDataFirebase() //grab information from the database
        
        locationManager = CLLocationManager() //Iniliaze the location maneger
        locationManager!.delegate = self //Set the delegatee of the location maneger to this viewController
        locationManager!.requestAlwaysAuthorization() //Ask the phone to be able to always get location
    }
    
    //Get the user information from the database
    func loadDataFirebase(){
        //Get all the documents in the users collection
        db.collection("users").getDocuments(){
            //querySnapot is the data the database returns and error is an error if connection to the database failed
            querySnapshot, error in
            //If there is an error, print the error
            if let error = error{
                print(error.localizedDescription)
            }else{
                //set the user array to empty as we are going to reset its values
                self.userArray = []
                //Loop through all the documents in the querSnapshot (each document will have the data for a user)
                for doc in querySnapshot!.documents{
                    //Create a user using the User initalizaer with the dictionary data contained within doc (doc.data())
                    var tempUser = User(dictionary: doc.data())
                    //Set the user id equal to the DocumentID.
                    tempUser!.id = doc.documentID
                    //Add the new user to the array
                    self.userArray.append(tempUser!)
                }
            }
        }
    }
    
    //What happens when the sign in button is tapped:
    @IBAction func signInTapped(_ sender: Any) {
        
        //save the information that was typed into the text boxes:
        let usernameText:NSString = username.text! as NSString
        let passwordText:NSString = password.text! as NSString
        
        //declare an alert that pops up if the information 
        let alert = UIAlertController(title: "User does not exist!", message: "Please try again", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        //if either of the text fields are blank then show the alert and tell them to try again
        if (usernameText == "" || passwordText == "") {
            self.present(alert, animated: true)
        }
        else {
            for (index, user) in userArray.enumerated() {
                if usernameText as String == user.username { //find the user with this username
                    if passwordText as String == user.password { //check if the password is correct
                        userPlaying = user //set the user
                        updateLocation() //call the function that finds the user's location
                        performSegue(withIdentifier: "SignInGood", sender: self) //move to the next page
                    }
                        //if the password does not match then present the alert
                    else{
                        self.present(alert, animated: true)
                    }
                    //if the user is not in the database then present the alert
                    if index == (userArray.count-1) {
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
     //This function updates the location of the user in the database using the location manager on the phone
       func updateLocation(){
           //If the location value of the location Mangaer is not null we will begin sending the current location to the database.
           if let location = self.locationManager?.location{
               //We get the "users" collecetion from the database and choose the document with the id of the current user.
               //We then set the lattitude and longitude fields of this user in the database, adding a mergeFields argumeent to the database to only override thelattitude and lonngitude fields.
               self.db.collection("users").document(self.userPlaying!.id!).setData([
                   "lattitude": String(describing: location.coordinate.latitude),
                   "longitude": String(describing: location.coordinate.longitude)
               ], mergeFields: ["lattitude", "longitude"]) { (error:Error?) in
                   //If there is an error while trying to set data to the database
                   if let error = error{
                       print("\(error.localizedDescription)")
                   //Otherwisee print sucess
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
                    print("GETTING Location Login")
                }
            }
        }
    }
    
    //Information that will be sent to other view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBar = segue.destination as? UITabBarController{ //set the tab bar as the destination
            
            //Send which user signed in to all the pages:
            if let nav0View = tabBar.viewControllers?[0] as? UINavigationController{
                if let profileView = nav0View.viewControllers[0] as? ProfileViewController{ //sending it to the profile view controller
                    profileView.user = userPlaying
                }
            }
            if let nav1View = tabBar.viewControllers?[1] as? UINavigationController{
                if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{ //sending it to the alive table view controller
                    aliveView.user = userPlaying
                }
            }
            if let nav2View = tabBar.viewControllers?[2] as? UINavigationController{
                if let leaderboardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{ //sending it to the leaderboard table view controller
                    leaderboardView.user = userPlaying
                }
            }
            if let nav3View = tabBar.viewControllers?[3] as? UINavigationController{
                if let gameView = nav3View.viewControllers[0] as? GamesTableViewController{ //sending it to the games table view controller
                    gameView.user = userPlaying
                }
            }
        }
    }
}
