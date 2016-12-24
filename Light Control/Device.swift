//
//  Device.swift
//  Light Control
//

import UIKit
import FirebaseDatabase


class Device: NSObject{
    
    var chipId: String = ""
    var title: String = ""
    var state: Bool = false
   
    override func setValue(_ value: Any?, forKey key: String) {
        
        if(key == "state"){
            
            var defaultState: Bool = true;
            
            if let sValue: Bool = value as! Bool?{
                
                if sValue == false{
                    
                   defaultState = false
                }
            }
            
            self.setValue(defaultState, forKey: "state")
        }else{
            
            self.setValue(value, forKey: key)
        }
    }
    
    func updateState(){
    
        let ref = FIRDatabase.database().reference()
        
        // devices/<chipId>/state = true or false
        ref.child("devices/\(self.chipId)/state").setValue(state)
    
    }
    
}
