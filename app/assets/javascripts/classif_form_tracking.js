$(document).ready(function() {

    $('.classic-info-panel').click(function(e) {
        var currentTrackingEvent = $(e.target).data('tracking-event');

        if(currentTrackingEvent) {
            trackActionV2(currentTrackingEvent, {ux_element: 'form'});
        }
    });
});