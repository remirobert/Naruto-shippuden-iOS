//
//  TabBarViewController.swift
//  naruto-download
//
//  Created by Remi Robert on 01/12/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {
    var episodesController = EpisodeControllerViewController()
    var downloadController = DownloadViewController()
    
    func addDownload(notification: NSNotification) {
        let dataNotification: Dictionary<String,String!> = notification.userInfo as Dictionary<String,String!>
        
        let title = dataNotification["title"]
        let subtitle = dataNotification["subtitle"]
        let url = dataNotification["url"]
        
        var modelDownload = DownloadModel()
        modelDownload.title = title!//.extend(map(title!.generate(), {$0 == " " ? "-" : $0} ))
        modelDownload.subtitle = subtitle!
        modelDownload.url = url!
        
        //self.downloadController.addDownload(modelDownload)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addDownload:",
            name: "addDownload", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
