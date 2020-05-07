//
//  CreateGameViewController.swift
//  HAssassins
//
//  Created by Ben Altschuler on 12/8/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CoreLocation
import Firebase
import FirebaseDatabase
import FirebaseStorage
class CreateGameViewController: UIViewController {
    //Connecting the text views from the storyboard
    @IBOutlet var nameOfGame: UITextField!
    @IBOutlet var codeLabel: UITextField!
    var gameArray:[Game]? //an array that will be filled in with information about the games
    var user:User? //the user that is currently signed into the app
    var db:Firestore! //declaring the database
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore() //connect the database to firebase
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadGamesFirebase() //reload informatino about the games everytime this page is shown
    }
    
    //What happens when the create new game button is clicked
    @IBAction func createNewGame(_ sender: UIButton) {
        //Save the information entered into the text boxes
        let nameText:String = nameOfGame.text! as String
        let codeText:String = codeLabel.text! as String
        let id = UUID() //get a random unique id
        if inGames(name: nameText) == false{
            self.db.collection("games").document(id.uuidString).setData([
                "name": nameText, "code": codeText]) { (error:Error?) in
                    if let error = error{
                        print("\(error.localizedDescription)")
                        
                    }else{
                        self.user?.gameId = id.uuidString //set the game id to the random unique id
                        self.user?.winNotification = true //make sure the user doesn't receive a pop up saying they won because they are the only player in the game
                        self.updateUser() //update the user with their new game ID
                        //Show an alert telling the user that they created and entered a new game
                        let alert = UIAlertController(title: "You have created and been added to the game: \(nameText)", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:
                            {(alert: UIAlertAction!) in
                                //SEND THE NEW INFORMATION ABOUT THE USER TO OTHER VIEW CONTROLLERS
                                if let gameTable = self.navigationController?.viewControllers[0] as? GamesTableViewController{ //send it to the games table view controller
                                    gameTable.user = self.user
                                    
                                    if let nav2View = gameTable.tabBarController!.viewControllers?[2] as? UINavigationController{
                                        if let leaderboardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{ //send it to the leaderboard table view controller
                                            leaderboardView.user = self.user
                                        }
                                    }
                                    if let nav1View = gameTable.tabBarController!.viewControllers?[1] as? UINavigationController{
                                        if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{ //send it to the alive table view controller
                                            aliveView.user = self.user
                                        }
                                    }
                                    if let nav0View = gameTable.tabBarController!.viewControllers?[0] as? UINavigationController{
                                        if let profileView = nav0View.viewControllers[0] as? ProfileViewController{ //send it to the profile view controller
                                            profileView.user = self.user
                                        }
                                    }
                                    gameTable.tableView.reloadData() //reload the tableview to show the updated information
                                }
                                self.navigationController?.popViewController(animated: true) //return to the games table view controller page
                                
                        }))
                        self.present(alert, animated: true)
                    }
            }
        }else{
            //declare an alert that pops up if a game with this name already exists
            let alert = UIAlertController(title: "Game with that name already exists!", message: "Please enter a unique name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    //Update the database with the new information about the user
    func updateUser(){
        //Updates the document in the users collection with the id of the current users id. The isAlive is set to true, numberKills to 0 and the game is set to the id of the new game the user is in. We use a merge field argument to tell the database to only override certian fields.
        db.collection("users").document(user!.id!).setData(["isAlive": true, "numberKills":0, "game": user!.gameId], mergeFields:["isAlive","numberKills", "game"]){(error:Error?) in
            //If error print error, otherwise print success
            if let error = error{
                print("\(error.localizedDescription)")
            }else{
                print("Success Updating User ")
            }
        }
    }
    
    //Grab information about the games from the database
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
                self.gameArray = []
                //Loop through all the documents in the querSnapshot (each document will have the data for a game)
                for doc in querySnapshot!.documents{
                    //Create a game using the Game initalizaer with the dictionary data contained within doc (doc.data())
                    if var tempGame = Game(dictionary: doc.data()){
                        //Set the game id of the Game equal to thee documentID of the document which will serve as a uniuqe identifier for that game.
                        tempGame.id = doc.documentID
                        //Add the newly created game to the game array
                        self.gameArray?.append(tempGame)
                    }
                }
            }
        }
    }
    
    //Function to see if a game with this name already exists
    func inGames(name: String) -> Bool{
        for game in gameArray!{
            if (game.name == name){
                return true
            }
        }
        return false
    }
}

