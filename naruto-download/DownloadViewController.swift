//
//  DownloadViewController.swift
//  naruto-download
//
//  Created by Remi Robert on 01/12/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import UIKit
import Realm
import MediaPlayer

class DownloadModel: RLMObject {
    dynamic var title = ""
    dynamic var subtitle = ""
    dynamic var url = ""
    dynamic var isDownloaded = false
}

class DownloadViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var downloads = Array<DownloadModel>()
    var downloadTableView: UITableView!
    var cellDownload = Array<UITableViewCell>()
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        
        let pathDirectory: NSURL? = NSFileManager.defaultManager()
        .URLsForDirectory(.DocumentDirectory,
        inDomains: .UserDomainMask).first as? NSURL
        
        if self.downloads[indexPath.row].isDownloaded == true {
            var path = pathDirectory?.URLByAppendingPathComponent("download/\(self.downloads[indexPath.row].title).mp4")
            println("set video = \(path!.path)")
            
            var videoPlayer = MPMoviePlayerViewController(contentURL: path)
            videoPlayer.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 144)
            videoPlayer.moviePlayer.play()
            self.presentMoviePlayerViewControllerAnimated(videoPlayer)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            
            if self.downloads[indexPath.row].isDownloaded == false {
                RRDownloadFile.cancelDownload(downloadTask: (self.cellDownload[indexPath.row] as
                    DownloadTableViewCell).currentDownloadTask)
            }
            
            if let let model: DownloadModel! = DownloadModel.objectsWhere("title == '\((self.downloads[indexPath.row]).title)'").firstObject() as? DownloadModel {
                let realm = RLMRealm.defaultRealm()
                
                realm.beginWriteTransaction()
                realm.deleteObject(model)
                realm.commitWriteTransaction()
            }
            
            self.downloads.removeAtIndex(indexPath.row)
            self.cellDownload.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        } else {
            NSLog("Unhandled editing style! %d");
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloads.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.cellDownload[indexPath.row]
    }
    
    func addNewDownload(model: DownloadModel) {
        let realm = RLMRealm.defaultRealm()
        
        if DownloadModel.objectsWhere("title == '\(model.title)'").count == 0 {
            let realm = RLMRealm.defaultRealm()
            
            realm.beginWriteTransaction()
            realm.addObject(model)
            realm.commitWriteTransaction()
            self.downloads.append(model)
            
            var newCell = DownloadTableViewCell()
            newCell.initContent(model)
            self.cellDownload.append(newCell)
            
            self.downloadTableView.reloadData()
        }
    }
    
    func findNewDownload() {
        let episodesController = EpisodeControllerViewController()
        self.presentViewController(episodesController, animated: true, completion: nil)
    }
    
    func initNavigationBar() {
        var navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 64))
        navigationBar.translucent = false
        navigationBar.backgroundColor = UIColor.whiteColor()
        navigationBar.tintColor = UIColor(red: 236 / 255.0, green: 240 / 255.0, blue: 241 / 255.0, alpha: 1)
        navigationBar.barTintColor = UIColor.whiteColor()//UIColor(red: 50 / 255.0, green: 50 / 255.0, blue: 50 / 255.0, alpha: 1)
        
        var titleController = UIBarButtonItem(title: "+", style: UIBarButtonItemStyle.Plain, target: self, action: "findNewDownload")
        var navigationItem = UINavigationItem(title: "Downloads")
        
        navigationItem.rightBarButtonItem = titleController
        navigationBar.pushNavigationItem(navigationItem, animated: true)
        self.view.addSubview(navigationBar)
    }
    
    func initDownloadTableView() {
        self.downloadTableView = UITableView(frame: CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64))
        self.downloadTableView.backgroundColor = UIColor.clearColor()
        self.downloadTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
//        self.downloadTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.downloadTableView.delegate = self
        self.downloadTableView.dataSource = self
        self.view.addSubview(self.downloadTableView)
    }
    
    func loadData() {
        self.cellDownload.removeAll(keepCapacity: false)
        self.downloads.removeAll(keepCapacity: false)
        
        let realm = RLMRealm.defaultRealm()
        for currentDownload in DownloadModel.allObjects() {
            if ((currentDownload as DownloadModel).isDownloaded == false) {
                var newCell = DownloadTableViewCell()
                newCell.initContent((currentDownload as DownloadModel))
                self.cellDownload.append(newCell)
            }
            else {
                var newCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: nil)
                newCell.backgroundColor = UIColor.clearColor()
                newCell.textLabel.text = (currentDownload as DownloadModel).title
                newCell.textLabel.textColor = UIColor.grayColor()
                newCell.detailTextLabel?.text = (currentDownload as DownloadModel).subtitle
                self.cellDownload.append(newCell)
            }
            
            self.downloads.append(currentDownload as DownloadModel)
        }
        self.downloadTableView.reloadData()
    }
  
    func addDownload(notification: NSNotification) {
        let dataNotification: Dictionary<String,String!> = notification.userInfo as Dictionary<String,String!>
        
        let title = dataNotification["title"]
        let subtitle = dataNotification["subtitle"]
        let url = dataNotification["url"]
        
        var modelDownload = DownloadModel()
        modelDownload.title = title!
        modelDownload.subtitle = subtitle!
        modelDownload.url = url!
        
        self.addNewDownload(modelDownload)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "download"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadData",
            name: "loadData", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addDownload:",
            name: "addDownload", object: nil)
        
        self.initDownloadTableView()
        self.initNavigationBar()
        
        self.loadData()
        
        self.view.backgroundColor = UIColor(red: 236 / 255.0, green: 240 / 255.0, blue: 241 / 255.0, alpha: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
