//
//  DownloadTableViewCell.swift
//  naruto-download
//
//  Created by Remi Robert on 01/12/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import UIKit
import Realm

class DownloadTableViewCell: UITableViewCell {

    var titleDownload: UILabel!
    var subtitle: UITextView!
    var currentDownloadTask: NSURLSessionDownloadTask!
    var progressView: RRProgressDownload!

    func initContent(model: DownloadModel) {
        
        self.subtitle = UITextView(frame: CGRectMake(80, 40, UIScreen.mainScreen().bounds.size.width - 90, 60))
        self.subtitle.backgroundColor = UIColor.clearColor()
        self.subtitle.textColor = UIColor.blackColor()
        self.subtitle.text = model.subtitle
        
        self.titleDownload = UILabel(frame: CGRectMake(80, 10, self.frame.size.width - 90, 20))
        self.titleDownload.text = model.title
        self.titleDownload.textColor = UIColor.grayColor()
        self.titleDownload.font = UIFont(name: self.titleDownload.font.fontName, size: 16)
        
        self.progressView = RRProgressDownload(frame: CGRectMake(10, 10, 70, 70))
        self.currentDownloadTask = RRDownloadFile.download("\(model.title).mp4", downloadSource:
            NSURL(string: model.url)!, pathDestination: NSURL(string: "download")!,
            progressBlockCompletion: { (bytesWritten, bytesExpectedToWrite) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let pourcentValue = bytesWritten * 100 / bytesExpectedToWrite
                //println(bytesWritten)
                self.progressView.percent = Float(pourcentValue)
                self.progressView.setNeedsDisplay()
            })
                self.progressView.setNeedsDisplay()
        }) { (error, fileDestination) -> () in
            if (error == nil) {
                println("file destination : \(fileDestination)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let let model: DownloadModel! = DownloadModel
                        .objectsWhere("title == '\(model.title)'")
                        .firstObject() as? DownloadModel {
                            
                        let realm = RLMRealm.defaultRealm()
                        
                        realm.beginWriteTransaction()
                        
                        model.isDownloaded = true
                        realm.commitWriteTransaction()
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName("loadData", object: nil)
                })
                
                println("download finished")
            }
            else {
                NSLog("ERROR DOWNLOAD = \(error)")
            }
        }
        
        self.backgroundColor = UIColor.clearColor()
        self.contentView.addSubview(self.titleDownload)
        self.contentView.addSubview(self.subtitle)
        self.contentView.addSubview(self.progressView)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
