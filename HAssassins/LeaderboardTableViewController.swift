//
//  LeaderboardTableViewController.swift
//  HAssassins
//
//  Created by Kara Siegel on 12/3/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import FirebaseFirestore

class LeaderboardTableViewController: UITableViewController {
    var db:Firestore!
    var userArray = [User] () //an array that will be filled in with all the users from the database
    var leaderboardArray = [User] ()
    var counter = 0 //counts how many people have the same number of kills
    var counter2 = 0 //helps keep track of place in leaderboard
    var place = 1 //variable for a user's place in the leaderboard
    var user:User? //the user signed into the app
    var userImages: [String: UIImage] = [:] //a dictionary with every user's profile image
    var leaderboard = [(p: Int, u: User)]() //Mapping the user's place in the leaderboard to a specific user
    var games:[Game] = [] //an array of all the games that exist (will be filled in from the database)
    var countAlivePlayers = 0 //variable that will count the number of players that are still alive in the game
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        db = Firestore.firestore() //connects the database to firebase
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Resets all these variables everytime the tableview appears
        leaderboardArray = []
        userArray = []
        counter = 0
        counter2 = 0
        place = 1
        countAlivePlayers = 0
        
        //Load information about the users from the database (must use a completion handler because sometimes it takes awhile)
        loadDataFirebase(){ (tempUsers) in
            self.userArray = tempUsers //set the userArray with all the users
            //For loops counts how many players are still alive in the game
            for user in self.userArray{
                if user.isAlive == true {
                    self.countAlivePlayers += 1
                }
            }
            //If the user is the only player still alive then present an alert saying they won
            if (self.countAlivePlayers == 1 && self.user?.isAlive == true && self.user?.winNotification==false){
                let alert = UIAlertController(title: "Congrats", message: "You Won!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.user?.winNotification = true //this is a global flag that shows that the user has already been notified that they won the game
            }
            self.leaderboard = self.leaderBoardAlgorithm()
            if (self.user?.isAlive == false && self.user?.loseNotification==false){
                let alert2 = UIAlertController(title: "Sorry", message: "You have been killed", preferredStyle: .alert)
                alert2.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert2, animated: true)
                self.user?.loseNotification = true //a global flag that shows the user has already been notified that they were killed
            }
            //Send the information about the user to other view controllers:
            if let nav0View = self.tabBarController!.viewControllers?[0] as? UINavigationController{
                if let profileView = nav0View.viewControllers[0] as? ProfileViewController{ //sending it to the profile view controllers
                    profileView.user = self.user
                }
            }
            if let nav1View = self.tabBarController!.viewControllers?[1] as? UINavigationController{
                if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{ //sending it to the alive table view controller
                    aliveView.user = self.user
                }
            }
        }
        loadGamesFirebase() //load all the information about the games from the database
        
        //Reset the header so that it also shows what game the user is currently playing in
        for game in games {
            if game.id == user?.gameId {
                self.navigationItem.title = "\(game.name): Leaderboard"
            }
        }
    }
    
    //Grab the information about the games from the database
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
                self.tableView.reloadData()
            }
        }
    }
    
    //Grab the information about the users from the database
    func loadDataFirebase(completionHandler: @escaping(([User]) -> Void)){ //we use a completion handler because it takes a lot of time to grab the information from the database
        var tempUsers : [User] = [] //a temp array that will be filled with the users from the database
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
                                    }
                                }).resume()
                            }
                        }
                        tempUsers.append(tempUser!)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                    
                }
                //Set data for the leaderboardArray
                self.leaderboardArray = tempUsers
                completionHandler(tempUsers)
            }
        }
    }
    
    //Declares the number of sections in the tableview
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Declares the number of rows in the tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count //there is a cell for every user playing
    }
    
    //A function that calculates what place every user is in the leaderboard
    func leaderBoardAlgorithm() -> [(p: Int, u: User)]{
        var leaderboard: [(p: Int, u: User)] = []
        //ALGORITHM TO DETERMINE WHAT PLACE EVERYONE IS IN THE LEADERBOARD
        for _ in userArray{
            var maxKills = 0 //variable keeping track of who has the max number of kills
            for person in leaderboardArray { //determines the max number of kills of all the users that are not already listed in the leaderboard
                if person.numberKills > maxKills {
                    maxKills = person.numberKills
                }
            }
            //These two if statements deal with people that are tied
            if counter == 0 {
                for person in leaderboardArray {
                    if person.numberKills == maxKills {
                        counter+=1 //the counter is the number of people that are tied for this particular number of kills
                        place = place + counter2 //this determines the place (# in leaderboard) of each player
                        counter2 = 0
                    }
                }
            }
            if counter > 0 { //keeping track of how many people are tied and if they were written into the leaderboard
                counter-=1
                counter2+=1
            }
            for (index, person) in leaderboardArray.enumerated() { //writes a user into the leaderboard
                if person.numberKills == maxKills {
                    leaderboard.append((p: place, u: person))
                    leaderboardArray.remove(at: index) //remove this user from the temporary array
                    break
                }
            }
        }
        return leaderboard
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Declare what each cell is
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) //declares the cell in the tableview
        //Reset the asthetics of the Table View cell as they are reused
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16.0)
        cell.textLabel?.textColor = UIColor.black
        
        //Fill in the person's username as the text of the cell
        let person = leaderboard[indexPath.row].u
        cell.textLabel?.text = "\(leaderboard[indexPath.row].p) | \(person.username)"
        
        //If the person is dead then have their name be in red
        if person.isAlive==false{
            cell.textLabel?.textColor = UIColor.red
        }
        //If the user matches the user signed in have their name in bold
        if person == user{
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        }
        return cell
    }
    
    //Function to send information to the next page (that displayed information about the user that was clicked on)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "leaderboardToPerson",
            let destination = segue.destination as? LeaderboardViewController,
            let index = tableView.indexPathForSelectedRow?.row {
            destination.user = leaderboard[index].u //send the user clicked
            destination.place = leaderboard[index].p //send the place in leaderboard of the user clicked
            destination.userImage = userImages[leaderboard[index].u.id!] //send the profile pic of the user clicked
        }
    }
}

