//
//  AliveTableViewController.swift
//  HAssassins
//
//  Created by Ben Altschuler on 12/3/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseFirestore

class AliveTableViewController: UITableViewController, CLLocationManagerDelegate {
    var db:Firestore!
    var locationManager: CLLocationManager?
    var userArray = [User]() //an array of all the users playing
    var usersAlive = [User]() //an array of all the users that are still alive
    var user:User?
    var userImages:[String: UIImage] = [:] //a dictionary that maps a user to their profile picture
    var games: [Game] = [] //an array of all the games that exist
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
        db = Firestore.firestore() //connect the database to firebase
        
        locationManager = CLLocationManager() //Iniliaze the location maneger
        locationManager?.delegate = self //Set the delegatee of the location maneger to this viewController
        locationManager?.requestAlwaysAuthorization() //Ask the phone to be able to always get location
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Load all the users from the database
        loadDataFirebase(){ (tempUsers) in
            self.usersAlive = tempUsers //fill in the usersAlive array once the completion handler has finished
            //If you are the only user alive present an alert telling the user that they won
            if (self.usersAlive.count == 0 && self.user?.isAlive == true && self.user?.winNotification==false){
                let alert = UIAlertController(title: "Congrats", message: "You Won!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.user?.winNotification = true
            }
            //If another user has killed you then present an alert telling the user that they were killed
            if (self.user?.isAlive == false && self.user?.loseNotification==false){
                let alert2 = UIAlertController(title: "Sorry", message: "You have been killed", preferredStyle: .alert)
                alert2.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert2, animated: true)
                self.user?.loseNotification = true
            }
            //SEND THIS NEW USER INFORMATION TO THE OTHER VIEW CONTROLLERS:
            if let nav0View = self.tabBarController!.viewControllers?[0] as? UINavigationController{
                if let profileView = nav0View.viewControllers[0] as? ProfileViewController{ //sending it to the profile view controller
                    profileView.user = self.user
                }
            }
            if let nav2View = self.tabBarController!.viewControllers?[2] as? UINavigationController{
                if let leaderboardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{ //sending it to the leaderboard table view controller
                    leaderboardView.user = self.user
                }
            }
        }
        loadGamesFirebase() //load all the information about the games from the database
        //Have the header indicate which game the user is playing in:
        for game in games { //first determine which game they are playing in
            if game.id == user?.gameId {
                self.navigationItem.title = "\(game.name): Alive Players" //then display the header
            }
        }
    }
    
    //Function that loads all the information from the database about the different games
    func loadGamesFirebase(){
        //Here we get all the documeents in the games collection from the database
        db.collection("games").getDocuments(){
            //querySnapot is the data the database returns and error is an error if connection to the database failed
            querySnapshot, error in
            //If there is an error, print the error
            if let error = error{
                print(error.localizedDescription)
            }else{
                //set the games array to eempty as we are going to reset its values
                self.games = []
                //Loop through all the documents in the querSnapshot (each document will have the data for a game)
                for doc in querySnapshot!.documents{
                    //Create a game using the Game initalizaer with the dictionary data contained within doc (doc.data())
                    if var tempGame = Game(dictionary: doc.data()){
                        //Set the game id of the Game equal to thee documentID of the document which will serve as a uniuqe identifier for that game.
                        tempGame.id = doc.documentID
                        //Add the newly created game to the game array
                        self.games.append(tempGame)
                    }
                }
                self.tableView.reloadData() //reload the tableview to show the updated information
            }
        }
    }
    
    //Function that loads all the information from the database about the different users
    func loadDataFirebase(completionHandler: @escaping(([User]) -> Void)){ //includes a completion handler because sometimes it takes awhile to fetch the data
        var tempUsers: [User] = []
        db.collection("users").getDocuments(){
            //querySnapot is the data the database returns and error is an error if connection to the database failed
            querySnapshot, error in
            if let error = error{ //if there is an error getting the information
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
                    tempUser!.id = doc.documentID
                    //Check if the images dictionary already has information for tempUser!
                    if self.userImages[tempUser!.id!] == nil{
                        //Get Image
                        if let url = URL(string: tempUser!.url){
                            URLSession.shared.dataTask(with: url, completionHandler: { (data,response, error) in
                                if error != nil {
                                    print(error?.localizedDescription)
                                    return
                                }
                                DispatchQueue.main.async {
                                    //Set new data in the imagesDictionary
                                    self.userImages[(tempUser?.id!)!] = UIImage(data: data!)
                                    if let nav2View = self.tabBarController!.viewControllers?[2] as? UINavigationController{
                                        if let leaderBoardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{
                                            let newUserImages = self.userImages.merging(leaderBoardView.userImages) { (current, _) in current }
                                        }
                                    }
                                    self.tableView.reloadData()
                                }
                            }).resume()
                        }
                    }
                    //If the tempUser is not the ViewControllers user add to the array and if the tempUser and the user on the ViewController have the same game id.
                    if tempUser!.id != self.user!.id && tempUser!.isAlive == true && tempUser!.gameId == self.user!.gameId{
                        tempUsers.append(tempUser!)
                    }
                }
                DispatchQueue.main.async{
                    self.tableView.reloadData()
                }
                completionHandler(tempUsers) //send the array of users after everything has been loaded
            }
        }
    }
    
    //Function to determine whether a particular user is alive and should be added to the table view
    func inArray(user:User) -> Bool{
        for userAlive in self.usersAlive{
            if user.id == userAlive.id{
                return true
            }
        }
        return false
    }
    
    //Function that determines how many cells should be displayed in the tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersAlive.count
    }
    
    //Function that assigns the size of the cells in the tableview
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LOCATION")
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    print("GETTING Location")
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //define the cell in the tableview
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as? AliveTableViewCell
        //set the image and name of the person to a cell
        cell?.nameLabel.text = usersAlive[indexPath.row].name
        cell?.profileImage.image = nil
        //While the image is loading show a loading spinner (UI activity view)
        if let image = userImages[usersAlive[indexPath.row].id!]{ //once the image has loaded display the image
            cell!.indicator.stopAnimating()
            cell!.profileImage.image = image
        }else if cell!.indicator.isAnimating == false { //otherwise show the loading spinner
            cell!.indicator.startAnimating()
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let catchRowAction = UITableViewRowAction(style: UITableViewRowAction.Style.default, title: "Kill", handler:{action, indexpath in
            self.db.collection("users").getDocuments() {
                //querySnapot is the data the database returns and error is an error if connection to the database failed
                querySnapshot, error in
                if let error = error{
                    print(error.localizedDescription)
                }else{
                    //Set the caughut User
                    var caughtUser = self.usersAlive[indexPath.row]
                    //Get the location of the caught user
                    var caughtUserLoc: CLLocation!
                    if Double(caughtUser.lattitude) != nil && Double(caughtUser.longitude) != nil{
                        caughtUserLoc = CLLocation(latitude: Double(caughtUser.lattitude)!, longitude: Double(caughtUser.longitude)!)
                    }else{
                        caughtUserLoc = CLLocation(latitude: 0.0, longitude: 0.0)
                    }
                    //Location of the current location
                    var userLoc: CLLocation!
                    if Double(self.user!.lattitude) != nil && Double(self.user!.longitude) != nil{
                        userLoc = CLLocation(latitude: Double(self.user!.lattitude)!, longitude: Double(self.user!.longitude)!)
                    }else{
                        userLoc = CLLocation(latitude: 40.0, longitude: 40.0)
                    }
                    //Distance between theusers
                    let distance = caughtUserLoc.distance(from: userLoc)
                    //If the distance is less than 100 meters killed functionality
                    if distance < 100{
                        //You killed somebody funcitonaltiy
                        let alert = UIAlertController(title: "You killed \(caughtUser.name)!", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true)
                        //Change the isAlvie Flag of the caughtUser
                        caughtUser.isAlive = false
                        //Update the dead user in the database
                        self.updateIsAlive(user: caughtUser, isAlive: caughtUser.isAlive)
                        //Update the new numbere of kills for the user of this view controller by adding the number of kills the caught user had
                        self.updateNumberOfKills(caughtUser: caughtUser)
                        //Reload the database
                        self.loadDataFirebase{(tempUsers) in
                            self.usersAlive = tempUsers
                        }
                    }else{
                        //Too far functionality
                        print("TOO FAR")
                        let alert = UIAlertController(title: "You are too far from \(caughtUser.name)! You are \(Int(distance)) meters from them. ", message: "You must be within 100 meters to kill them", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
            }})
        return [catchRowAction]
        
    }
    
    //Function that updates the location of the user
    func updateLocation(user:User){
        //set lattitude and longitude for the user
        self.db.collection("users").document(user.id!).setData([
            "lattitude": String(describing: self.locationManager!.location!.coordinate.latitude),
            "longitude": String(describing: self.locationManager!.location!.coordinate.longitude)
        ], mergeFields: ["lattitude", "longitude"]) { (error:Error?) in
            if let error = error{
                print("\(error.localizedDescription)")
            }else{
                print("Success Updating Location")
            }
        }
    }
    
    //Function to update that the user has been killed:
    func updateIsAlive(user:User,isAlive:Bool){
        self.db.collection("users").document(user.id!).setData(["isAlive": isAlive], mergeFields: ["isAlive"]){ (error:Error?) in
            if let error = error{
                print("\(error.localizedDescription)")
            }else{
                print("Success Updating isAlive")
            }
        }
    }
    
    //Function to update the number of kills that the killer now has after killing someone else
    func updateNumberOfKills(caughtUser: User){
        user!.numberKills = user!.numberKills + caughtUser.numberKills + 1
        
        self.db.collection("users").document((user?.id!)!).setData(["numberKills": self.user!.numberKills], mergeFields: ["numberKills"]){ (error:Error?) in
            if let error = error{
                print("\(error.localizedDescription)")
            }else{
                print("Success Updating numberOfKills")
            }
        }
    }
}

