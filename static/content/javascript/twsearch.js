function twsearch(C) {
    var R = C.results;
    var A = [];
    for (var D = 0; D < R.length; D++) {
        var E = R[D].to_user;
        var B = R[D].text.replace(/((https?|s?ftp|ssh)\:\/\/[^"\s\<\>]*[^.,;'">\:\s\<\>\)\]\!])/g, function(F) {
            return '<a href="' + F + '">' + F + "</a>"
        }).replace(/\B@([_a-z0-9]+)/ig, function(F) {
            return F.charAt(0) + '<a href="http://www.twitter.com/' + F.substring(1) + '">' + F.substring(1) + "</a>"
        });
        A.push('<li><span> <b><a href="http://twitter.com/' + R[D].from_user + '">' + R[D].from_user + '</a></b></span> <span>' + B + '</span> <a style="font-size: 85%" href="http://twitter.com/' + R[D].from_user + "/statuses/" + R[D].id + '">' + search_relative_time(R[D].created_at) + "</a></li>");
    }
    document.getElementById("twitter_update_list").innerHTML = A.join("");
}
function search_relative_time(C) {
    var B = C.split(" ");
    C = B[2] + " " + B[1] + ", " + B[3] + " " + B[4];
    var A = Date.parse(C);
    var D = (arguments.length > 1) ? arguments[1] : new Date();
    var E = parseInt((D.getTime() - A) / 1000);
    E = E + (D.getTimezoneOffset() * 60);
    if (E < 60) {
        return "less than a minute ago"
    } else if (E < 120) {
        return "about a minute ago"
    } else if (E < (60 * 60)) {
        return (parseInt(E / 60)).toString() + " minutes ago"
    } else if (E < (120 * 60)) {
        return "about an hour ago"
    } else if (E < (24 * 60 * 60)) {
        return "about " + (parseInt(E / 3600)).toString() + " hours ago"
    } else if (E < (48 * 60 * 60)) {
        return "1 day ago"
    } else return (parseInt(E / 86400)).toString() + " days ago";
}
function relative_time(C) {
    var B = C.split(" ");
    C = B[1] + " " + B[2] + ", " + B[5] + " " + B[3];
    var A = Date.parse(C);
    var D = (arguments.length > 1) ? arguments[1] : new Date();
    var E = parseInt((D.getTime() - A) / 1000);
    E = E + (D.getTimezoneOffset() * 60);
    if (E < 60) {
        return "less than a minute ago"
    } else {
        if (E < 120) {
            return "about a minute ago"
        } else {
            if (E < (60 * 60)) {
                return (parseInt(E / 60)).toString() + " minutes ago"
            } else {
                if (E < (120 * 60)) {
                    return "about an hour ago"
                } else {
                    if (E < (24 * 60 * 60)) {
                        return "about " + (parseInt(E / 3600)).toString() + " hours ago"
                    } else {
                        if (E < (48 * 60 * 60)) {
                            return "1 day ago"
                        } else { return (parseInt(E / 86400)).toString() + " days ago" } 
                    } 
                } 
            } 
        } 
    }
}