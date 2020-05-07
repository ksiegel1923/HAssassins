//
//  GamesTableViewController.swift
//  HAssassins
//
//  Created by Ben Altschuler on 12/8/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseFirestore

class GamesTableViewController: UITableViewController {
    
    @IBOutlet var newGameButton: UIBarButtonItem!
    var db:Firestore! //declare the database
    var games: [Game] = [] //declaring the array that will be filled in with information about each game
    var user:User? //the user that is signed in right now
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        db = Firestore.firestore() //connecting the database to firebase
        loadGamesFirebase() //load the information about each game from the database
        tableView.reloadData() //Reload teh tableView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadGamesFirebase() //reload information about the games everytime the user goes to the games tab
        tableView.reloadData() //reload the tableview with the new information
    }
    
    //The number of sections in the table view
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Function that grabs the information about the games from firebase
    func loadGamesFirebase(){
        //Load all the documents from the game collection
        db.collection("games").getDocuments(){
            //querySnapot is the data the database returns and error is an error if connection to the database failed
            querySnapshot, error in
            //If there is an error, print the error
            if let error = error{
                print(error.localizedDescription)
            }else{
                //Set the games array to empty
                self.games = []
                //Loop through all the documents in the querSnapshot (each document will have the data for a game)
                for doc in querySnapshot!.documents{
                    //Create a new game
                    if var tempGame = Game(dictionary: doc.data()){
                        //Set the id of the game to the docuemnt ID
                        tempGame.id = doc.documentID
                        //Add the new game to the games array
                        self.games.append(tempGame)
                        
                    }
                }
                //Reload the tableView
                self.tableView.reloadData()
            }
        }
    }
    
    //Declares the number of cells in the tableview
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    //Sets the information for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) //Declare the cell
        cell.textLabel?.text = games[indexPath.row].name //set the text on the cell to be the name of the game
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16.0) //reset the fond
        //Make the name of the game you are currently playing in be in bold
        if games[indexPath.row].id == user?.gameId {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
        }
        return cell
    }
    
    //What happens if the user tries to join a new game
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //1. Create the alert controller.
        if self.games[indexPath.row].id != self.user?.gameId{
            let alert = UIAlertController(title: "Join Game", message: "Enter the Code", preferredStyle: .alert)
            
            //2. Add the text field
            alert.addTextField { (textField) in
                textField.text = "Code"
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                if (textField!.text! == self.games[indexPath.row].code) {
                    //Alert the user that they entered the new game
                    let successAlert = UIAlertController(title: "You have entered the game: \(self.games[indexPath.row].name)", message: nil, preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:nil))
                    self.present(successAlert, animated: true)
                    //Reset the gameID of the user after they switch games:
                    self.user?.gameId = self.games[indexPath.row].id!
                    //Update the user with their new information (calling a function later on in the code)
                    self.updateUser()
                    //SENDING THE NEW USER INFORMATION TO THE OTHER VIEW CONTROLLERS:
                    if let nav2View = self.tabBarController!.viewControllers?[2] as? UINavigationController{
                        if let leaderboardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{ //sending it to the leaderboard tableview controller
                            leaderboardView.user = self.user
                        }
                    }
                    if let nav1View = self.tabBarController!.viewControllers?[1] as? UINavigationController{
                        if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{ //sending it to the alive tableview controller
                            aliveView.user = self.user
                        }
                    }
                    if let nav0View = self.tabBarController!.viewControllers?[0] as? UINavigationController{
                        if let profileView = nav0View.viewControllers[0] as? ProfileViewController{ //sending it to the profile view controller
                            profileView.user = self.user
                            
                        }
                    }
                    self.tableView.reloadData() //reload the tableview with the updated information
                }
                else{ //display an alert if the code that was entered for the game is incorrect:
                    let failureAlert = UIAlertController(title: "You have entered the wrong code for game: \(self.games[indexPath.row].name)", message: nil, preferredStyle: .alert)
                    failureAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler:nil))
                    self.present(failureAlert, animated: true) //present the alert to the user
                }
                //Unseleect the table view cell that was selected
                tableView.cellForRow(at: indexPath)?.isSelected = false
            }))
            self.present(alert, animated: true, completion: nil)
        }
         //Unseleect the table view cell that was selected
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
    
    //Update all the user's information in the database after they have changed their gameId
    func updateUser(){
        //Get the docuement in the users collecetion with the user!.id as its id. Set isAlive, numberKills, and Game. We use a mergeFields argument to tell the database which fields to override
        db.collection("users").document(user!.id!).setData(["isAlive": true, "numberKills":0, "game": user!.gameId], mergeFields:["isAlive","numberKills", "game"]){(error:Error?) in
            if let error = error{
                print("\(error.localizedDescription)")
            }else{
                print("Success Updating User")
            }
        }
    }
    
    //Sending which user is signed into the app to the create game view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gameVC = segue.destination as? CreateGameViewController{
            gameVC.user = self.user
        }
    }
    
    
}
