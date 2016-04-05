window.classificationForms.askAvailabilitiesForm = function(params) {
    window.classificationForms.classificationForm.isParentOf(this, params);
    this.alreadySuggestedDates = params.alreadySuggestedDates;

    var askAvailabilitiesForm = this;
    window.leftColumnMessage = localize("classification_forms.ask_availabilities.dates_identification")


    window.submitClassification = function () {
        askAvailabilitiesForm.sendForm();
    };

    $(function(e) {
        $(".client-agreement-panel .yes-button").click(function () {
            askAvailabilitiesForm.validateClientAgreement(true, true);
        });

        askAvailabilitiesForm.checkClientAgreement();

        $("#submit-these-already-suggested-dates").click(function() {
            askAvailabilitiesForm.submitSuggestedDates(true);
        });
        $("#none-of-already-suggested-dates").click(function() {
            askAvailabilitiesForm.submitSuggestedDates(false);
        });
        $("#submit-detected-date-button").click(function() {
            askAvailabilitiesForm.submitDetectedDates();
        });

        $(".already-suggested-dates-container .already-suggested-date input[type=checkbox]").change(function() {
            askAvailabilitiesForm.changeAlreadySuggestedDateCheckbox();
        });
        $("body").on("click", ".detected-date .detected-date-remove-button", function(e) {
            $(this).closest(".detected-date").remove();
        });
        $("#add-detected-date-button").click(function(e) {
            askAvailabilitiesForm.appendDetectedDateRow({
                startDate: moment()
            });
        });

        askAvailabilitiesForm.processDateDetection();
        askAvailabilitiesForm.changeAlreadySuggestedDateCheckbox();


        $(".classic-info-panel").hide();
        //$(".waiting-for-others-panel").show();

    });
};

window.classificationForms.askAvailabilitiesForm.prototype.getSuggestedDateTimes = function() {
    var askAvailabilitiesForm = this;

    return $.map(askAvailabilitiesForm.suggestedDates, function(d) {
        if(d.date) {
            return {
                date: d.date.clone().tz("utc").format(),
                timezone: d.date.tz()
            }
        }
        else {
            return {
                text: d.text
            }
        }
    });
};

window.classificationForms.askAvailabilitiesForm.prototype.checkAlreadySuggestedDates = function() {
    var askAvailabilitiesForm = this;
    var datesmanager = $('#dates-identifications-manager').scope();

    $(".messages-thread-info-panel .classic-info-panel").hide();
    $(".messages-thread-info-panel .dates-identification-panel").show();
    if(askAvailabilitiesForm.alreadySuggestedDates.length > 0) {
        $(".messages-thread-info-panel .dates-identification-panel .already-suggested-dates-container").show();
        $(".messages-thread-info-panel .dates-identification-panel .detected-dates-container").hide();
        datesmanager.showAlreadySuggestedDates();
    }
    else {
        $(".messages-thread-info-panel .dates-identification-panel .already-suggested-dates-container").hide();
        $(".messages-thread-info-panel .dates-identification-panel .detected-dates-container").show();
        datesmanager.showDetectedDates();
    }

    datesmanager.$apply();
};

window.classificationForms.askAvailabilitiesForm.prototype.submitSuggestedDates = function(answerToSuggestedDates) {
    var askAvailabilitiesForm = this;
    var datesManager = $('#dates-identifications-manager').scope();

    if(answerToSuggestedDates) {
        askAvailabilitiesForm.suggestedDates = $(".already-suggested-dates-container .already-suggested-date input[type=checkbox]:checked").map(function() {
            var date = $(this).closest(".already-suggested-date").data("date");
            var timezone = $(this).closest(".already-suggested-date").data("timezone");
            return {
                date: moment(date).tz(timezone)
            };
        }).toArray();
        $(".messages-thread-info-panel .dates-identification-panel").hide();
        $(".messages-thread-info-panel .classic-info-panel").show();

        askAvailabilitiesForm.addSuggestedDatesToHeader();

        //datesManager.showDetectedDates();
        //if(!datesManager.$$phase)
        //    datesManager.$apply();

        askAvailabilitiesForm.clickBackButtonFunctions.push(function() {
            console.log('here');
            $(".messages-thread-info-panel .dates-identification-panel").show();
            $(".messages-thread-info-panel .classic-info-panel").hide();
            askAvailabilitiesForm.removeSuggestedDatesToHeader();
            //datesManager.showDetectedDates();
            //if(!datesManager.$$phase)
            //    datesManager.$apply();
        });
    }
    else {
        datesManager.showDetectedDates();
        if(!datesManager.$$phase)
            datesManager.$apply();

        askAvailabilitiesForm.clickBackButtonFunctions.push(function() {
            askAvailabilitiesForm.removeSuggestedDatesToHeader();
            datesManager.showAlreadySuggestedDates();
            if(!datesManager.$$phase)
                datesManager.$apply();
        });
    }
};

