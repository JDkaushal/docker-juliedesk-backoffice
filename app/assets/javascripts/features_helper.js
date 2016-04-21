window.featuresHelper = {};

window.featuresHelper.isFeatureActive = function(featureName) {
    return $("#active-features #feature-" + featureName).length > 0;
};