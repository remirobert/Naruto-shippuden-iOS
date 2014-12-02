//
//  EpisodeControllerViewController.swift
//  naruto-download
//
//  Created by Remi Robert on 01/12/14.
//  Cop<yright (c) 2014 remirobert. All rights reserved.
//

import UIKit

class EpisodeControllerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var episodeTableView: UITableView!
    var episodes = Array<UITableViewCell>()
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let currentSelectedEpisode = self.episodes[indexPath.row].textLabel.text?.componentsSeparatedByString(" ").last {
            let stringUrl = "http://www1.narutospot.net/watch/naruto-shippuden-\(currentSelectedEpisode)"
            
            let contentEpisodeRequest = Crackers(url: stringUrl)
            
            contentEpisodeRequest.sendRequest(.GET, blockCompletion: { (data, response, error) -> () in
                if (data == nil) {
                    return
                }
                var json: String = NSString(data: data!, encoding: NSUTF8StringEncoding) as String
                
                var idVideo: String!
                var urlEpisode = json.componentsSeparatedByString("data-video-id=\"")
                if urlEpisode.count > 1 {
                    idVideo = urlEpisode[1].componentsSeparatedByString("\">").first
                }
                
                if (idVideo != nil) {
                    var requestInfoDownload = Crackers(url: "http://www1.narutospot.net/video/play/\(idVideo!)")
                    
                    requestInfoDownload.sendRequest(.GET, blockCompletion: { (data, response, error) -> () in
                        if (data == nil) {
                            return
                        }
                        var json: String = NSString(data: data!, encoding: NSUTF8StringEncoding) as String
                        var urlVideo: String! = nil
                        var data = json.componentsSeparatedByString("\"360p\"},{file: \"")
                        
                        if data.count > 1 {
                            urlVideo = data[1].componentsSeparatedByString("\"").first
                        }
                        else {
                            data = json.componentsSeparatedByString("{file: \"http:")
                            if (data.count > 1) {
                                urlVideo = json.componentsSeparatedByString("{file: \"http:").last?.componentsSeparatedByString("\"").first
                                urlVideo = "http:\(urlVideo)"
                            }
                        }
                        if (urlVideo != nil) {
                            
                            let currentCell = self.episodes[indexPath.row]
                            
                            var userInfo = Dictionary<String, String!>()
                            userInfo["title"] = currentCell.textLabel.text
                            userInfo["subtitle"] = currentCell.detailTextLabel?.text
                            userInfo["url"] = (urlVideo == nil) ? "" : urlVideo
                            userInfo["img"] = json.componentsSeparatedByString("image: '").last?.componentsSeparatedByString("'").first
                            NSNotificationCenter.defaultCenter().postNotificationName("addDownload", object: nil, userInfo: userInfo)
                        }
                    })
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.episodes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.episodes[indexPath.row]
    }
    
    func getListEpisodes() {
        let request = Crackers(url: "http://www.naruspot.net/category/naruto-shippuden-subbed/")
        
        request.sendRequest(.GET, blockCompletion: { (data, response, error) -> () in
            if (data == nil) {
                return
            }
            
            var json: String = NSString(data: data!, encoding: NSUTF8StringEncoding) as String
            var list: [String]? = json.componentsSeparatedByString("<ul class=\"categorylist\">")[1].componentsSeparatedByString("</ul>").first?.componentsSeparatedByString("<li>")
            
            for (var index = 0; index < list?.count; index++) {
                var currentCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cellCategorie")
                
                println(list![index])
                var title = list![index].componentsSeparatedByString(">")
                if title.count > 1 {
                    title = title[1].componentsSeparatedByString(" <")
                    currentCell.textLabel.textColor = UIColor.grayColor()
                    currentCell.textLabel.text = title[0]
                }
                
                var subtitle = list![index].componentsSeparatedByString("<i>")
                if subtitle.count > 1 {
                    subtitle = subtitle[1].componentsSeparatedByString("</i>")
                    currentCell.detailTextLabel?.textColor = UIColor(red: 50 / 255.0, green: 50 / 255.0, blue: 50 / 255.0, alpha: 1)
                    currentCell.detailTextLabel?.text = subtitle[0]
                    self.episodes.append(currentCell)
                }
                currentCell.backgroundColor = UIColor.clearColor()
            }
            self.episodeTableView.reloadData()
        })
    }
    
    func closeEpisodeController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func initNavigationBar() {
        var navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 64))
        navigationBar.translucent = false
        navigationBar.backgroundColor = UIColor.whiteColor()
        navigationBar.tintColor = UIColor(red: 30 / 255.0, green: 30 / 255.0, blue: 30 / 255.0, alpha: 1)
        navigationBar.barTintColor = UIColor.whiteColor()
        
        var titleController = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: self, action: "closeEpisodeController")
        var navigationItem = UINavigationItem(title: "Episodes")
        
        navigationItem.rightBarButtonItem = titleController
        navigationBar.pushNavigationItem(navigationItem, animated: true)
        self.view.addSubview(navigationBar)
    }
    
    func initEpisodeTableView() {
        self.episodeTableView = UITableView(frame: CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64))
        self.episodeTableView.backgroundColor = UIColor.clearColor()
        
        self.episodeTableView.delegate = self
        self.episodeTableView.dataSource = self
        self.view.addSubview(self.episodeTableView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 236 / 255.0, green: 240 / 255.0, blue: 241 / 255.0, alpha: 1)
        self.initEpisodeTableView()
        self.initNavigationBar()
        self.getListEpisodes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
