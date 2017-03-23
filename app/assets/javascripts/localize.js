function setCurrentLocale(locale) {
    window.currentLocale = locale;
}
function getCurrentLocale() {
    if(!window.currentLocale) window.currentLocale = 'en';
    return window.currentLocale;
}
function getDefaultLocale() {
 return (window.threadComputedData && window.threadComputedData.locale) || (window.threadAccount && window.threadAccount.locale) || 'en';
}
function localize(key, params) {
    if(!params) params = {};
    var keys = key.split(".");

    var locale = getCurrentLocale();
    if(params.locale) {
        locale = params.locale;
    }
    var rawResult = window.wordings[locale];
    while(keys.length > 0) {
        if(!rawResult) {
            return "Missing wording: " + locale + "." + key;
        }
        var currentKey = keys.shift();
        rawResult = rawResult[currentKey];
    }
    var regexp = /%{([a-zA-Z_]*)}/;
    var lastMatch = rawResult.match(regexp);

    while(lastMatch) {
        rawResult = rawResult.replace(regexp, params[lastMatch[1]]);
        lastMatch = rawResult.match(regexp);
    }
    return rawResult;
}