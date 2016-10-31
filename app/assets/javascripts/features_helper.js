window.featuresHelper = {};

window.featuresHelper.isFeatureActive = function(featureName) {
    return $("#active-features #feature-" + featureName).length > 0;
};

// Feature Object based on the Javascript Proxy Object
// Allow to intercept the calls to any function on this objects and prevent its use if for example the feature is not active on the current operator
var Feature = function(featureName, obj) {
    var handler = {
        get: function(target, propKey, receiver) {
            var origMethod = target[propKey];

            return function(args) {
                if(!window.featuresHelper.isFeatureActive(featureName)) {
                    return;
                }

                if(typeof(args) != Array) {
                    args = [args];
                }
                return origMethod.apply(this, args);
            }
        }
    };

    return new Proxy(obj, handler);
};