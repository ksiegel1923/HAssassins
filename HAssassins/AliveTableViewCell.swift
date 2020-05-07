//
//  AliveTableViewCell.swift
//  HAssassins
//
//  Created by Ben Altschuler on 12/3/19.
//  Copyright © 2019 Ben Altschuler. All rights reserved.
//

import UIKit

class AliveTableViewCell: UITableViewCell {
    
    
    //Outlets for the view
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    var indicator = UIActivityIndicatorView() //Indicator Instance
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator() //Setup the activity Indicator
    }
    //Funciton to have the activity Indicator appear
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = UIActivityIndicatorView.Style.gray
        indicator.center = self.profileImage.center
        self.profileImage.addSubview(indicator)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