window.classificationForms.askAvailabilitiesForm.prototype.submitDetectedDates = function() {
    var askAvailabilitiesForm = this;
    var datesManager = $('#dates-identifications-manager').scope();

    askAvailabilitiesForm.suggestedDates = $(".detected-dates-container .detected-dates .detected-date").map(function() {
        var $radio = $(this).find(".detected-date-radios input[type=radio]:checked");
        if($radio.length > 0 && $radio.val() == "freetext") {
            return {
                text: $(this).find(".detected-date-freetext").val()
            };
        }
        else {
            var mDate = moment.tz($(this).find(".detected-date-real-date").val() + "T" + $(this).find(".detected-date-time").val(), $(this).find(".detected-date-timezone").val());
            return {
                date: mDate
            };
        }
    }).toArray();
    $(".messages-thread-info-panel .dates-identification-panel").hide();
    $(".messages-thread-info-panel .classic-info-panel").show();

    askAvailabilitiesForm.addSuggestedDatesToHeader();

    askAvailabilitiesForm.clickBackButtonFunctions.push(function() {
        askAvailabilitiesForm.removeSuggestedDatesToHeader();
        datesManager.showDetectedDates();
        if(!datesManager.$$phase)
            datesManager.$apply();
        $(".messages-thread-info-panel .dates-identification-panel").show();
        $(".messages-thread-info-panel .classic-info-panel").hide();
    });
};

window.classificationForms.askAvailabilitiesForm.prototype.processDateDetection = function() {
    var askAvailabilitiesForm = this;
    var addedDates = [];
    var mainAiInterpretation = window.messageInterpretations[0];

    $(".detected-dates").html("");

    var timeEntities = $('.email.highlighted .body .juliedesk-entity.time');

    detectedDates = _.each(timeEntities, function(node) {
        var $node = $(node);
        var date = $node.attr('value');

        if(addedDates.indexOf(date) == -1) {
            askAvailabilitiesForm.appendDetectedDateRow({
                text: $node.text(),
                startDate: moment(date)
            });
        }

        addedDates.push(date);
    });

    if(mainAiInterpretation && !mainAiInterpretation.error && mainAiInterpretation.raw_response) {
        var datesToCheck = JSON.parse(mainAiInterpretation.raw_response).dates_to_check;
        if(datesToCheck && datesToCheck.length > 0) {
            var suggestedTimesNodes = $('.already-suggested-date');
            var currentNodeDate;
            var current$Node;
            datesToCheck = _.map(datesToCheck, function(date) {
               return moment(date);
            });

            _.each(suggestedTimesNodes, function(node) {
                current$Node = $(node);
                currentNodeDate = moment(current$Node.data('date'));
                _.every(datesToCheck, function(date) {
                    if(currentNodeDate.isSame(date)) {
                        // We trigger the change event to undisable the "Oui" button in the suggestion date pannel
                        current$Node.find('input[type="checkbox"]').prop('checked', true).trigger('change');
                        return false;
                    }
                    return true;
                });
            });
        }
    }
};

window.classificationForms.askAvailabilitiesForm.prototype.removeSuggestedDatesToHeader = function() {
    $("#selected-suggested-dates").html("");
};

