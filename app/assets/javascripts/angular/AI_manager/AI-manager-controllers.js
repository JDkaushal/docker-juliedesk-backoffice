(function(){

    var app = angular.module('AI-manager-controllers', ['templates']);

    app.controller('localeManager', ['$scope', '$injector', 'messageInterpretationsService', function($scope, $injector, messageInterpretationsService) {
        $scope.currentLocale = undefined;

        var localeDiscrepancyMessageNode = $('.locale-discrepancy-message');

        $scope.init = function() {
            var mainInterpretation = messageInterpretationsService.getMainInterpretation();

            $("input[name='locale']").change(function (e) {
                if(!!$scope.currentLocale) {
                    $scope.checkLocaleConsistency(e.currentTarget.value);
                }
            });

            if(mainInterpretation && !!mainInterpretation.language_detected) {
                $scope.currentLocale = mainInterpretation.language_detected;
            }

            if(!!$scope.currentLocale) {
                // The first time the form is filled
                if (window.threadComputedData.appointment_nature === null) {
                    $('#locale_' + $scope.currentLocale).prop('checked', true);
                    // Bypass the locale selection step
                    askNextLinearFormEntry();
                } else {
                    $scope.checkLocaleConsistency($scope.currentLocale);
                }
            }
        };

        $scope.checkLocaleConsistency = function(locale) {
            if(locale != $scope.currentLocale) {
                localeDiscrepancyMessageNode.find('#locale_discrepancy_text').html($scope.getLocaleDiscrepancyMessage());
                $scope.displayLocaleDiscrepancyMessage(true);
            } else {
                $scope.displayLocaleDiscrepancyMessage(false);
            }
        };

        $scope.displayLocaleDiscrepancyMessage = function(show) {
            if(show) {
                localeDiscrepancyMessageNode.show();
            } else {
                localeDiscrepancyMessageNode.hide();
            }
        };

        $scope.getLocaleDiscrepancyMessage = function() {
            var message = 'Attention - ';
            var locale = $scope.currentLocale;

            switch(locale) {
                case 'en':
                    message += 'Anglais détecté';
                    break;
                case 'fr':
                    message += 'Français détecté';
                    break;
                default:
                    message += 'Locale non supportée : ' + locale;
            }

            return message;
        };

        $scope.init();

    }]);

    app.controller('appointmentTypeManager', ['$scope', '$injector', 'messageInterpretationsService', function($scope, $injector, messageInterpretationsService) {
        $scope.currentAppointmentType = undefined;
        var appointmentSelectNode = $('#appointment_family_nature');

        $scope.init = function() {
            // The first time the form is filled
            if(window.threadComputedData.appointment_nature === null) {
                var mainInterpretation = messageInterpretationsService.getMainInterpretation();

                if(mainInterpretation && mainInterpretation.appointment_classif && mainInterpretation.appointment_proba >= 0.50) {
                    $scope.currentAppointmentType = mainInterpretation.appointment_classif;
                    $scope.setAppointmentType();
                }
            }
        };

        $scope.setAppointmentType = function() {
            appointmentSelectNode.val($scope.currentAppointmentType);
            // To trigger the related events
            appointmentSelectNode.trigger('change');
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
                    $scope.validateClientRelatedEntities(args.clients);
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

                $scope.validateClientRelatedEntities = function(clients) {
                    _.each(clients, function(client) {
                        $('.juliedesk-entity.phone[owner="' + client.email + '"], .juliedesk-entity.skype[owner="' + client.email + '"]').addClass('validated');
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

})();