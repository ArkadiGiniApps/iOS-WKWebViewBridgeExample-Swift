//
//  ViewController.swift
//  WKWebViewBridgeExample
//
//  Created by Priya Rajagopal on 12/8/14.
//  Copyright (c) 2014 Lunaria Software LLC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    var webView : WKWebView! {
        didSet {
            webView.navigationDelegate = self
        }
    }
    var buttonClicked:Int = 0
    var colors:[String] = ["0xff00ff","#ff0000","#ffcc00","#ccff00","#ff0033","#ff0099","#cc0099","#0033ff","#0066ff","#ffff00","#0000ff","#0099cc"];
    
    var webConfig : WKWebViewConfiguration {
        
        // Create WKWebViewConfiguration instance
        let webCfg = WKWebViewConfiguration()
        
        // Setup WKUserContentController instance for injecting user script
        let userController = WKUserContentController()
        
        // Add a script message handler for receiving  "buttonClicked" event notifications posted from the JS document using window.webkit.messageHandlers.buttonClicked.postMessage script message
        userController.addScriptMessageHandler(self, name: "buttonClicked")
        
        // Get script that's to be injected into the document
        let js = buttonClickEventTriggeredScriptToAddToDocument()
        
        // Specify when and where and what user script needs to be injected into the web document
        let userScript =  WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
        
        // Add the user script to the WKUserContentController instance
        userController.addUserScript(userScript)
        
        // Configure the WKWebViewConfiguration instance with the WKUserContentController
        webCfg.userContentController = userController;
        
        return webCfg
    }
    
    // MARK: - View LifeCycle
    override func loadView() {
        super.loadView()
        
        // Create a WKWebView instance
        webView = WKWebView (frame: self.view.frame, configuration: webConfig)
        view.addSubview(webView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load the HTML document
        loadHtml()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let fileName:String =  String("\( NSProcessInfo.processInfo().globallyUniqueString)_TestFile.html")
        
        let tempHtmlPath:String =  (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(fileName)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(tempHtmlPath)
        } catch let error as NSError {
            print("Error: \(error)")
        }
        webView = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
// MARK: - Private methods
extension ViewController {
    
    // File Loading
    func loadHtml() {
        // NOTE: Due to a bug in webKit as of iOS 8.1.1 we CANNOT load a local resource when running on device. Once that is fixed, we can get rid of the temp copy
        let mainBundle:NSBundle = NSBundle(forClass: ViewController.self)
        
        let fileName:String =  String("\( NSProcessInfo.processInfo().globallyUniqueString)_TestFile.html")
        
        let tempHtmlPath:String? = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(fileName)
        
        if let htmlPath = mainBundle.pathForResource("TestFile", ofType: "html") {
            do {
                try NSFileManager.defaultManager().copyItemAtPath(htmlPath, toPath: tempHtmlPath!)
            } catch let error
                as NSError {
                    print("Error: \(error)")
            }
            if tempHtmlPath != nil {
                let requestUrl = NSURLRequest(URL: NSURL(fileURLWithPath: tempHtmlPath!))
                webView?.loadRequest(requestUrl)
            }
        }
        else {
            showAlertWithMessage("Could not load HTML File!")
        }
        
    }
    
    // Button Click Script to Add to Document
    func buttonClickEventTriggeredScriptToAddToDocument() ->String {
        // Script: When window is loaded, execute an anonymous function that adds a "click" event handler function to the "ClickMeButton" button element. The "click" event handler calls back into our native code via the window.webkit.messageHandlers.buttonClicked.postMessage call
        var script:String?
        
        if let filePath:String = NSBundle(forClass: ViewController.self).pathForResource("ClickMeEventRegister", ofType:"js") {
            
            script = try? String (contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
        }
        return script!;
        
    }
    
    // Update color of Button with specified Id
    func updateColorOfButtonWithId(buttonId:String) {
        let count:UInt32 = UInt32(colors.count)
        let index:Int = Int(arc4random_uniform(count))
        let color:String = colors [index]
        
        // Script that changes the color of tapped button
        let js2:String = String(format: "var button = document.getElementById('%@'); button.style.backgroundColor='%@';", buttonId,color)
        
        webView?.evaluateJavaScript(js2, completionHandler: { (AnyObject, NSError) -> Void in
            NSLog("%s", #function)
            
        })
    }
    
    // Helper
    func showAlertWithMessage(message:String) {
        let alertAction:UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            })
        }
        
        let alertView:UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addAction(alertAction)
        
        self.presentViewController(alertView, animated: true, completion: { () -> Void in
            
        })
    }
    
}
// MARK: - WKScriptMessageHandler
extension ViewController : WKScriptMessageHandler {
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        guard let messageBody = message.body as? NSDictionary, idOfTappedButton = messageBody["ButtonId"] as? String else { return }
        updateColorOfButtonWithId(idOfTappedButton)
    }
    
}
// MARK: - WKNavigationDelegate
extension ViewController : WKNavigationDelegate {
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        NSLog("%s", #function)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        NSLog("%s. With Error %@", #function,error)
        
        showAlertWithMessage("Failed to load file with error \(error.localizedDescription)!")
    }
    
}
