# API Authentication Samples
Here are examples of API authentication in Swift (OS X and iOS) and Java, for LinkedIn, Facebook, meetup.com, Yammer, Amazon, Paypal, FourSquare, Salesforce, AOL, Battle.net, Twitch and Uber. The UI in Swift is created programmatically, without Interface Builder.

The purpose of the project is to show a simple working implementation of API authentication using web server authentication flow of OAuth 2.0 (https://tools.ietf.org/html/draft-ietf-oauth-v2-02#section-3.5.2). The examples do not handle exceptions, to keep the code clear and readable. 

IDE details and some FAQ are on the wiki page.



### Authentication Flow and Steps


     +----------+         Client Identifier       +---------------+
     |         -+----(A)-- & Redirect URI ------->|               |
     | End-user |                                 | Authorization |
     |    at    |<---(B)-- User authenticates --->|     Server    |
     | Browser  |                                 |               |
     |         -+----(C)-- Verification Code ----<|               |
     +-|----|---+                                 +---------------+
       |    |                                         ^      v
      (A)  (C)                                        |      |
       |    |                                         |      |
       ^    v                                         |      |
     +---------+                                      |      |
     |         |>---(D)-- Client Credentials, --------'      |
     |   Web   |           Verification Code,                |
     |  Client |            & Redirect URI                   |
     |         |                                             |
     |         |<---(E)------- Access Token -----------------'
     +---------+        (w/ Optional Refresh Token)


                                 Figure 4

   The web server flow illustrated in Figure 4 includes the following
   steps:

   (A)  The web client initiates the flow by redirecting the end-user's
        user-agent to the authorization endpoint with its client
        identifier and a redirect URI to which the authorization server
        will send the end-user back once authorization is received (or
        denied).

   (B)  The authorization server authenticates the end-user (via the
        user-agent) and establishes whether the end-user grants or
        denies the client's access request.

   (C)  Assuming the end-user granted access, the authorization server
        redirects the user-agent back to the client to the redirection
        URI provided earlier.  The authorization includes a verification
        code for the client to use to obtain an access token.

   (D)  The client requests an access token from the authorization
        server by including its client credentials (identifier and
        secret), as well as the verification code received in the
        previous step.

   (E)  The authorization server validates the client credentials and
        the verification code and responds back with the access token.

Once the access token is available, you can initiate authenticated API requests on behalf of the end user. 


### App vs. Applet (then and now)

![](https://github.com/h0n3yBadg3r/API-Authentication/blob/master/app-vs-applet.png)
