//
//  Download.swift
//  narutoDownload
//
//  Created by Remi Robert on 28/11/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import UIKit

class RRDownloadFile: NSObject, NSURLSessionDelegate {
    var downloads = Array<InfoDownload>()
    var session: NSURLSession!
    let identifierDownload = "com.RRDownloadFile"
    
    let pathDirectory: NSURL? = NSFileManager.defaultManager()
        .URLsForDirectory(.DocumentDirectory,
        inDomains: .UserDomainMask).first as? NSURL
    
    class InfoDownload: NSObject {
        var fileTitle: String!
        var downloadSource: NSURL!
        var downloadTask: NSURLSessionDownloadTask!
        var taskResumeData: NSData!
        var isDownloading: Bool!
        var downloadComplete: Bool!
        var pathDestination: NSURL!
        var progressBlockCompletion: ((bytesWritten: Int64, bytesExpectedToWrite: Int64)->())!
        var responseBlockCompletion: ((error: NSError!, fileDestination: NSURL!) -> ())!
        
        init(downloadTitle fileTitle: String, downloadSource source: NSURL) {
            super.init()
            
            self.fileTitle = fileTitle
            self.downloadSource = source
            self.pathDestination = nil
            self.isDownloading = false;
            self.downloadComplete = false;
        }
        
    }
    
    private class Singleton {
        class var sharedInstance: RRDownloadFile {
            struct Static {
                static var instance: RRDownloadFile?
                static var token: dispatch_once_t = 0
            }
            
            dispatch_once(&Static.token, { () -> Void in
                Static.instance = RRDownloadFile()
                Static.instance?.initSessionDownload()
            })
            return Static.instance!
        }
    }
    
    private func initSessionDownload() {
        let sessionConfiguration: NSURLSessionConfiguration = NSURLSessionConfiguration
            .backgroundSessionConfigurationWithIdentifier(self.identifierDownload)
        sessionConfiguration.allowsCellularAccess = true
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 10
        self.session = NSURLSession(configuration: sessionConfiguration,
            delegate: self, delegateQueue: nil)
    }
    
    private func saveDataTaskDownload(currentDownload: InfoDownload, location: NSURL) -> NSError? {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let pathData = currentDownload.pathDestination
        var error: NSError? = NSError()
        
        if fileManager.fileExistsAtPath(pathData!.path!) == true {
            if fileManager.replaceItemAtURL(pathData!, withItemAtURL: location,
                backupItemName: nil, options: NSFileManagerItemReplacementOptions.UsingNewMetadataOnly,
                resultingItemURL: nil, error: &error) == false {
                    println(error)
            }
        }
        else {
            if fileManager.moveItemAtURL(location, toURL: pathData!, error: &error) == false {
                return error
            }
        }
        return nil
    }
    
    class func setDestinationDownload(currentDownload: InfoDownload, urlDestination: NSURL?) -> NSError? {
        let fileManager = NSFileManager.defaultManager()

