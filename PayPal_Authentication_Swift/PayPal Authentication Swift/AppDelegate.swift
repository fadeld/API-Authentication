//
//  AppDelegate.swift
//  PayPal Authentication Swift
//
//  Created by SwiftBlog on 3/3/15.
//  Copyright (c) 2015 SwiftBlog. All rights reserved.
//


import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {

    // Programmatically create the UI
    let window = NSWindow(contentRect: NSMakeRect(0, 0, NSScreen.mainScreen()!.frame.width/2, NSScreen.mainScreen()!.frame.height*3/4), styleMask: NSTitledWindowMask|NSResizableWindowMask|NSMiniaturizableWindowMask|NSClosableWindowMask, backing: NSBackingStoreType.Buffered, defer: true)
    let view = NSView(frame: NSMakeRect(0, 0, NSScreen.mainScreen()!.frame.width/2, NSScreen.mainScreen()!.frame.height*0.75))
    let webView = WKWebView(frame: NSMakeRect(0, 0, NSScreen.mainScreen()!.frame.width/2, NSScreen.mainScreen()!.frame.height*0.75))

    // Step 1:  Define the authentication parameters
    let grantType = "client_credentials"
    var redirectUrl = ""
    let apiKey = ""
    let secretKey = ""
    let responseType = "code"
    let randomState = "jdhfgrueFSH16dh88352jsGSD"
    let scope = "openid%20email"
    let contentType = "application/x-www-form-urlencoded"

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        // Create the preference settings and configuration for the web view
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences

        webView.navigationDelegate = self

        // Step 2: Request an Authorization Code
        var authUrl = NSURL(string: "https://www.sandbox.paypal.com/webapps/auth/protocol/openidconnect/v1/authorize?response_type=\(responseType)" +
                "&client_id=\(apiKey)" +
                "&scope=\(scope)" +
                "&redirect_uri=\(redirectUrl)")

        var request = NSMutableURLRequest(URL: authUrl!)
        webView.loadRequest(request)

        window.title = "Sample Swift App"
        window.center()
        window.contentView.addSubview(view)
        window.makeKeyAndOrderFront(window)
        view.addSubview(webView)

    }

    // Step 3: Exchange Authorization Code for a Request Token
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        println("Navigation response: \(navigationResponse.response)")

        var url: NSURL = navigationResponse.response.URL!

        decisionHandler(.Allow)

        let urlComps = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        if let items = urlComps!.queryItems as? [NSURLQueryItem] {
            var dict = NSMutableDictionary()

            for item in items {
                dict.setValue(item.value(), forKey: item.name)
            }

            // If the user grants access, print to the console the authorization code and status that were included in the redirect URL
            if (dict["code"] != nil /** && dict["status"] == randomState */) {
                var authCode: NSString = dict["code"] as NSString
                println(authCode)
                println(dict["state"])

                //var params = ["\(apiKey)": "\(secretKey)", "grant_type": "\(grantType)", "code": "\(authCode)", "redirect_uri"] as Dictionary<String, String>
                var err1: NSError?

                var tokenUrl = NSURL(string: "https://api.sandbox.paypal.com/v1/identity/openidconnect/tokenservice?grant_type=\(grantType)&code=\(authCode)&redirect_uri=\(redirectUrl)&\(apiKey)=\(secretKey)")

                var session = NSURLSession.sharedSession()
                var requestToken = NSMutableURLRequest(URL: tokenUrl!)

                requestToken.HTTPMethod = "POST"
                //requestToken.addValue("application/json", forHTTPHeaderField: "Accept")
                //requestToken.addValue("\(contentType)", forHTTPHeaderField: "content-type")
                //requestToken.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err1)


                var task = session.dataTaskWithRequest(requestToken, completionHandler: {
                    data, response, error -> Void in
                    println("Response: \(response)")
                    var err: NSError?
                    var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
                    if (err != nil) {
                        println(err!.localizedDescription)
                        var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
                        println("Error: Could not parse JSON: '\(strData)")
                    } else {
                        println("Result containing token: \(jsonResult)")
                        var token: NSString = jsonResult["access_token"] as NSString
                        var bearer: NSString = jsonResult["token_type"] as NSString
                        println("\(bearer): \(token)")

                        // Step 4: Make authenticated requests with the token
                        var apiUrl = NSURL(string: "https://api.sandbox.paypal.com/v1/payments/payment")
                        var requestAuthenticated = NSMutableURLRequest(URL: apiUrl!)

                        requestAuthenticated.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
                        requestAuthenticated.addValue("\(bearer) \(token)", forHTTPHeaderField: "Authorization")
                        requestAuthenticated.addValue("application/json", forHTTPHeaderField: "Content-Type")

                        var task = session.dataTaskWithRequest(requestAuthenticated, completionHandler: {
                            data, response, error -> Void in
                            println("Response: \(response)")
                            var err2: NSError?
                            var json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err2) as NSDictionary
                            if (err2 != nil) {
                                println(err2!.localizedDescription)
                                var strData2 = NSString(data: data, encoding: NSUTF8StringEncoding)
                                println("Error: Could not parse JSON: '\(strData2)")
                            } else {
                                println(json)
                            }
                        })

                        task.resume()

                    }
                })

                task.resume()

                // If the user declines access, print to the concole the error and error description that were included in the redirect URL
            } else if (dict["error"] != nil) {
                println(dict["error"])
                println(dict["error_description"])

            } else {
                println("This is not OAUth2 redirect URL.")
            }
        } else {
            println("Hoa!")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }




}