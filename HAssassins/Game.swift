//
//  Game.swift
//  HAssassins
//
//  Created by Ben Altschuler on 12/8/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import Foundation
import FirebaseFirestore
import UIKit

//Creating a decleration of the DocumentSerializableG protocol
protocol DocumentSerializableG {
    init?(dictionary:[String:Any])
}

//Struct for the Game. It is codable so that jsons or dictionarys can be used to inialize a Game.
struct Game: Codable{
    //All the fields in the database
    var name:String
    var code:String
    var id:String?
    
    //dictionary that is returned from the database
    var dictionary:[String:Any]{
        return[
            "name":name,
            "code":code
        ]
    }
}

//This is an extension for Game that allows us to use the DocuementSerializbleG protocal creeated above
extension Game:DocumentSerializableG {
    init?(dictionary:[String:Any]){
        guard let name = dictionary["name"] as? String,
            let code = dictionary["code"] as? String else {return nil}
        self.init(name: name, code: code)
    }
}
