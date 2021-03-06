//
//  ViewController.swift
//  LinkedIn AUthentication Swift iOS
//
//  Created by SwiftBlog on 3/3/15.
//  Copyright (c) 2015 SwiftBlog. All rights reserved.
//


import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView?

    // Step 1:  Define the authentication parameters
    let grantType = "authorization_code"
    var redirectUrl = ""
    let apiKey = ""
    let secretKey = ""
    let responseType = "code"
    let randomState = "jdhfgrueFSH16dh88352jsGSD"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create the preference settings and configuration for the web view
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences

        webView = WKWebView(frame: view.bounds, configuration: configuration)

        // Step 2: Request an Authorization Code
        if let myWebView = webView{

            var authUrl = NSURL(string: "https://www.linkedin.com/uas/oauth2/authorization?response_type=\(responseType)" +
                    "&client_id=\(apiKey)" +
                    "&state=\(randomState)" +
                    "&redirect_uri=\(redirectUrl)")

            var request = NSMutableURLRequest(URL: authUrl!)
            myWebView.loadRequest(request)
            myWebView.navigationDelegate = self
            view.addSubview(myWebView)


        }
    }

    // Step 3: Exchange Authorization Code for a Request Token
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        println("Navigation response: \(navigationResponse.response)")
        var url: NSURL = navigationResponse.response.URL!
        NSLog("Redirect URL: ", url)

        decisionHandler(.Allow)

        let urlComps = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        let items = urlComps?.queryItems as [NSURLQueryItem]
        var dict = NSMutableDictionary()

        for item in items{
            dict.setValue(item.value, forKey: item.name)
        }

        // If the user grants access, print to the console the authorization code and status that were included in the redirect URL
        if (dict["code"] != nil) { /** && dict["status"] == randomState */
            var authCode: NSString = dict["code"] as NSString
            println(authCode)
            println(dict["status"])

            var tokenUrl = NSURL(string: "https://www.linkedin.com/uas/oauth2/accessToken?grant_type=\(grantType)&code=\(authCode)&redirect_uri=\(redirectUrl)&client_id=\(apiKey)&client_secret=\(secretKey)")

            var session = NSURLSession.sharedSession()
            var requestToken = NSMutableURLRequest(URL: tokenUrl!)

            requestToken.HTTPMethod = "POST"
            var task = session.dataTaskWithRequest(requestToken, completionHandler: {
                data, response, error -> Void in
                println("Response: \(response)")
                var err: NSError?
                var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
                if(err != nil){
                    println(err!.localizedDescription)
                    var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error: Could not parse JSON: '\(strData)")
                } else {
                    println("Result containing token: \(jsonResult)")
                    var token: NSString = jsonResult["access_token"] as NSString
                    println("\(token)")

                    // Step 4: Make authenticated requests with the token
                    var apiUrl = NSURL(string: "https://api.linkedin.com/v1/people/~")
                    var requestAuthenticated = NSMutableURLRequest(URL: apiUrl!)

                    requestAuthenticated.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
                    requestAuthenticated.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                    var task = session.dataTaskWithRequest(requestAuthenticated, completionHandler: {
                        data, response, error -> Void in
                        println("Response: \(response)")
                        var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
                        println("Data: \(strData)")
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

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }




}