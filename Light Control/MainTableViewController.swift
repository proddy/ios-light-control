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
    
    // read device info from FB
    func fetchDevice(){
        
        ref.observe(.value, with: { (snapshot: FIRDataSnapshot) in
            
            // delete existing table
            self.items.removeAll()
            
            // get devices tree
            let devices: FIRDataSnapshot = snapshot.childSnapshot(forPath: "devices")
            
            // build up device database
            for device in devices.children.allObjects as! [FIRDataSnapshot]{
                
                // chipId is name of parent node
                let chipId: String = device.key
                print("Got device with chipID: ", chipId)
                
                // now get child
                let child: FIRDataSnapshot = devices.childSnapshot(forPath: chipId)
                print("got this set of child data: ", child)
                let value: NSDictionary = child.value as! NSDictionary
                
                let newDevice = Device()
                
                newDevice.chipId = chipId
                newDevice.title = value["title"] as! String
                newDevice.state = value["state"] as! Bool
                
               self.items.append(newDevice)
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
                
                // load all the devices
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
