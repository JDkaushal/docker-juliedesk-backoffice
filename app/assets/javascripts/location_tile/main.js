function LocationTile($selector, params) {
    this.$selector = $selector;
    this.locationText = params.location_text;
    this.locationNature = params.location_nature;

    var locationTile = this;

    locationTile.setLocationLabel();
    locationTile.render();
    locationTile.initActions();
}

LocationTile.prototype.setLocationLabel = function() {
    var locationTile = this;
    locationTile.locationLabel = null;
    if(locationTile.locationNature) {
        var foundAddressHash =_.find(window.threadAccount.addresses, function(addressHash) {
            return addressHash.kind == locationTile.locationNature;
        }) ;
        if(foundAddressHash) {
            locationTile.locationLabel = foundAddressHash.label;
        }
    }
};
LocationTile.prototype.render = function() {
    var locationTile = this;

    locationTile.$selector.html(HandlebarsTemplates['location_tile/main']());
    locationTile.$selector.find(".from-ai-text-text").html(locationTile.locationText);
    locationTile.$selector.find(".from-ai-interpreted-location").val(locationTile.locationLabel);
};

LocationTile.prototype.initActions = function() {
    var locationTile = this;

    locationTile.$selector.find(".from-ai-button.accept").click(function (e) {
        if(locationTile.locationLabel) {
            $("#location_nature").val(locationTile.locationLabel);
            setAddressValues();
        }
        else {
            $("#location_nature").val("Custom");
            $("#location").val(locationTile.locationText);
        }

        locationTile.$selector.remove();
    });

    locationTile.$selector.find(".from-ai-button.reject").click(function (e) {
        locationTile.$selector.remove();
    });
};