window.classificationForms.askAvailabilitiesForm.prototype.addSuggestedDatesToHeader = function() {
    var askAvailabilitiesForm = this;

    askAvailabilitiesForm.removeSuggestedDatesToHeader();
    var $dataEntry = $("<div>").addClass("data-entry");
    var $dataEntryName = $("<div>").addClass("data-entry-name").html(localize("classification_forms.ask_availabilities.suggested_dates"));
    var $dataEntryValue = $("<div>").addClass("data-entry");

    $.each(askAvailabilitiesForm.suggestedDates, function(k, v) {
        var formattedDate = "";
        if(v.date) {
            formattedDate = v.date.format(localize("email_templates.common.full_date_format"));
            formattedDate = formattedDate + "<br>";
            formattedDate = formattedDate + v.date.tz();
        }
        else {
            formattedDate = v.text;
        }

        $dataEntryValue.append($("<div>").html(formattedDate));
    });
    $dataEntry.append($dataEntryName);
    $dataEntry.append($dataEntryValue);
    $("#selected-suggested-dates").append($dataEntry);

    $("#selected-suggested-dates").append("<br/><br/>");
};

window.classificationForms.askAvailabilitiesForm.prototype.appendDetectedDateRow = function(params) {

    var $detectedDate = $("<div>").addClass("detected-date");
    if(params.text) {
        var $detectedDateText = $("<div>").addClass("detected-date-text").html(params.text);
        $detectedDate.append($detectedDateText);
    }


    var mStartDate = params.startDate;
    var $detectedDateDate = $("<input>").addClass("detected-date-date").val(mStartDate.format("dddd D MMMM YYYY"));
    $detectedDate.append($detectedDateDate);

    var $detectedDateRealDate = $("<input>").addClass("detected-date-real-date").val(mStartDate.format("YYYY-MM-DD"));
    $detectedDate.append($detectedDateRealDate);

    var $detectedDateTime = $("<input>").addClass("detected-date-time").val(mStartDate.format("HH:mm"));
    $detectedDate.append($detectedDateTime);

    var timezone = mStartDate.tz();
    if(!timezone) {
        timezone = window.threadComputedData.timezone;
    }
    var $detectedDateTimezone = $("<input>").addClass("detected-date-timezone").val(timezone);
    $detectedDate.append($detectedDateTimezone);

    var $detectedDateRemoveButton = $("<div>").addClass("detected-date-remove-button").html("x");
    $detectedDate.append($detectedDateRemoveButton);



    $(".detected-dates").append($detectedDate);

    $(".detected-dates .detected-date:last .detected-date-time").timepicker({timeFormat: 'H:i'});
    $(".detected-dates .detected-date:last .detected-date-date").each(function() {
        var $input = $(this);
        $input.datepicker({
            dateFormat: 'DD d MM yy',
            altField: $(this).siblings(".detected-date-real-date"),
            altFormat : 'yy-mm-dd'
        });
    });
    $(".detected-dates .detected-date:last .detected-date-timezone").timezonePicker();
};

window.classificationForms.askAvailabilitiesForm.prototype.changeAlreadySuggestedDateCheckbox = function() {
    $checkedCheckboxes = $(".already-suggested-dates-container .already-suggested-date input[type=checkbox]:checked");
    if($checkedCheckboxes.length == 0) {
        $("#none-of-already-suggested-dates").removeAttr("disabled");
        $("#submit-these-already-suggested-dates").attr("disabled", "disabled");
    }
    else {
        $("#none-of-already-suggested-dates").attr("disabled", "disabled");
        $("#submit-these-already-suggested-dates").removeAttr("disabled");
    }
};

window.classificationForms.askAvailabilitiesForm.prototype.onceAgreementAndAttendeesNoticedDone = function() {
    var askAvailabilitiesForm = this;
    askAvailabilitiesForm.checkAlreadySuggestedDates();
};

window.classificationForms.askAvailabilitiesForm.prototype.onceAgreementAndAttendeesNoticedDoneRevert = function() {
    $(".messages-thread-info-panel .dates-identification-panel").hide();
};