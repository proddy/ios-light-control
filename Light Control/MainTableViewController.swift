//
//  MainTableViewController.swift
//  Light Control
//

import UIKit
import FirebaseDatabase
import Firebase
import GoogleSignIn


class MainTableViewController: UITableViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    var ref: FIRDatabaseReference!
    
    var items: [Device] = []
    
    let cellId: String = "cellId"
    
    // Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialise the firebase DB
        ref = FIRDatabase.database().reference()
        
        // google sign-in
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
        
        // main view
        self.title = "Light Control"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(DeviceTableViewCell.self, forCellReuseIdentifier: cellId)
        
        // add sign-out button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleLogout))
    }
    
    // sign out
    func handleLogout(){
    
        do {
            // sign out first from Firebase
            print("sign out FB")
            try FIRAuth.auth()?.signOut()
            
            print("sign out google")
            GIDSignIn.sharedInstance().signOut()
        
            // go back to login screen
            // MARK still doesn't work!
            print("back to start screen")
            let loginVC = LoginViewController()
            self.present(loginVC, animated: true, completion: nil)
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }

    
    }
    
    func fetchDevice(){
        
        ref.observe(.value, with: { (snapshot: FIRDataSnapshot) in
            
            print ("Preparing to read devices")
            
            // delete existing table
            self.items.removeAll()
            
            for chipItem: FIRDataSnapshot in snapshot.children.allObjects as! [FIRDataSnapshot]{
                
                let chipId: String = chipItem.key
            
                let titles: FIRDataSnapshot = chipItem.childSnapshot(forPath: "titles")
                
                
                for device in titles.children.allObjects as! [FIRDataSnapshot]{
                    
                    print("Got device: ", device)
                    
                    let value: NSDictionary = device.value as! NSDictionary
                    
                    let deviceTitle: String = value["title"] as! String
                    let deviceId: String = value["id"] as! String
                    
                    let deviceState: Bool = chipItem.childSnapshot(forPath: "states/\(deviceId)").value as! Bool
                    
                    let newDevice = Device()
                    
                    newDevice.title = deviceTitle
                    newDevice.chipId = chipId
                    newDevice.state = deviceState
                    newDevice.id = deviceId
                    
                    self.items.append(newDevice)
                }
                
            }
            
            // refresh table
            self.tableView.reloadData()
        
            
        }) { (err:Error) in
            print("got an error reading device data: ", err)
        }
        
    
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    // table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! DeviceTableViewCell

        let deviceItem: Device = items[indexPath.row]
        
        cell.deviceItem = deviceItem
        cell.title.text = deviceItem.title
        cell.button.isOn = deviceItem.state

        return cell
    }
    
    // GID Sign In Delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            print(error.localizedDescription)
            return
        }
        print("User signed into Google as", user.profile.email)
        
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!,
                                                          accessToken: (authentication?.accessToken)!)
        
        // sign in to Firebase auth
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            
            // check valid user in Firebase
            if let error = error {
                print("a firebase error occured ", error.localizedDescription)
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                // self.present
                return
            }
            else {
                print("User signed into Firebase")
                
                self.fetchDevice()
                
                self.ref.child("user_profiles").child(user!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let snapshot = snapshot.value as? NSDictionary
                    
                    // add valid user to firebase user db
                    if(snapshot == nil)
                    {
                        self.ref.child("user_profiles").child(user!.uid).child("name").setValue(user?.displayName)
                        self.ref.child("user_profiles").child(user!.uid).child("email").setValue(user?.email)
                    }
                })
            }

            
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
