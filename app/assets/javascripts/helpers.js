window.helpers = {};

window.helpers.capitalize = function(str) {
    if(str) {
        return str[0].toUpperCase() + str.substr(1);
    }
    else {
        return str;
    }

};

window.helpers.lowerize = function(str) {
    if(str) {
        return str[0].toLowerCase() + str.substr(1);
    }
    else {
        return str;
    }

};

// Take in input an url query string like "?default_template=Demander%20quel%20est%20le%20client%20concern%C3%A9"
// And return an object like {default_template: "Demander quel est le client concerné"}
window.helpers.getQueryParams = function(queryString) {
    queryString = queryString.split('+').join(' ');

    var params = {},
        tokens,
        re = /[?&]?([^=]+)=([^&]*)/g;

    while (tokens = re.exec(queryString)) {
        params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
    }

    return params;
}