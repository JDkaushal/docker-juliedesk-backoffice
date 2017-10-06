window.flowConditionsHandler = {};

window.flowConditionsHandler.conditionCouldBeReached = function(flowConditions, conditionName) {
    return _.keys(flowConditions).indexOf(conditionName) > -1;
};

window.availableFrontFlowConditionsGroups = function(groupName) {
    return {
        conscience_suggestion: {
            wait_for: function(processConditions) {
                if(!window.consienceSuggestionCallbacks) {
                    window.consienceSuggestionCallbacks = []
                }
                window.consienceSuggestionCallbacks.push(function(conscienceSuggestionData) {
                    processConditions({
                        conscienceSuggestionData: conscienceSuggestionData
                    });
                });
            },
            conditions: {
                'count': function(contextData, conditionValue) {
                    return contextData.conscienceSuggestionData.suggestions.length === conditionValue;
                },
                'suggestion_on_all_day_event': function(contextData, conditionValue) {
                    var suggestionOnAllDayEvent = contextData.conscienceSuggestionData.all_days_on_suggestions;
                    return suggestionOnAllDayEvent == conditionValue;
                }
            }

        }
    }[groupName];
};

window.flowConditionsHandler.processFlowConditions = function(flowConditions) {
    var flowConditionsPromises = {};

    _.each(flowConditions, function(flowData, flowName) {
        flowConditionsPromises[flowName] = {};
        var frontConditionsGroups = flowData.front_conditions;

        _.each(frontConditionsGroups, function(conditions, conditionsGroupName) {
            flowConditionsPromises[flowName][conditionsGroupName] = "pending";
            window.flowConditionsHandler.processFlowConditionsGroup(conditionsGroupName, conditions, function(result) {
                flowConditionsPromises[flowName][conditionsGroupName] = result;
                var allFlowsResult = window.flowConditionsHandler.handleFlowConditionsPromises(flowConditionsPromises);
                if(allFlowsResult.status === 'success' && flowData.flow_action) {
                    window[flowData.flow_action]();
                }
            });
        })
    });
    window.flowConditionsHandler.handleFlowConditionsPromises(flowConditionsPromises);
};

window.flowConditionsHandler.processFlowConditionsGroup = function(groupName, conditions, callback) {
    var frontFlowConditionsGroup = window.availableFrontFlowConditionsGroups(groupName);
    if(!frontFlowConditionsGroup) {
        throw("Unsupported frontConditionsGroupName: " + groupName);
    }
    frontFlowConditionsGroup.wait_for(function(contextData) {
        var conditionsResults = _.map(conditions, function(conditionValue, conditionName) {
            var conditionFunction = frontFlowConditionsGroup.conditions[conditionName];
            if(!conditionFunction) {
                throw("Unsupported conditionName from " + groupName + " : " + conditionName)
            }
            return conditionFunction(contextData, conditionValue);
        });

        callback(!_.contains(conditionsResults, false));
    });
};

window.flowConditionsHandler.handleFlowConditionsPromises = function(flowConditionsPromises) {
    var flowResults = {};
    _.each(flowConditionsPromises, function(flowConditionsGroups, flowName) {
        if(_.contains(flowConditionsGroups, "pending")) {
            flowResults[flowName] = "pending";
        }
        else if(_.contains(flowConditionsGroups, false)) {
            flowResults[flowName] = false;
        }
        else {
            flowResults[flowName] = true;
        }
    });
    if(_.contains(flowResults, "pending")) {
        return {
            status: "pending"
        }
    }
    else {
        var positiveFlowNames = [];
        _.each(flowResults, function(result, flowName) {
            if(result) {
                positiveFlowNames.push(flowName);
            }
        });
        if(positiveFlowNames.length === 0) {
            return {
                status: "no_flow"
            }
        }
        else if(positiveFlowNames.length > 1) {
            return {
                status: "several_flows"
            }
        }
        else {
            return {
                status: "success",
                flow: positiveFlowNames[0]
            }
        }

    }
};