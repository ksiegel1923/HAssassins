//
//  Users.swift
//  HAssassins
//
//  Created by Ben Altschuler on 12/3/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import Foundation
import FirebaseFirestore

//This names a protocal that we will extend
protocol DocumentSerializable {
    init?(dictionary:[String:Any])
}

//This is the user struct. It is codable so that it can deecode a JSON (or dictionary) object sent by the database
struct User: Codable{
    //All the fields in the database
    var name:String //Name of user
    var username:String //Username of user
    var password:String //Password of user
    var url:String //Photo url for user
    var isAlive:Bool //Is Alive Flag
    var numberKills: Int //Number of kills for user
    var lattitude:String //most recent Lattitude of User
    var longitude:String //Most recent longitude of user
    var gameId:String //GameID of the game the user is in
    var id:String? //Unique identifer for the user (this is the document.id and is not recieved from the database)
    var winNotification = false //This is a flag to determine whether the person has recieved the winNotification. This is not recieved from the database
    var loseNotification = false //This is a flag to determine whether the person has recieved the losNotification
    
    //This dictionary will be the structure of what the database sends us
    var dictionary:[String:Any]{
        return[
            "name":name,
            "username":username,
            "password":password,
            "url":url,
            "isAlive":isAlive,
            "numberKills": numberKills,
            "lattitude":lattitude,
            "longitude":longitude,
            "game":gameId
            ]
    }

    
}

//This extension allows us to inialize a User using DocumentSerializable
extension User:DocumentSerializable{
    init?(dictionary:[String:Any]){
        guard let name = dictionary["name"] as? String,
        let username = dictionary["username"] as? String,
        let password = dictionary["password"] as? String,
        let url = dictionary["url"] as? String,
        let isAlive = dictionary["isAlive"] as? Bool,
        let numberKills = dictionary["numberKills"] as? Int,
        let gameId = dictionary["game"] as? String,
        let lattitude = dictionary["lattitude"] as? String,
            let longitude = dictionary["longitude"] as? String else {return nil}
        self.init(name: name, username: username, password: password, url: url, isAlive: isAlive, numberKills: numberKills, lattitude: lattitude, longitude: longitude,gameId:gameId)
    }
}

//Extension that allows to confirm to users are the same (based on name and username)
extension User: Equatable {
  static func == (lhs: User, rhs: User) -> Bool {
    return (lhs.name == rhs.name &&
        lhs.username == rhs.username)
  }
}
