(function(){

    var app = angular.module('AI-manager-controllers', ['templates']);

    app.controller('localeManager', ['$scope', '$injector', 'messageInterpretationsService', function($scope, $injector, messageInterpretationsService) {
        $scope.currentLocale = undefined;
        $scope.localeValidated = false;
        $scope.clickedOnWrong = false;

        var messagesContainerNode = $('#messages_container');
        var messagesThreadId = messagesContainerNode.data('messages-thread-id');
        var trackingId = messagesContainerNode.data('operator-id').toString() + '-' + messagesThreadId.toString();

        var localeDiscrepancyMessageNode = $('.locale-discrepancy-message');

        $('.locale-discrepancy-message').on('click', '.locale-ai-right-link', function(e) {
            e.preventDefault();
            $scope.clickedOnWrong = true;
            $scope.displayLocaleDiscrepancyMessage(false);
        });

        $(".submit-classification").click(function () {
            $scope.trackLocaleAIFeedback();
        });

        $scope.init = function() {
            var mainInterpretation = messageInterpretationsService.getMainInterpretation();

            $("input[name='locale']").change(function (e) {
                if(!!$scope.currentLocale && window.formFirstPass) {
                    $scope.checkLocaleConsistency(e.currentTarget.value, function() {
                        if(!$scope.localeValidated) {
                            askNextLinearFormEntry();
                            $scope.localeValidated = true;

                            if($('#appointment_family_nature').val()) {
                                askNextLinearFormEntry();
                            }
                        }
                    });
                }
            });

            if(mainInterpretation && !!mainInterpretation.language_detected) {
                $scope.currentLocale = mainInterpretation.language_detected;
            }

            if(!!$scope.currentLocale) {
                // The first time the form is filled
                if (window.formFirstPass) {
                    //$('#locale_' + $scope.currentLocale).prop('checked', true);

                    // If the AI locale detected is the same as the current used locale in the thread
                    if($scope.currentLocale == window.currentLocale) {
                        // Bypass the locale selection step
                        askNextLinearFormEntry();
                        $scope.localeValidated = true;
                    } else {
                        $scope.checkLocaleConsistency(window.currentLocale);
                    }
                } else {
                    $scope.checkLocaleConsistency($scope.currentLocale);
                }
            }
        };

        $scope.checkLocaleConsistency = function(locale, sameLocaleCallback) {
            if(locale != $scope.currentLocale) {
                $scope.currentLocaleDifferentThanAI();
            } else {
                $scope.displayLocaleDiscrepancyMessage(false);
                if(sameLocaleCallback)
                    sameLocaleCallback();
            }
        };

        $scope.currentLocaleDifferentThanAI = function() {
            localeDiscrepancyMessageNode.find('#locale_discrepancy_text').html($scope.getLocaleDiscrepancyMessage());
            $scope.displayLocaleDiscrepancyMessage(true);
        };

        $scope.displayLocaleDiscrepancyMessage = function(show) {
            if(show) {
                localeDiscrepancyMessageNode.show();
            } else {
                localeDiscrepancyMessageNode.hide();
            }
        };

        $scope.getLocaleDiscrepancyMessage = function() {
            var message = '';
            var locale = $scope.currentLocale;

            switch(locale) {
                case 'en':
                    message += 'Anglais détecté <a class="locale-ai-right-link" href="#">C\'est bien du français</a>';
                    break;
                case 'fr':
                    message += 'Français détecté <a class="locale-ai-right-link" href="#">C\'est bien de l\'anglais</a>';
                    break;
                default:
                    message += 'Locale non supportée : ' + locale;
            }

            return message;
        };

        $scope.trackLocaleAIFeedback = function() {
            window.trackEvent("ai_language_detection", {
                distinct_id: trackingId,
                message_id: $('.email.highlighted').attr('id'),
                language_detected: $scope.currentLocale,
                language_confirmed: window.currentLocale,
                ai_success_boolean: $scope.currentLocale == window.currentLocale,
                first_path: window.formFirstPass,
                click_on_wrong_boolean: $scope.clickedOnWrong
            });
        };

        $scope.init();

    }]);

    app.controller('appointmentTypeManager', ['$scope', '$injector', 'messageInterpretationsService', function($scope, $injector, messageInterpretationsService) {
        $scope.currentAppointmentType = undefined;
        $scope.currentlySelectedAppointmentType = undefined;

        var appointmentSelectNode = $('#appointment_family_nature');
        var appointmentNatureNode = $('#appointment_nature');

        var messagesContainerNode = $('#messages_container');
        var messagesThreadId = messagesContainerNode.data('messages-thread-id');
        var trackingId = messagesContainerNode.data('operator-id').toString() + '-' + messagesThreadId.toString();

        $(".submit-classification").click(function () {
            $scope.trackAppointmentTypeAIFeedback();
        });

        appointmentSelectNode.change(function() {
            $scope.currentlySelectedAppointmentType = appointmentSelectNode.val();

            if($scope.currentlySelectedAppointmentType == $scope.currentAppointmentType) {
                $scope.tagInputToVerify();
            }else {
                $scope.untagInputToVerify();
            }
        });

        $scope.init = function() {
            // The first time the form is filled
            if(window.threadComputedData.appointment_nature === null) {
                var mainInterpretation = messageInterpretationsService.getMainInterpretation();

                if(mainInterpretation && mainInterpretation.appointment_classif && mainInterpretation.appointment_proba >= 0.50) {
                    $scope.currentAppointmentType = mainInterpretation.appointment_classif;
                    $scope.setAppointmentType();
                    //$scope.tagInputToVerify();
                }
            }
        };

        $scope.tagInputToVerify = function() {
            $('#appointment_family_nature').addClass('ai-need-control');
        };

        $scope.untagInputToVerify = function() {
            $('#appointment_family_nature').removeClass('ai-need-control');
        };

        $scope.setAppointmentType = function() {
            appointmentSelectNode.val($scope.currentAppointmentType);
            // To trigger the related events
            appointmentSelectNode.trigger('change');

            // setTimeout to wait for page to load and data to be available
            setTimeout(function() {
                appointmentNatureNode.trigger('change');
            }, 500);

        };

        $scope.trackAppointmentTypeAIFeedback = function() {
            window.trackEvent("ai_appointment_type", {
                distinct_id: trackingId,
                message_id: $('.email.highlighted').attr('id'),
                event_type_detected: $scope.currentAppointmentType,
                event_type_confirmed: $scope.currentlySelectedAppointmentType,
                ai_success_boolean: $scope.currentAppointmentType == $scope.currentlySelectedAppointmentType
            });
        };

        $scope.init();
    }]);

    app.directive('phoneSkypeEntitiesManager', function() {
        return {
            restrict: 'E',
            templateUrl: 'phone-skype-entities-manager.html',
            controller: ['$scope', '$element', 'attendeesService', function($scope, $element, attendeesService) {
                var messagesContainerNode = $('#messages_container');
                var messagesThreadId = messagesContainerNode.data('messages-thread-id');
                var trackingId = messagesContainerNode.data('operator-id').toString() + '-' + messagesThreadId.toString();
                var attendeeEditionNode = $($element[0]).find('.attendee-edition');
                var attendeesSelectionNode = $($element[0]).find('.attendees-area');
                var interactionAreaNode = $($element[0]).find('.interaction-area');
                var editionPanelNode = $($element[0]).find('.edition-panel');
                var phoneSkypeEntitiesFormNode = $($element[0]).find('.phone-skype-entities-form');

                $scope.currentDetectedOwner = undefined;
                $scope.currentDetectedNewOwner = undefined;
                $scope.currentDetectedSupportType = undefined;
                $scope.currentDetectedSupport = undefined;
                $scope.currentPositionInText = undefined;
                $scope.entityType = '';
                $scope.value = '';
                $scope.valueDetected = '';
                $scope.attendees = [];
                $scope.currentSelectedAttendee = undefined;
                $scope.possibleAttributes = [];
                $scope.attributeToModify = '';
                $scope.displayForm = false;

                $scope.currentClickedEntityNode = undefined;

                $scope.$on('callNumbersFetched', function(event, args) {
                    $scope.validateAlreadyFetchedEntities(args);
                });

                $scope.$on('clientsFetched', function(event, args) {
                    $scope.discardClientRelatedEntities(args.clients);
                });

                $($element[0]).on('click', '.attendee', function(e) {
                    $scope.goToAttendeeEditionPanel(e);
                });

                $($element[0]).on('click', '.type:not(.not-clickable)', function(e) {
                    $scope.saveSelectedAttribute(e);
                });

                $($element[0]).find('#go_to_attendees_list').click(function(e) {
                    $scope.goToAttendeesListPanel();
                });

                // The e.preventDefault() below allow to ignore eventual <a></a> tags that could be wrapping the entity <span> tag
                // causing to trigger the link when an operator click the entity
                $('phone-skype-entities-manager').click(function(e) {
                    e.preventDefault();
                });

                $('.juliedesk-entity.skype').click(function(e) {
                    e.preventDefault();
                    $scope.displayFormAction('skype', $(e.currentTarget));
                });

                $('.juliedesk-entity.phone').click(function(e) {
                    e.preventDefault();
                    $scope.displayFormAction('phone', $(e.currentTarget));
                });

                // To close the form when clicking outside the element
                $(document).mouseup(function(e) {
                    var container = $($element[0]);

                    if (!container.is(e.target) // if the target of the click isn't the container...
                        && container.has(e.target).length === 0) // ... nor a descendant of the container
                    {
                        $scope.closeForm();
                    }
                });

                $scope.displayFormAction = function(entity_type, currentTargetNode) {

                    $scope.attendees = attendeesService.getAttendeesWithoutClients();
                    $scope.currentDetectedSupportType = entity_type;
                    $scope.currentClickedEntityNode = currentTargetNode;
                    $scope.currentSelectedAttendee = undefined;
                    $scope.displayForm = true;

                    $scope.setParametersExtractedFromEntity();
                    $scope.attachFormToClickedNode();
                    $scope.highlightClickedEntityNode();
                    $scope.setSelectedAttendeeIfPossible();
                    $scope.highlightAttributeToModify();
                    $scope.checkDisplayAttendeeEditMode();
                    $scope.determinePossibleAttributes();

                    if(!$scope.$$phase) {
                        $scope.$apply();
                    }

                    $scope.trackOpenEvent();
                };

                $scope.discardClientRelatedEntities = function(clients) {
                    var $node, phoneBaseSelector, skypeBaseSelector;
                    _.each(clients, function(client) {
                        phoneBaseSelector = '.juliedesk-entity.phone[owner="' + client.email + '"]';
                        skypeBaseSelector = '.juliedesk-entity.skype[owner="' + client.email + '"]';
                        $node = $(phoneBaseSelector + '[from="signature"],' + phoneBaseSelector + '[from="reply_signature"],' + skypeBaseSelector + '[from="signature"],' + skypeBaseSelector + '[from="reply_signature"]');
                        if($node) {
                            // Remove Events handlers (click ...)
                            $node.off();
                            // Change the class so it is not displayed anymore as an entity to the operator
                            $node.removeClass('juliedesk-entity').addClass('juliedesk-entity-client');
                        }
                    });
                };

                $scope.saveSelectedAttribute = function(e) {
                    $scope.attributeToModify = e.currentTarget.dataset.attributeValue;
                    $($element[0]).find('.attendee-edition').find('.type').removeClass('highlighted');
                    $(e.currentTarget).addClass('highlighted');

                    $scope.saveCurrentSelectedAttendee();
                    $scope.closeForm();
                };

                $scope.goToAttendeesListPanel = function() {
                    interactionAreaNode.addClass('slide-to-right');
                    interactionAreaNode.removeClass('slide-to-left');
                };

                $scope.goToAttendeeEditionPanel = function(e) {
                    var id = e.currentTarget.dataset.attendeeId;
                    $scope.currentSelectedAttendee = _.find($scope.attendees, function(a) {
                        return a.guid == id;
                    });
                    attendeeEditionNode.find('.type').removeClass('highlighted');
                    interactionAreaNode.removeClass('slide-to-right');
                    interactionAreaNode.addClass('slide-to-left');
                    $scope.attributeToModify = '';
                    $scope.$apply();
                };

                $scope.validateAlreadyFetchedEntities = function(args) {
                    var existingNodes = undefined;

                    _.each(args.callNumbers, function(details, number) {

                        // ALlow to discard problems when a confcall is using complex instructions
                        try{
                            existingNodes = $('.juliedesk-entity.phone[value="' + number + '"], .juliedesk-entity.skype[value="' + number + '"]');
                        }catch(e) {
                            console.log(e);
                        }

                        if(!!existingNodes) {
                            existingNodes.addClass('validated');
                            existingNodes.attr('new-owner', details.ownerGuid);
                            existingNodes.attr('attribute-to-modify', details.type);
                        }
                    });
                };

                $scope.closeForm = function() {
                    if($scope.displayForm) {
                        $scope.closeFormAction();
                    }
                };

                $scope.closeFormAction = function() {
                    $scope.currentClickedEntityNode.removeClass('highlighted');
                    $('.type').removeClass('highlighted');
                    interactionAreaNode.removeClass('slide-to-right');
                    interactionAreaNode.removeClass('slide-to-left');
                    $scope.displayForm = false;
                    $scope.$apply();
                };

                $scope.saveCurrentSelectedAttendee = function() {
                    if($scope.updateCurrentAttendeeAttribute()) {
                        $('.type').removeClass('highlighted');
                        $('.type[data-attribute-value="' + $scope.attributeToModify + '"]').addClass('highlighted');
                    }
                    editionPanelNode.removeClass('slide-to-right');
                    editionPanelNode.removeClass('slide-to-left');
                    $scope.$apply();

                    $scope.trackSaveEvent();
                };

                $scope.setParametersExtractedFromEntity = function() {
                    $scope.currentDetectedOwner = $scope.currentClickedEntityNode.attr('owner');
                    $scope.attributeToModify = $scope.currentClickedEntityNode.attr('attribute-to-modify');
                    $scope.currentDetectedNewOwner = $scope.currentClickedEntityNode.attr('new-owner');
                    $scope.currentDetectedSupport = $scope.currentClickedEntityNode.attr('type');
                    $scope.value = $scope.currentClickedEntityNode.attr('new-value') || $scope.currentClickedEntityNode.attr('value');

                    if(!!$scope.currentClickedEntityNode.attr('position-in-text'))
                        $scope.currentPositionInText = JSON.parse($scope.currentClickedEntityNode.attr('position-in-text'));
                };

                $scope.highlightClickedEntityNode = function() {
                    $scope.currentClickedEntityNode.addClass('highlighted');
                };

                $scope.setSelectedAttendeeIfPossible = function() {
                    if(!!$scope.currentDetectedNewOwner) {
                        $scope.currentSelectedAttendee = _.find($scope.attendees, function(a) {
                            return a.guid == $scope.currentDetectedNewOwner;
                        });
                    }else if(!!$scope.currentDetectedOwner) {
                        $scope.currentSelectedAttendee = _.find($scope.attendees, function(a) {
                            return a.email == $scope.currentDetectedOwner;
                        });
                    }
                };

                $scope.attachFormToClickedNode = function() {
                    var form = $($element[0]).detach();
                    $scope.currentClickedEntityNode.after(form);
                    // Adjust the left postion of the form to match the one of the clicked element
                    phoneSkypeEntitiesFormNode.css({left: $scope.currentClickedEntityNode.position().left.toString() + 'px'});
                };

                $scope.highlightAttributeToModify = function() {
                    if(!!$scope.attributeToModify) {
                        $('.type[data-attribute-value="' + $scope.attributeToModify + '"]').addClass('highlighted');
                    }
                };

                $scope.checkDisplayAttendeeEditMode = function() {
                    if(!!$scope.currentSelectedAttendee) {
                        interactionAreaNode.addClass('slide-to-left');
                    }
                };

                $scope.determinePossibleAttributes = function() {
                    switch($scope.currentDetectedSupportType) {
                        case 'phone':
                            $scope.possibleAttributes = [
                                {name: 'Mobile', value: 'mobile'},
                                {name: 'Téléphone Fix', value: 'landline'},
                                {name: 'Confcall', value: 'confCallInstructions'}
                            ];
                            break;
                        case 'skype':
                            $scope.possibleAttributes = [
                                {name: 'Skype', value: 'skypeId'}
                            ];
                            break;
                    }
                };

                $scope.updateCurrentAttendeeAttribute = function() {
                    var result = false;
                    if($scope.currentSelectedAttendee && $scope.attributeToModify) {
                        $scope.currentSelectedAttendee[$scope.attributeToModify] = $scope.value;
                        attendeesService.applyScope();
                        $scope.setEntityTypeNodeValidated();
                        result = true;
                    }

                    return result;
                };

                $scope.setEntityTypeNodeValidated = function() {
                    var nodes = $('.juliedesk-entity[entity-id="' + $scope.currentClickedEntityNode.attr('entity-id') + '"]');
                    nodes.addClass('validated');
                    nodes.attr('new-owner', $scope.currentSelectedAttendee.guid);
                    nodes.attr('attribute-to-modify', $scope.attributeToModify);
                    nodes.attr('new-value', $scope.value);
                };

                $scope.setEntityTypeNodeUnvalidated = function() {
                    var nodes = $('.juliedesk-entity[entity-id="' + $scope.currentClickedEntityNode.attr('entity-id') + '"]');
                    nodes.removeClass('validated');
                    nodes.removeAttr('new-owner');
                    nodes.removeAttr('attribute-to-modify');
                };

                $scope.trackOpenEvent = function() {
                    window.trackEvent("click_on_contact_recognition", {
                        distinct_id: trackingId,
                        interpreted_text: $scope.value,
                        support_detected: $scope.currentDetectedSupport,
                        participant_detected: $scope.currentDetectedOwner,
                        index_in_text: $scope.currentPositionInText,
                        message_id: $scope.currentClickedEntityNode.closest('.email').data('message-id'),
                        thread_id: messagesThreadId
                    });
                };

                $scope.trackSaveEvent = function() {
                    var attendeeEmail = null;
                    if($scope.currentSelectedAttendee)
                        attendeeEmail = $scope.currentSelectedAttendee.email;

                    window.trackEvent("save_contact_recognition", {
                        distinct_id: trackingId,
                        interpreted_text: $scope.currentClickedEntityNode.attr('value'),
                        saved_text: $scope.value,
                        support_detected: $scope.currentDetectedSupport,
                        participant_detected: $scope.currentDetectedOwner,
                        support_saved: $scope.attributeToModify,
                        participant_saved: attendeeEmail,
                        index_in_text: $scope.currentPositionInText,
                        message_id: $scope.currentClickedEntityNode.closest('.email').data('message-id'),
                        thread_id: messagesThreadId
                    });
                };

            }],
            controllerAs: 'phoneEntitiesManager'
        }
    });

    app.controller('datesSuggestionManager', ['$scope', 'aIDatesSuggestionService', function($scope, aIDatesSuggestionService) {

        $scope.init = function() {
        };

        $scope.fetchSuggestedDatesByAi = function(params) {
            return aIDatesSuggestionService.fetch(params);
        };

        $scope.sendLearningData = function(params) {
            return aIDatesSuggestionService.sendLearningData(params);
        };

        $scope.init();
    }]);

    app.controller('eventsMetadataManager', ['$scope', '$q', 'eventsMetadataService', function($scope, $q, eventsMetadataService) {

        $scope.init = function() {
        };

        $scope.fetchMetadata = function(params) {
            return eventsMetadataService.fetch(params).then(function(response) {
                return JSON.parse(response.data.calendar);
            });
        };
        
        $scope.fetchSchedulingEventMetadata = function() {
            return $scope.fetchMetadata({
                events: [{
                    id: 'scheduling_event',
                    summary: window.threadComputedData.summary,
                    attendees: window.threadComputedData.attendees,
                    location: window.threadComputedData.location
                }],
                calendar_login_username: window.threadComputedData.calendar_login_username
                }
            );
        };


        $scope.init();
    }]);
    
    app.controller('datesVerificationManager', ['$scope', 'aIDatesVerificationService', function($scope, aIDatesVerificationService) {

        $scope.init = function() {
        };

        $scope.verifyDates = function(params) {
            return aIDatesVerificationService.verifyDates(params);
        };

        $scope.init();
    }]);

})();