//
//  DeviceTableViewCell.swift
//  Light Control
//

import UIKit

class DeviceTableViewCell: UITableViewCell {

    
    // use the new Device class
    var deviceItem: Device = Device()
    
    
    let title: UILabel = {
    
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.text = "Title"
        
        return label
    
    }()
    
    
    lazy var button: UISwitch = {
    
        let sw = UISwitch()
    
        sw.translatesAutoresizingMaskIntoConstraints = false
        
        sw.isOn = false
        
        sw.addTarget(self, action: #selector(handleChangeState), for: .valueChanged)
        
        return sw
        
    }()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupCell()
        
    }
    
    
    func handleChangeState(_ sender: AnyObject){
        
        let switchButton = sender as! UISwitch
        
        let newState = switchButton.isOn
        
        deviceItem.state = newState
        
        deviceItem.updateState()
        
    }
    
    func setupCell(){
        
        self.addSubview(title)
        self.addSubview(button)
                
        title.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        title.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 18).isActive = true
        title.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // switch button auto layout
        
        button.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        button.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -18).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    

}
