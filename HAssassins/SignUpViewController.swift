//
//  SignUpViewController.swift
//  HAssassins
//
//  Created by Ben Altschuler on 11/26/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CoreLocation
import Firebase
import FirebaseDatabase
import FirebaseStorage

//This function allows us to later compress our images before uploading them to the database so that we don't run out of storage
//code taken from: https://stackoverflow.com/questions/29726643/how-to-compress-of-reduce-the-size-of-an-image-before-uploading-to-parse-as-pffi/29726675
extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    var ref:DatabaseReference?
    var db:Firestore! //establishing the database
    var locationManager: CLLocationManager?
    var imageURL = "" //the URL of the user's profile picture will be passed to a different view controller
    var userArray = [User]() //an array of all the users playing that will be filled in from the database
    
    //links to all the information on the storyboard
    @IBOutlet weak var confirm: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet var imageView: UIImageView!
    
    let context = CIContext()
    var original: UIImage! //image that is uploaded from the user's phone
    var user:User? //the user that is being created
    var imageFinal: Data? //the final compressed image that will be sent to the database
    
    var long:CLLocationDegrees = 0.0 //Setting temp longitude to be used when creating a user
    var lat:CLLocationDegrees = 0.0 //Setting temp lattitude to be used when creating a user.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore() //connect the database to firebase
        
        locationManager = CLLocationManager() //Iniliaze the location maneger
        locationManager?.delegate = self //Set the delegatee of the location maneger to this viewController
        locationManager?.requestAlwaysAuthorization() //Ask the phone to be able to always get location
        
        ref = Database.database().reference() //Reference of the Databasee
        loadDataFirebase() //call the function that grabs the information about the users from the database
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
    }
    
    //Function that grabs the information about the users from the database
    func loadDataFirebase(){
        //Get all the documents int he users collection
        db.collection("users").getDocuments(){
            //querySnapot is the data the database returns and error is an error if connection to the database failed
            querySnapshot, error in
            if let error = error{
                print(error.localizedDescription)
            }else{
                //Set userArray to eequal nothing
                self.userArray = []
                //Loop through the documents in the snapshot (each doc will be a users datat)
                for doc in querySnapshot!.documents{
                    //Inialize a new user
                    var tempUser = User(dictionary: doc.data())
                    //Set users id to the document's uinique id
                    tempUser!.id = doc.documentID
                    self.userArray.append(tempUser!)
                }
            }
        }
    }
    
    
    //What happens when the choose photo button is pressed
    @IBAction func choosePhoto(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary //pick image from the phone's photo library
            present(picker,animated: true, completion: nil) //show the photo library so they can pick a photo
        }
    }
    
    //Picking the image from the photo library
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image //display the image they picked
            original = image //save the image that the user picked
        }
        //Compress the image so it is smaller before storing it in the database
        if let imageData = original.jpeg(.lowest) {
            imageFinal = imageData
        }
    }
    
    //This function shows the loading spinning circle while all the data is loading
    //Code From:  https://stackoverflow.com/questions/27033466/how-to-display-activity-indicator-in-center-of-uialertcontroller
    func displaySignUpPendingAlert() -> UIAlertController{
        let pending = UIAlertController(title: "Creating New User", message: nil, preferredStyle: .alert)
        
        let indicator = UIActivityIndicatorView()
        pending.view.addSubview(indicator)
        
        let views = ["pending" : pending.view, "indicator" : indicator]
        
        indicator.isUserInteractionEnabled = false
        indicator.startAnimating()
        
        self.present(pending, animated: true, completion: nil)
        return pending
    }
    
    //What happens when the sign up button is clicked:
    @IBAction func signupTapped(sender : UIButton) {
        //Save the information entered into the text boxes:
        let usernameText:NSString = username.text! as NSString
        let passwordText:NSString = password.text! as NSString
        let confirmPassword:NSString = confirm.text! as NSString
        let nameText:NSString = name.text! as NSString
        var sameUsername = false
        
        //checking to see if this username already exists (we don't want two users to have the same username)
        for user in userArray {
            if user.username == usernameText as String{
                sameUsername = true
            }
        }
        
        //If any of the text boxes are blank then present an alert telling the user
        if (original == nil || usernameText == "" || passwordText == "" || confirmPassword == "" || nameText == "") {
            //Declare the alert:
            let alert = UIAlertController(title: "Did you forget something?", message: "Please fill out all fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true) //displaying the alert:
            
        }
            //If the password doesn't match what they typed in for confirm password
        else if (passwordText != confirmPassword) {
            //Declare the alert:
            let alert = UIAlertController(title: "Did you make a mistake?", message: "Passwords do not match", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            //Display the alert:
            self.present(alert, animated: true)
        }
            //If two this username already exists then present an alert so the user enters a different username
        else if (sameUsername == true){
            let alert2 = UIAlertController(title: "Sorry this username already exists", message: "Please try a different username", preferredStyle: .alert)
            alert2.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert2, animated: true)
        }
            //If everything is correct then create the new user
        else {
            let newUserAlert = displaySignUpPendingAlert()
            //Create the new user:
            let newUser = User(name: nameText as String, username: usernameText as String, password: confirmPassword as String, url: "", isAlive: true, numberKills: 0, lattitude: "", longitude: "", gameId: "harvardCollege", id: "")
            //Add the new user to the user array
            userArray.append(newUser)
            //Add the user created into the database:
            createUser(name: nameText as String, username: usernameText as String, password: confirmPassword as String){
                //Move to the profile page:
                newUserAlert.dismiss(animated: true, completion: nil)
                self.performSegue(withIdentifier: "SignUpGood", sender: self)
            }
        }
    }
    
    //Function that adds a user to the database:
    func createUser(name:String, username:String, password:String, completion: @escaping() -> Void){
        let imageName = NSUUID().uuidString //finds a random number to later have as the image name
        let storageRef = Storage.storage().reference().child("\(imageName).png")
        //Store the photo in the database
        if let uploadData = UIImage(data: imageFinal!)!.pngData(){
            storageRef.putData(uploadData, metadata: nil, completion:
                { (metadata, error) in
                    if error != nil{
                        return
                    }
                    //Save the URL of the image to the user's information in the database
                    storageRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            print("Failed to download url:", error!)
                            return
                        } else {
                            self.imageURL = url!.absoluteString
                            //creatte a unique id that will be used for the document
                            let id = UUID()
                            //if the location is available, get the location. This
                            if let location = self.locationManager?.location{
                                self.long = location.coordinate.latitude
                                self.lat = location.coordinate.longitude
                            }
                            //Create a new document in the users coleciton. The id of that document is the string of the id created above. To create the new user in the database
                            self.db.collection("users").document(id.uuidString).setData([
                                "name": name, "username": username, "password": password, "longitude": String(describing: self.long), "lattitude": String(describing: self.lat), "isAlive": true, "numberKills": 0, "url": self.imageURL, "game": "harvardCollege"]) { (error:Error?) in
                                    if let error = error{
                                        print("\(error.localizedDescription)")
                                        
                                    }else{
                                        print("Success Creating User")
                                    }
                            }
                            //Function that gets the user just created from the database
                            self.getUser(id:id.uuidString){ (tempUser) in
                                //sets the user of this view Controller to the user returned from the function
                                self.user = tempUser
                                //Sets the uinique id of the user
                                self.user?.id = id.uuidString
                                completion()
                            }
                        }
                    })
            })
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
    
    //Function that gets a speific user from the database
    func getUser(id:String, completionHandler: @escaping ((User?) -> Void)) {
        var tempUser:User?
        //gets the document from the users collection with the id
        self.db.collection("users").document(id).getDocument(){
            //querySnapot is the data the database returns and error is an error if connection to the database failed
            querysnapshot, error in
            //If there is an error, print the error and return the funciton with nothing
            if let error = error{
                print(error.localizedDescription)
                completionHandler(nil)
            }else{
                //Set the user equal to the temp user
                tempUser = User(dictionary: querysnapshot!.data()!)!
                completionHandler(tempUser!)
            }
        }
    }
    
    //Sends the information about the user to the next pages on the storyboard
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Send the information to the tab bar
        if let tabBar = segue.destination as? UITabBarController{
            //All the pages connected to the tabBar will also receive the information:
            if let nav0View = tabBar.viewControllers?[0] as? UINavigationController{
                if let profileView = nav0View.viewControllers[0] as? ProfileViewController{
                    profileView.user = user
                }
            }
            if let nav1View = tabBar.viewControllers?[1] as? UINavigationController{
                if let aliveView = nav1View.viewControllers[0] as? AliveTableViewController{
                    aliveView.user = user
                }
            }
            if let nav2View = tabBar.viewControllers?[2] as? UINavigationController{
                if let leaderboardView = nav2View.viewControllers[0] as? LeaderboardTableViewController{
                    leaderboardView.user = user
                }
            }
            if let nav3View = tabBar.viewControllers?[3] as? UINavigationController{
                if let gameView = nav3View.viewControllers[0] as? GamesTableViewController{
                    gameView.user = user
                }
            }
        }
    }
}