        if urlDestination == nil {
            currentDownload.pathDestination = fileManager.URLsForDirectory(.DocumentDirectory,
                inDomains: .UserDomainMask)[0] as? NSURL
            currentDownload.pathDestination = currentDownload.pathDestination?
                .URLByAppendingPathComponent("\(urlDestination?.path!)/\(currentDownload.fileTitle)")
        }
        else {
            var error: NSError? = NSError()
            var path = fileManager.URLsForDirectory(.DocumentDirectory,
                inDomains: .UserDomainMask)[0] as? NSURL
            path = path?.URLByAppendingPathComponent(urlDestination!.path!)

            if fileManager.createDirectoryAtURL(path!,
                withIntermediateDirectories: true, attributes: nil, error: &error) == true {
                currentDownload.pathDestination = path?.URLByAppendingPathComponent(currentDownload.fileTitle)
            }
            else {
                return error
            }
        }
        return nil
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { (dataTask: [AnyObject]!, uploadTask: [AnyObject]!,
            downloadTask: [AnyObject]!) -> Void in
            
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if (error != nil) {
            if let selectedDownloadTask = RRDownloadFile.getTaskByIdentifier(task.taskIdentifier) {
                selectedDownloadTask.downloadTask.cancel()
                selectedDownloadTask.responseBlockCompletion(error: error, fileDestination: nil)
                var index = find(Singleton.sharedInstance.downloads, selectedDownloadTask)
                Singleton.sharedInstance.downloads.removeAtIndex(index!)
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let selectedDownloadTask = RRDownloadFile.getTaskByIdentifier(downloadTask.taskIdentifier) {
            selectedDownloadTask.downloadTask.cancel()
            self.saveDataTaskDownload(selectedDownloadTask, location: location)
            selectedDownloadTask.responseBlockCompletion(error: nil, fileDestination: selectedDownloadTask.pathDestination!)
            var index = find(Singleton.sharedInstance.downloads, selectedDownloadTask)
            Singleton.sharedInstance.downloads.removeAtIndex(index!)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64) {
        if let selectedDownloadTask = RRDownloadFile.getTaskByIdentifier(downloadTask.taskIdentifier) {
            selectedDownloadTask.progressBlockCompletion?(bytesWritten: totalBytesWritten,
                bytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    private class func getTaskByIdentifier(identifier: Int) -> InfoDownload! {
        var selectedDownload: InfoDownload! = nil
        for currentDownload in Singleton.sharedInstance.downloads {
            if (currentDownload as InfoDownload).downloadTask.taskIdentifier == identifier {
                selectedDownload = currentDownload
                return selectedDownload
            }
        }
        return nil
    }
    
    private class func downloadFile(fileName: String, downloadSource sourceUrl: NSURL, destination: NSURL?,
        progressBlockCompletion progressBlock:((bytesWritten: Int64, bytesExpectedToWrite: Int64)->())?,
        responseBlockCompletion responseBlock:((error: NSError!, fileDestination: NSURL!) -> ())) -> NSURLSessionDownloadTask {
           
            var newDownload = InfoDownload(downloadTitle: fileName, downloadSource: sourceUrl)
            newDownload.progressBlockCompletion = progressBlock
            newDownload.responseBlockCompletion = responseBlock
            
            if let errorDestination = self.setDestinationDownload(newDownload, urlDestination: destination) {
                responseBlock(error: errorDestination, fileDestination: nil)
                return newDownload.downloadTask
            }
            
            newDownload.downloadTask = Singleton.sharedInstance.session
                .downloadTaskWithURL(newDownload.downloadSource, completionHandler: nil)
            newDownload.downloadTask.resume()
            newDownload.isDownloading = true
            Singleton.sharedInstance.downloads.append(newDownload);
            return newDownload.downloadTask

    }
    
    /**
    Creates a new download request URL string.
    
    :param: file name of the download.
    :param: URLString The URL string.
    */
    class func download(fileName: String, downloadSource sourceUrl: NSURL,
        progressBlockCompletion progressBlock:((bytesWritten: Int64, bytesExpectedToWrite: Int64)->())?,
        responseBlockCompletion responseBlock:((error: NSError!, fileDestination: NSURL!) -> ())) -> NSURLSessionDownloadTask {
            
        return self.downloadFile(fileName, downloadSource: sourceUrl, destination: nil,
            progressBlockCompletion: progressBlock, responseBlockCompletion: responseBlock)
    }

    /**
    Creates a new download request URL string.
    
    :param: file name of the download.
    :param: URLString The URL string.
    :param: destination path download
    */
    class func download(fileName: String, downloadSource sourceUrl: NSURL, pathDestination destination: NSURL,
        progressBlockCompletion progressBlock:((bytesWritten: Int64, bytesExpectedToWrite: Int64)->())?,
        responseBlockCompletion responseBlock:((error: NSError!, fileDestination: NSURL!) -> ())) -> NSURLSessionDownloadTask {
            
            return self.downloadFile(fileName, downloadSource: sourceUrl, destination: destination,
                progressBlockCompletion: progressBlock, responseBlockCompletion: responseBlock)
    }
    
    /**
    Pause a download.
    
    :param: the download task.
    */
    class func pauseDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = self.getTaskByIdentifier(task.taskIdentifier) {
            //selectedDownload.downloadTask.suspend()
            selectedDownload.isDownloading = false
            task.cancelByProducingResumeData { (data: NSData!) -> Void in
                selectedDownload.taskResumeData = data
                selectedDownload.isDownloading = false
            }
        }
    }

    /**
    Resume a suspend download.
    
    :param: the download task.
    */
    class func resumeDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = self.getTaskByIdentifier(task.taskIdentifier) {
            if selectedDownload.isDownloading == false {
                selectedDownload.downloadTask = Singleton.sharedInstance.session
                    .downloadTaskWithResumeData(selectedDownload.taskResumeData)
                selectedDownload.isDownloading = true
                selectedDownload.downloadTask.resume()
            }
        }
    }
    
    /**
    Cancel a download.
    
    :param: the download task.
    */
    class func cancelDownload(downloadTask task: NSURLSessionDownloadTask) {
        if let selectedDownload = self.getTaskByIdentifier(task.taskIdentifier) {
            selectedDownload.downloadTask.cancel()
        }
    }
}
