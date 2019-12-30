// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"

let channel = socket.channel("simulator:lobby", {}); // connect to channel "simulator"
//
channel.on('shout', function (payload) { // listen to the 'shout' event
    alert("shout");
});

channel.on("termination", function (payload){
    document.getElementById("status").innerHTML = "Simulation Completed."
    console.log("Completed")
});

channel.on("ListOfHashtagTweets", function (payload){
    console.log("REACHED ListOfHashtagTweets")
    // console.log(payload["hashtagTweets"])x`
    $("#right2").html("");
    $.each(payload["hashtagTweets"], function(key, value) {
        console.log(value)
        var html_txt
            = "<li>" + "<b>" + value["uname"] + ": " + "</b>" + value["tweet"]  + "</li>"
        $("#right2").append(html_txt);
    });
});


channel.on("ListOfMentions", function (payload){
    // alert("RETWEETS!")
    console.log("REACHED ListOfMentions")
    $("#left2").html("");
    $.each(payload["mentions"], function(key, value) {
        var html_txt
            = "<li>" + "<b>" + value["uname"] + ": " + "</b>" + value["tweet"]  + "</li>"
        $("#left2").append(html_txt);
    });
});

channel.on("ListOfRetweets", function (payload){
    // alert("RETWEETS!")
    console.log("REACHED ListOfRetweets")
    $("#mid2").html("");
    $.each(payload["retweets"], function(key, value) {
        var html_txt
            = "<li>" + "<b>" + value["uname"] + ": " + "</b>" + value["tweet"]  + "</li>"
        $("#mid2").append(html_txt);
    });
});

channel.on("ListOfHashtags", function (payload){
    console.log("REACHED ListOfHashtags")
    $("#right1").html("");
    $.each(payload["hashtags"], function(key, value) {
        var tag = value["hashtag"]
        var tag = tag.slice(1)
        var html_txt
            = "<label id=\""+tag+"\">"  + value["hashtag"] + ": " + value["count"] + "</label>"
            // = "<label>"  + value["hashtag"] + ": " + value["count"] + "</label>"
        $("#right1").append(html_txt);
        $("#"+tag).click({name:tag},myClickfunction2);
    });
});

function myClickfunction2(d){
    // alert(d.data.name)
    channel.push('getHashtagData', {
        hashtag: d.data.name
    });
}

channel.on("ListOfTweets", function (payload) {
    //console.log("REACHED ListOfTweets");
    $("#mid1").html("");
    $.each(payload["tweets"], function(key, value) {
        var html_txt
            = "<li>" + "<b>" + value["uname"] + ": " + "</b>" + value["tweet"]  + "</li>"
        $("#mid1").append(html_txt);
    });
});

channel.on("ListOfUsers", function (payload){
    console.log("REACHED ListOfUsers");
    $("#left1").html("");
    $.each(payload["users"], function(key, value) {
        var html_txt
            // = "<label>" + "<a href='#mentions'>"  + value + "</a>" + "</label>"
            = "<label id=\""+value+"\">"  + value + "</label>"
        $("#left1").append(html_txt);
        $("#"+value).click({name:value},myClickfunction1);
    });
});

function myClickfunction1(d){
    channel.push('getUserData', {
        username: d.data.name
    });
}

//
channel.join(); // join the channel.
//
let numUsers = document.getElementById('numUsers');        // list of messages.
let numTweets = document.getElementById('numTweets');          // name of message sender


//
// "listen" for the [Enter] keypress event to send a message:
// numTweets.addEventListener('keypress', function (event) {
//     if( event.keyCode == 13 && numTweets.value.length > 0 && numUsers.value.length > 0) {
//
//         channel.push('shout', { // send the message to the server on "shout" channel
//             numUsers: numUsers.value,
//             numTweets: numTweets.value// get value of "name" of person sending the message
//         });
//         numUsers.value = ''
//         numTweets.value = ''
//     }
// });