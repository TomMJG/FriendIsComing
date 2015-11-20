//
//  AppDelegate.swift
//  Chat
//
//  Created by 马家固 on 15/9/16.
//  Copyright (c) 2015年 马家固. All rights reserved.
//

import UIKit
import CoreData

//这是后台的操作
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RCIMUserInfoDataSource {
    
    var window: UIWindow?
    
    //获取会话列表上每个好友的名字
    func getUserInfoWithUserId(userId: String!, completion: ((RCUserInfo!) -> Void)!) {
        let userInfo = RCUserInfo()
        userInfo.userId = userId
        
        let query = AVQuery(className: "AppUser")
        query.whereKey("mail", equalTo: userInfo.userId)
        
        if (userInfo.name == "user<"+userId+">") {
            
            query.getFirstObjectInBackgroundWithBlock({ (object:AVObject!, error:NSError!) -> Void in
                if object != nil {
                    let queryData = object["localData"] as! NSDictionary
                    
                    userInfo.name = queryData["name"] as! String
                    userInfo.portraitUri = queryData["portraitUri"] as! String
                    
                    return completion(userInfo)
                }
            })
        }
        else {
            return completion(nil)
        }
    }
    
    
    
    //载入完启动界面后的行为
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        //初始化appKey
        RCIM.sharedRCIM().initWithAppKey("x4vkb1qpvcdzk")
        
        //设置用户信息提供者为自己AppDelegate
        RCIM.sharedRCIM().userInfoDataSource = self
        
        //获得LeanCloud授权
        AVOSCloud.setApplicationId("27oo1VbBTKtRMj5Ma6U8eurD", clientKey: "UXDyLHubfTD7vAPTFBvllpLw")
        // Override point for customization after application launch.
        
        //设置通知
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert , UIUserNotificationType.Badge , UIUserNotificationType.Sound], categories: nil)
        
        application.registerUserNotificationSettings(settings)
        
        return true
    }
    
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let token = deviceToken.description.stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "")
        RCIMClient.sharedRCIMClient().setDeviceToken(token)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        application.applicationIconBadgeNumber++
        RCIMClient.sharedRCIMClient().recordRemoteNotificationEvent(userInfo)
        
        //震动
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1007)
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        RCIMClient.sharedRCIMClient().recordLocalNotificationEvent(notification)
        
        application.applicationIconBadgeNumber++
        
        if notification.alertBody == "100米内有您的好友哦" {
            let test = SIAlertView(title: "通知", andMessage: "附近有好友")
            test.addButtonWithTitle("确定", type: SIAlertViewButtonType.Default, handler: { (alert:SIAlertView!) -> Void in
                friendNotification = 0
                application.applicationIconBadgeNumber = 0
            })
            test.transitionStyle = SIAlertViewTransitionStyle.Bounce
            test.show()
        }
        
        //震动
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1007)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        let unreadMsgCount = RCIMClient.sharedRCIMClient().getUnreadCount([RCConversationType.ConversationType_PRIVATE.rawValue,RCConversationType.ConversationType_SYSTEM.rawValue,RCConversationType.ConversationType_PUSHSERVICE.rawValue])
        
        application.applicationIconBadgeNumber = Int(unreadMsgCount)
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let unreadMsgCount = RCIMClient.sharedRCIMClient().getUnreadCount([RCConversationType.ConversationType_PRIVATE.rawValue,RCConversationType.ConversationType_SYSTEM.rawValue,RCConversationType.ConversationType_PUSHSERVICE.rawValue])
        
        application.applicationIconBadgeNumber = Int(unreadMsgCount)
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        friendNotification = 0
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        
        RCIMClient.sharedRCIMClient().disconnect()
        
        //关闭程序时，删除用户在数据库中的定位数据
        let query = AVQuery(className: "UserLocation")
        query.whereKey("mail", equalTo: deleteName)
        query.findObjectsInBackgroundWithBlock({ (anyObjects:[AnyObject]!, error:NSError!) -> Void in
            let objects = anyObjects as! [NSDictionary]
            if objects != [] {
                let queryObjectId = anyObjects[0]["objectId"] as! String
                let locationDelete = AVObject(withoutDataWithClassName: "UserLocation", objectId:queryObjectId)
                locationDelete.delete()
            }
        })
    }
    
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "student.HitList" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("FriendIsComing", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("HitList.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
}

