window.helpers = {};

window.helpers.capitalize = function(str) {
    if(str) {
        return str[0].toUpperCase() + str.substr(1);
    }
    else {
        return str;
    }

};