# Overview -> in Progress...

## Author

* **Maik Müller** *Applied Computer Science (M. Sc.)* - [LinkedIn](https://www.linkedin.com/in/maik-m-253357107), [Xing](https://www.xing.com/profile/Maik_Mueller215/cv)

#### Background

<p align="justify">I finished my studies in Applied Computer Science (LINK) (B.Sc and M.Sc.) at the HTW, University of Applied Science Berlin, in January 2020. During my studies, I worked on several projects that contained app prototypes for public health and professional work environments. All apps were written in Swift. The present project, TwitterDrop, is based on the demo Twitter client developed during the course: Stanford - Developing iOS 10 Apps with Swift, Lecture: <a href="https://www.youtube.com/watch?v=Sm3jupdLJBY">9. Table View</a>, <a href="https://www.youtube.com/watch?v=L02Ty79Xdvw">10. Core Data</a> and <a href="https://www.youtube.com/watch?v=D9kFvJix30M">11. Core Data Demo</a>. The recordings of the lectures are available for free on Youtube.</p>

## Table of Contents

* [1. About the App](#1-about-the-app)
  * [1.1. Goals](#11-goals)
  * [1.2. What's the App about?](#12-whats-the-app-about)
  * [1.3. Features](#13-features)
  * [1.4. Technical Information](#14-technical-information)
* [2. Concept and Implementation](#2-concept-and-implementation)
  * [2.1. System Design](#21-system-design)
    * [2.1.1. App Cache](#211-app-cache)
    * [2.1.2. Core Data](#212-core-data)
  * [2.2. Network Communication](#22-network-communication)
    * [2.2.1. Twitter Requests](#221-twitter-requests)
    * [2.2.2. Profile Images](#222-profile-images)
  * [2.3. JSON Parsing](#23-json-parsing)
* [3. UI](#3-ui)
  * [3.1. Tweets](#31-tweets)
  * [3.2. Spinning Indicators and Alerts](#32-spinning-indicators-and-alerts)

## 1. About the App

### 1.1. Goals

<p align="justify">TwitterDrop is a further project after graduation. Overall the goal in all my projects is to gain knowledge in Swift and general iOS development. In the opposite to my first project <a href="https://github.com/maikdrop/Titanic">Titanic</a>, this app focuses on the following topics:</p>

* Network Communication 
* JSON Parsing
* System Design

### 1.2. What's the App about?

<p align="justify">Users have to log in to their account in order to fetch data from Twitter. In the first view after login, the current tweets of the users timeline will be fetched automatically. The user credentials are saved in the Keychain. So, if the user launches the app again, a new login is not necessary. Of course, the user has the possibility to log out. In the timeline view the tweets can be refreshed via the “pull to refresh” gesture and they will be stored in a local database. Next time these tweets will be fetched automatically from the database before fetching new tweets from Twitter. The user can search for tweets from Twitter via the magnifying glass button in the navigation bar. By typing a word in the search bar at the top, the user can search for tweets, which contains the searched term. The found tweets will be inserted in a descending order. If the user scrolls to the end of the list, older tweets will be fetched from Twitter immediately. In order to search for the tweeters, the user taps on the button with the title “Tweeters” in the navigation bar. This leads to a further view where all tweeters are sorted alphabetically. Each cell shows the tweeter and the count of tweets containing the search term. If the user taps on a cell, a new view with a list of these tweets shows up.</p>

### 1.3. Features

The following features haven been implemented:

* log in and log out of a Twitter user
* fetching the timeline for this user
* search for tweets
* show tweeters of the searched tweets
* offline functionality

### 1.4. Technical Information

The following list contains the most important technical information about the app:

* Development Environment: Xcode
* Interface: Storyboard, Programmatically and XIB
* Life Cycle: UIKit App Delegate
* Language: Swift
* Deployment Info: iOS 14.6, iPhone & iPad
* 3pp Libraries/Projects: [MyTwitterDrop](https://github.com/maikdrop/MyTwitterDrop)
* Dependency Manager: [SwiftPackageManager](https://swift.org/package-manager/)

## 2. Concept and Implementation

### 2.1. System Design

<p align="justify">System design focusses on the data flow between Twitter server, application cache and the local database (see <a href="#211-app-cache">chapter 2.1.1.</a> and <a href="#212-core-data">chapter 2.1.2.</a> for more details).
 
New tweets are fetched from Twitter and will be inserted directly into the timeline. Profile images from tweeters will be downloaded from an external image server and stored in the app cache. Additionally, they will be stored in the database. The following graphic illustrates the data flow from external sources.</p>

<br/>
<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/TweetFetchExternalDataFlow.png" align="center" width="500">
     <p align="center">Graphic 1: Tweet Fetching from External Sources; Source: Own Illustration
  </p>
</figure>
<br/>

**Code Links:**
  * [TweetTimeline.swift](TwitterDrop/Scenes/TweetTimeline/TweetTimelineTableViewController.swift)
  * [OfflineTweetTimeline.swift](TwitterDrop/Scenes/TweetTimeline/OfflineTimelineTVC.swift)
  * [TweetSearch.swift](TwitterDrop/Scenes/TweetSearch/TweetSearchTableViewController.swift)
  * [OfflineTweetSearch.swift](TwitterDrop/Scenes/TweetSearch/OfflineTweetSearchTVC.swift)

#### 2.1.1. App Cache

<p align="justify">In order to realize a fluent scrolling experience, the profile images of the tweeters are stored in the application cache. Fetching the images from the internet, database or filesystem leads to juddering while the user is scrolling a list of tweets. A second benefit is that the profile images can be easily shared through the cache across the application. This leads to a less complex data source of the table view and less fetching actions from the database.</p>

**Code Links:**
  * [Cache.swift](TwitterDrop/Utility/Cache.swift)

#### 2.1.2. Core Data

<p align="justify">It makes sense to store the tweets and related data like tweeters and their profile image in the database instead of fetching same data over and over again from the internet. Furthermore, it enables an offline functionality and results in a higher data fetching efficiency.

As you can see in the next graphic, stored tweets and profile images can be fetched and used directly from the database. 

The big advantage of this approach is that the user saves on mobile data traffic and battery consumption. Additionally, you get a better performance because fetching data from a local database is much faster than fetching from an external source.</p>

<br/>
<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/TweetFetchDatabaseDataFlow.png" align="center" width="500">
     <p align="center">Graphic 2: Fetching Tweets from local Database; Source: Own Illustration
  </p>
</figure>
<br/>

<p align="justify">In order to display only stored tweeters, a <a href="https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller">NSFetchedResultsController</a> is used to manage the results of a Core Data fetch request. Graphic 3 illustrates the fetching and displaying of tweeters in alphabetical order whose tweets contain the search term "#Swift".</p>

<br/>
<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/TweetersAlphabetical.png" align="center" width="300">
     <p align="center">Graphic 3: Fetching Tweeters from local Database; Source: Own Illustration
  </p>
</figure>
<br/>

**Code Links:**
  * [OfflineTweetTimeline.swift](TwitterDrop/Scenes/TweetTimeline/OfflineTimelineTVC.swift)
  * [OfflineTweetSearch.swift](TwitterDrop/Scenes/TweetSearch/OfflineTweetSearchTVC.swift)
  * [CoreDataFetchedResults](TwitterDrop/Scenes/FetchedResults)
  * [CoreDataModel](TwitterDrop/Model/Core%20Data%20Model)

### 2.2. Network Communication

There are two tasks where network requests are used in the present project. 

* Twitter Requests
* Fetching profile images of Twitter users from a url

#### 2.2.1. Twitter Requests

<p align="justify">MyTwitterDrop is a small library to capsule the network requests with Twitter. Follow <a href="https://github.com/maikdrop/MyTwitterDrop">Link</a> for more details.</p>

#### 2.2.2. Profile Images

<p align="justify">The fetched Twitter user entity contains a url for the profile image. The download of the image is done asynchronously via <a href="https://developer.apple.com/documentation/foundation/urlsession">URLSession</a>. So, the UI is still responsive while the data is fetching. A closure calls back with the requested tweets and the UI will be updated on the main queue. In order to check if a stored profile image is still valid, URLSession is used to ping the url of the image by requesting only the http header. Twitter stated, if you receive a 403 or 404 response code, you should request the user again to get the latest profile image.</p>

**Code Links:**
  * [Network.swift](TwitterDrop/Utility/Network.swift)

### 2.3. JSON Parsing

<p align="justify">The requested Data from Twitter is JSON formatted. So, it can be directly parsed into the model object when implementing the Codable protocol from Apple. It’s not necessary to cast the data as a dictionary and iterate over it in order to create a tweet or a user object. Depending on the requested data it can be decoded directly with the <a href="https://developer.apple.com/documentation/foundation/jsondecoder">JSONDecoder</a> or must be serialized before with <a href="https://developer.apple.com/documentation/foundation/jsonserialization">JSONSerialization</a>. 

Because of the entities that a tweet can contain, the properties in the tweet struct have to be de- and encoded by a custom implementation.</p>

**Code Links:**
  * [Twitter Entities](https://github.com/maikdrop/MyTwitterDrop/tree/main/Sources/MyTwitterDrop/Model)

## 3. UI

<p align="justify">The UI in this project focuses on responsiveness and status information. That’s why network and database fetches never run on the main queue. The result is that the user can scroll through the tweets earlier because the profile images of the tweeters will be fetched in the background later. So, it’s not necessary to wait until the fetching of the image finishes.</p>

### 3.1. Tweets

<p align="justify">A List of Tweets is used in several views and contexts. There are different possibilities to make the list reusable. One possibility is to reuse a TableViewController with a custom  configured tweet cell. The problem is that the UI logic e.g. selecting a cell or swipe action will be reused as well. It makes more sense to make the tweet cell itself reusable. That can be done programmatically or using the interface builder (IB). The IB was chosen because the handling is easier to arrange and constraint parts of the UI e.g. labels and images. Graphic 4 shows the result of the IB in Xcode.</p>

<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/TweetCell.png" align="center" width="450">
     <p align="center">Graphic 4: Tweet UI; Source: <a href="TwitterDrop/CustomCells/TweetTableViewCell.xib">TweetTableViewCell.xib</a> in Xcode
  </p>
</figure>
<br/>

### 3.2. Spinning Indicators and Alerts

<p align="justify">The goal of the spinning indicators and alerts is that the user is always informed about what’s going on.
 
Indicators are used in order to inform the user that tweets are fetched from Twitter or during the authentication of the user. In order to make the UI clear, the large indicator has a grey background when it appears in the center of the view (see graphic 5). If a list of searched tweets is refreshed during scrolling, a small spinning indicator is showing at the end of the list (see graphic 6).
 
Alerts are used when a network connection should be established but the network is unavailable e.g. when tweets should be fetched from Twitter or the user has to be authenticated (see graphic 7).</p>

<br/>
<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/SpinningIndicator.png" align="center" width="300">
     <p align="center">Graphic 5: Large Spinning Indicator; Source: Own Illustration of Search for Tweets
  </p>
</figure>

<br/>
<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/SpinningIndicator_small.png" align="center" width="300">
     <p align="center">Graphic 6: Small Spinning Indicator; Source: Own Illustration of Search for Tweets
  </p>
</figure>

<br/>
<br/>
<figure>
  <p align="center">
     <img src="/TwitterDrop/ReadMeImages/NoNetwork.png" align="center" width="300">
     <p align="center">Graphic 7: No Network Available; Source: Own Illustration of Search for Tweets
  </p>
</figure>
<br/>

**Code Links:**
  * [LoadingViewController.swift](TwitterDrop/Utility/View%20Helper/LoadingViewController.swift)
  * [TweetSearch.swift](TwitterDrop/Scenes/TweetSearch/TweetSearchTableViewController.swift)
  * [UIViewController+Alert.swift](TwitterDrop/Extension/UIViewController+Alert.swift)
