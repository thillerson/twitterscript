﻿/*
This is a fork of http://code.google.com/p/twitterscript/ for
use in Hello! Flex 3.

The reason I am forking the library is that I need to control
it so that the book does not depend on something that could
change. The original project is obviously free to take all the
code that it wants from this fork: the license is obviously
unchanged (Apache 2).
*/
package twitter.api {
  
  import flash.events.*;
  import flash.net.*;
  import flash.xml.*;
  
  import mx.utils.Base64Encoder;
  
  import twitter.api.data.*;
  import twitter.api.events.TwitterEvent;
  
  /**
   * This is a wrapper class around the Twitter public API.
   * The pattern for all of the calls is to:
   * 1.) Use XML for the format
   * 2.) Internally handle the event from the REST call
   * 3.) Parse the XML into a strongly typed object
   * 4.) Publish a TwitterEvent whose payload is the type object
   * from above
   */ 
  public class Twitter extends EventDispatcher
  {
    // constants used for loaders
    private static const HTTP:String = 'http';
    private static const HTTPS:String = 'https';
    private static const PROTOCOL_TOKEN:String = "$protocol"
    
    private static const FRIENDS:String = "friends";
    private static const FRIENDS_TIMELINE:String =
      "friendsTimeline";
    private static const PUBLIC_TIMELINE:String = "timeline";
    private static const USER_TIMELINE:String = "userTimeline";
    private static const SET_STATUS:String = "setStatus";
    private static const FOLLOW_USER:String = "follow";
    private static const SHOW_STATUS:String = "showStatus";
    private static const REPLIES:String = "replies";
    private static const DESTROY:String = "destroy";
    private static const FOLLOWERS:String = "followers";
    private static const FEATURED:String = "featured";
    private static const VERIFY_CREDENTIALS:String = "verifyCredentials";
    
    private static const LOAD_FRIENDS_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/friends/$userId.xml";
    private static const LOAD_FRIENDS_TIMELINE_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/friends_timeline/$userId.xml";
    private static const PUBLIC_TIMELINE_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/public_timeline.xml"
    private static const LOAD_USER_TIMELINE_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/user_timeline/$userId.xml"
    private static const FOLLOW_USER_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/friendships/create/$userId.xml";
    private static const SET_STATUS_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/update.xml";
    private static const SHOW_STATUS_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/show/$id.xml";
    private static const REPLIES_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/replies.xml";
    private static const DESTROY_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/destroy/$id.xml";
    private static const FOLLOWERS_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/followers.xml";
    private static const FEATURED_USERS_URL:String = 
      PROTOCOL_TOKEN + "://twitter.com/statuses/featured.xml";
    private static const LITE:String = "?lite=true";
	private static const VERIFY_CREDENTIALS_URL:String = 
		"https://twitter.com/account/verify_credentials.xml";    
    
    public var useHTTPS:Boolean;

    // internal variables
    private var _loaders:Array;
    private var authorizationHeader:URLRequestHeader;

    function Twitter() 
    {
      _loaders = [];
      addLoader(FRIENDS, friendsHandler);
      addLoader(FRIENDS_TIMELINE, friendsTimelineHandler);
      addLoader(PUBLIC_TIMELINE, publicTimelineHandler);
      addLoader(USER_TIMELINE, userTimelineHandler);
      addLoader(SET_STATUS, setStatusHandler);
      addLoader(FOLLOW_USER, friendCreatedHandler);
      addLoader(SHOW_STATUS, showStatusHandler);
      addLoader(REPLIES, repliesHandler);
      addLoader(DESTROY, destroyHandler);
      addLoader(FOLLOWERS, followersHandler);
      addLoader(FEATURED, featuredHandler);
      addLoader(VERIFY_CREDENTIALS, verifyCredentialsHandler);
    }
  
    // Public API
    
    /**
     * Sets the username and password for this instance, setting the 
     * flag to use https to true. Note that this will not 
     * work at all in Flash player 9.0.115, and will only work in later
     * versions if the remote server has the 
     * <code>allow-http-request-headers-from</code> tag set permissively 
     * in its crossdomain policy file. For more information see:
     * http://kb.adobe.com/selfservice/viewContent.do?externalId=kb403184.
     * Unfortunately Twitter has it set to (as of Sept 2008):
     * <allow-http-request-headers-from domain="*.twitter.com" headers="*" secure="true"/>
     * which only lets in the twitter badges originating from twitter.com. Since
     * that's the case, authentication will only work for AIR.
     * 
     * If you use this for Flash in the browser, it will fail over
     * to the browser's basic auth without an issue.
     * 
     * @param username
     * @param password
     * 
     */    
    public function setAuthenticationCredentials(username:String, password:String):void {
		if (username != null && password != null){
	    	useHTTPS = true;
			var creds:String = username + ":" + password;
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encode(creds);
			var encodedCredentials:String = encoder.toString();
			authorizationHeader = new URLRequestHeader("Authorization",
				"Basic " + encodedCredentials);
		}
    }
    
    /**
     * Loads a list of Twitter friends and (optionally) their
     * statuses. Authentication required for private users.
     */
    public function loadFriends(userId:String,
      lite:Boolean = true):void {
      var friendsLoader:URLLoader = getLoader(FRIENDS);
      var urlStr:String =
        LOAD_FRIENDS_URL.replace("$userId", userId).
        	replace(PROTOCOL_TOKEN, protocol);
      if (lite) {
        urlStr += LITE;
      }
      friendsLoader.load(getUrlRequest(urlStr));
    }

    /**
      * Loads the timeline of all friends on Twitter.
      * Authentication required for private users.
     */
    public function loadFriendsTimeline(userId:String):void {
      var friendsTimelineLoader:URLLoader = 
        getLoader(FRIENDS_TIMELINE);
      friendsTimelineLoader.load(getUrlRequest(
        LOAD_FRIENDS_TIMELINE_URL.replace("$userId",userId).
        	replace(PROTOCOL_TOKEN, protocol)
       ));
    }
    /**
    * Loads the timeline of all public users on Twitter.
    */
    public function loadPublicTimeline():void {
      var publicTimelineLoader:URLLoader =
        getLoader(PUBLIC_TIMELINE);
      publicTimelineLoader.load(getUrlRequest(
        PUBLIC_TIMELINE_URL.replace(PROTOCOL_TOKEN, protocol)));
    }
    
    /**
     * Loads the timeline of a specific user on Twitter.
     * Authentication required for private users.
     */
    public function loadUserTimeline(userId:String):void {
      var userTimelineLoader:URLLoader =
        getLoader(USER_TIMELINE);
      userTimelineLoader.load(getUrlRequest(
        LOAD_USER_TIMELINE_URL.replace("$userId", userId).
        	replace(PROTOCOL_TOKEN, protocol)
      ));
    }
    
    /**
     * Follows a user. Right now this uses the
     * /friendships/create/user.format
     */
    public function follow(userId:String):void
    {
      var req:URLRequest = getUrlRequest(
        FOLLOW_USER_URL.replace("$userId",userId).
        	replace(PROTOCOL_TOKEN, protocol)
      );
      req.method = "POST";
      getLoader(FOLLOW_USER).load(req);
    }

    /**
     * Sets user's Twitter status. Authentication required.
     */
    public function setStatus(statusString:String):void {
      if (statusString.length <= 140) {
        var request:URLRequest =
          getUrlRequest(SET_STATUS_URL.replace(
          	PROTOCOL_TOKEN, protocol));
        request.method = "POST"
        var variables:URLVariables = new URLVariables();
        variables.status = statusString;
        request.data = variables;
        try {
          getLoader(SET_STATUS).load(request);
        } catch (error:Error) {
          trace("Unable to set status");
        }
      } else {
        trace("STATUS NOT SET: status limited to 140 chars");
      }
    }
    
    /**
     * Returns a single status, specified by the id parameter
     * below. The status's author will be returned inline.
     */
    public function showStatus(id:String):void {
      var showStatusLoader:URLLoader = getLoader(SHOW_STATUS);
      showStatusLoader.load(getUrlRequest(
        SHOW_STATUS_URL.replace("$id",id).
        	replace(PROTOCOL_TOKEN, protocol)
      ));
    }
    
    /**
     * Loads the most recent replies for the current
     * authenticated user
     */
    public function loadReplies():void {
      var repliesLoader:URLLoader = getLoader(REPLIES);
      repliesLoader.load(getUrlRequest(REPLIES_URL.
      	replace(PROTOCOL_TOKEN, protocol)
      ));
    }
    
    public function loadFollowers(lite:Boolean=true):void {
      var followersLoader:URLLoader = getLoader(FOLLOWERS);
      var urlStr:String = FOLLOWERS_URL.replace(
      	PROTOCOL_TOKEN, protocol);
      if (lite) {
        urlStr += LITE;
      }
      followersLoader.load(getUrlRequest(urlStr));
    }
    
    public function loadFeatured():void {
      var featuredLoader:URLLoader = getLoader(FEATURED);
      featuredLoader.load(getUrlRequest(FEATURED_USERS_URL.
      	replace(PROTOCOL_TOKEN, protocol)
      ));
    }
    
    public function verifyCredentials(username:String, password:String):void {
    	setAuthenticationCredentials(username, password);
    	var verifyCredentialsLoader:URLLoader = getLoader(VERIFY_CREDENTIALS);
	 	verifyCredentialsLoader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onVerifyCredentialsHttpResponseStatus);
	 	verifyCredentialsLoader.load( getUrlRequest(VERIFY_CREDENTIALS_URL.
	 		replace(PROTOCOL_TOKEN, protocol)
	 	));
    }
 
    
    //private handlers for the events coming back from twitter
	private function onVerifyCredentialsHttpResponseStatus(event:HTTPStatusEvent):void {
		var success:Boolean = false;
		if (event.status==200) {
			success = true;
		}
		// else:  401 error usually
		
		var result:TwitterEvent = new TwitterEvent (TwitterEvent.ON_VERIFY_CREDENTIALS);
		result.data = {success:success};
		dispatchEvent (result);
	}
	
	private function verifyCredentialsHandler(e:Event):void {
		
	}
		   
    private function friendsHandler(e:Event):void {
      var xml:XML = new XML(getLoader(FRIENDS).data);
      var userArray:Array = new Array();
      for each (var tempXML:XML in xml.children()) {
        var twitterUser:TwitterUser = new TwitterUser(tempXML);
        userArray.push(twitterUser);
      }
      var r:TwitterEvent = new TwitterEvent(
        TwitterEvent.ON_FRIENDS_RESULT);
      r.data = userArray;
      dispatchEvent(r);
    }
      
    private function friendsTimelineHandler(e:Event):void {
      var xml:XML = new XML(getLoader(FRIENDS_TIMELINE).data);
      var statusArray:Array = new Array();
      for each (var tempXML:XML in xml.children()) {
        var twitterStatus:TwitterStatus =
          new TwitterStatus(tempXML);
        statusArray.push(twitterStatus );
      }
      var r:TwitterEvent = new TwitterEvent(
        TwitterEvent.ON_FRIENDS_TIMELINE_RESULT);
      r.data = statusArray;
      dispatchEvent(r);
    }
    
    private function publicTimelineHandler(e:Event):void {
      var xml:XML = new XML(getLoader(PUBLIC_TIMELINE).data);
      var statusArray:Array = new Array();
      for each (var tempXML:XML in xml.children()) {
        var twitterStatus:TwitterStatus =
          new TwitterStatus(tempXML);
        statusArray.push(twitterStatus );
      }
      var r:TwitterEvent = new TwitterEvent(
        TwitterEvent.ON_PUBLIC_TIMELINE_RESULT);
      r.data = statusArray;
      dispatchEvent(r);
    }
    
    private function userTimelineHandler(e:Event):void {
      var xml:XML = new XML(getLoader(USER_TIMELINE).data);
      var statusArray:Array = new Array();
      for each (var tempXML:XML in xml.children()) {
        var twitterStatus:TwitterStatus =
          new TwitterStatus(tempXML)
        statusArray.push(twitterStatus );
      }
      var r:TwitterEvent =
        new TwitterEvent(TwitterEvent.ON_USER_TIMELINE_RESULT);
      r.data = statusArray;
      dispatchEvent(r);
    }
    
    
    private function setStatusHandler(e:Event):void {
      var r:TwitterEvent = new TwitterEvent(
        TwitterEvent.ON_SET_STATUS);
      r.data = "success";
      dispatchEvent(r);
    }
    
    private function friendCreatedHandler(e:Event):void{
      trace("Friend created " + getLoader(FOLLOW_USER).data);
    }
    
    private function showStatusHandler(e:Event):void
    {
      var xml:XML = new XML(getLoader(SHOW_STATUS).data);
      var twitterStatus:TwitterStatus = new TwitterStatus(xml);
      var twitterEvent:TwitterEvent =
        new TwitterEvent(TwitterEvent.ON_SHOW_STATUS);
      twitterEvent.data = twitterStatus;
      dispatchEvent(twitterEvent);
    }
    
    private function repliesHandler(e:Event):void {
      var xml:XML = new XML(getLoader(REPLIES).data);
      var statusArray:Array = [];
      for each(var reply:XML in xml.children()) {
        statusArray.push(new TwitterStatus(reply));
      }
      var twitterEvent:TwitterEvent =
        new TwitterEvent(TwitterEvent.ON_REPLIES);
      twitterEvent.data = statusArray;
      dispatchEvent(twitterEvent);
    }
    
    private function destroyHandler(e:Event):void {
      var r:TwitterEvent = new TwitterEvent(
        TwitterEvent.ON_DESTROY);
      r.data = "success";
      dispatchEvent(r);
    }
    
    private function errorHandler(errorEvent:IOErrorEvent):void {
      trace(errorEvent.text);
    }
    
    private function followersHandler(e:Event):void {
      var xml:XML = new XML(getLoader(FOLLOWERS).data);
      var userArray:Array = new Array();
      for each (var tempXML:XML in xml.children()) {
        var twitterUser:TwitterUser = new TwitterUser(tempXML);
        userArray.push(twitterUser);
      }
      var r:TwitterEvent =
        new TwitterEvent(TwitterEvent.ON_FOLLOWERS);
      r.data = userArray;
      dispatchEvent(r);
    }
    
    private function featuredHandler(e:Event):void {
      var xml:XML = new XML(getLoader(FEATURED).data);
      var userArray:Array = new Array();
      for each (var tempXML:XML in xml.children()) {
        var twitterUser:TwitterUser = new TwitterUser(tempXML);
        userArray.push(twitterUser);
      }
      var r:TwitterEvent =
        new TwitterEvent(TwitterEvent.ON_FEATURED);
      r.data = userArray;
      dispatchEvent(r);
    }
    
    // private helper methods
    
    private function addLoader(name:String,
      completeHandler:Function):void {
      var loader:URLLoader = new URLLoader();
      loader.addEventListener(Event.COMPLETE, completeHandler);
      loader.addEventListener(
        IOErrorEvent.IO_ERROR, errorHandler);
      loader.addEventListener(
        SecurityErrorEvent.SECURITY_ERROR, errorHandler);
      _loaders[name] = loader;
    }
    
    private function getUrlRequest(url:String=null):URLRequest {
    	var ur:URLRequest = new URLRequest(url);
    	if (authorizationHeader) {
    		ur.authenticate = false;
    		ur.requestHeaders = [authorizationHeader];
    	}
    	return ur;
    }
    
    private function getLoader(name:String):URLLoader {
      return _loaders[name] as URLLoader;
    }
    
    private function get protocol():String {
    	if (useHTTPS) {
    		return HTTPS;
    	} else {
    		return HTTP;
    	}
    }
  }
}