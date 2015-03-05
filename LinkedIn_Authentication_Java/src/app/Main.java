//  LinkedIn Authentication Java
//
//  Created by SwiftBlog on 1/1/15.
//  Copyright (c) 2015 SwiftBlog. All rights reserved.
//
//  This code is intended to be used as a guideline for authentication.
//  This code is not a fully functional authentication framework to be used in production.
 
package app;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.params.*;
import org.apache.http.impl.client.DefaultHttpClient;

import javafx.application.Application;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.event.EventHandler;
import javafx.scene.Scene;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;
import javafx.stage.Stage;
import javafx.concurrent.Worker.State;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.*;
import java.net.*;

import com.sun.webkit.network.*;
import javafx.scene.control.*;

//java webview oauth
public class Main extends Application {
    public static void main(String[] args) {
        launch(args);
    }

    HttpClient _client = new DefaultHttpClient();

    // Step 1:  Define the authentication parameters
    public static final String CALLBACK_URL = "";
    public static final String KEY = "";
    public static final String SEC = "";
    public static final String RAND_STATE = "gfdgfgdfydy";

    public static final String CODE_URL1 = "https://www.linkedin.com/uas/oauth2/authorization?response_type=code" +
            "&client_id=" + KEY +
            "&state=" + RAND_STATE +
            "&redirect_uri=" + CALLBACK_URL;

    public static String _auth_url2 = "https://www.linkedin.com/uas/oauth2/accessToken?grant_type=authorization_code";

    public static String API_ROOT = "https://www.linkedin.com/v1/";

    Button _but1 = new Button();
    WebView _browser = new WebView();
    URI _uri;
    // RFC 6265
    com.sun.webkit.network.CookieManager _broCookies = new com.sun.webkit.network.CookieManager();

    Map<String, List<String>> _headers;

    //native
    public void start(Stage primaryStage) {
        _but1.setText("Button");
        _but1.setOnMouseClicked(new EventHandler<MouseEvent>() {
            public void handle(MouseEvent arg0) {
                System.out.println("yo");
            }
        });

        //layout
        VBox vBox = new VBox();
        vBox.getChildren().addAll(_browser, _but1);
        //stage
        StackPane root = new StackPane();
        root.getChildren().add(vBox);
        primaryStage.setScene(new Scene(root, 500, 620));
        primaryStage.show();

        showOriginLoginAndGetCode1(CODE_URL1);
    }

    // Step 2: Request an Authorization Code
    //http://sites.google.com/site/oauthgoog/oauth-practices/mobile-apps-for-complex-login-systems/samplecode
    public void showOriginLoginAndGetCode1(String site) {
        CookieHandler.setDefault(_broCookies);
        _uri = URI.create(site);
        _headers = new HashMap<String, List<String>>();
        final WebEngine webEng = _browser.getEngine();
        webEng.getLoadWorker().stateProperty().addListener(
                new ChangeListener<State>() {
                    public void changed(ObservableValue ov, State oldState, State newState) {
                        //System.out.println(newState);
                        if (newState == State.SUCCEEDED) {
                            System.out.println("loaded");

                            Map<String, List<String>> cookies = _broCookies.get(_uri, _headers);
                            //System.out.println(cookies);
                            //System.out.println(_uri);
                            String qrs = webEng.getLocation();
                            try {
                                restAccessToken2(qrs, "code");
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    }
                });

        webEng.load(site);
    }

    // Step 3: Exchange Authorization Code for a Request Token
    public void restAccessToken2(String qrs, String key) throws Exception {
        if (!qrs.contains(key))
            return;
        //System.err.println(qrs);
        int start = qrs.indexOf(key);
        qrs = qrs.substring(start);
        int end = qrs.indexOf('&');
        qrs = qrs.substring(0, end);
        if (qrs.length() < 6)
            return;

        _browser.setVisible(false);

        _auth_url2 += "&" + qrs; //code from step 1
        _auth_url2 += "&redirect_uri=" + CALLBACK_URL;
        _auth_url2 += "&client_id=" + KEY;
        _auth_url2 += "&client_secret=" + SEC;

        System.out.println(_auth_url2);
        HttpPost rest = new HttpPost(_auth_url2);
        rest.getParams().setParameter(ClientPNames.COOKIE_POLICY, org.apache.http.client.params.CookiePolicy.NETSCAPE);

        HttpResponse response = _client.execute(rest);
        BufferedReader rd = new BufferedReader(new InputStreamReader(response.getEntity().getContent()));
        String line;
        String ret = "";
        while ((line = rd.readLine()) != null) {
            System.out.println(line);
            ret = line;
        }
        rd.close();
        parseBearer(ret);
    }

    public void parseBearer(String s) throws Exception {
        final String find = "access_token\":\"";
        int start = s.indexOf(find);
        s = s.substring(start+find.length());
         int end = s.indexOf('"');
        s = s.substring(0, end);
        System.err.println(s);
        makeApiCall(s);
    }

    // Step 4: Make authenticated requests with the token
    public void makeApiCall(String bear) throws Exception {
        String call = API_ROOT+"people/~" +
                "?oauth2_access_token="+bear;
        System.out.println(call);
        HttpGet rest = new HttpGet(call);

        HttpResponse response = _client.execute(rest);
        BufferedReader rd = new BufferedReader(new InputStreamReader(response.getEntity().getContent()));
        String line;
        String ret = "";
        while ((line = rd.readLine()) != null) {
            System.out.println(line);
            ret = line;
        }
        rd.close();
    }


}