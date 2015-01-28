function setCurrentLocale(locale) {
    window.currentLocale = locale;
}
function getCurrentLocale() {
    if(!window.currentLocale) window.currentLocale = 'en';
    return window.currentLocale;
}
function localize(key, params) {
    if(!params) params = {};
    var keys = key.split(".");
    var rawResult = window.wordings[getCurrentLocale()];
    while(keys.length > 0) {
        var currentKey = keys.shift();
        rawResult = rawResult[currentKey];
    }
    console.log(rawResult);
    var regexp = /%{([a-zA-Z_]*)}/;
    var lastMatch = rawResult.match(regexp);
    console.log(lastMatch);
    while(lastMatch) {
        rawResult = rawResult.replace(regexp, params[lastMatch[1]]);
        lastMatch = rawResult.match(regexp);
    }
    return rawResult;
}