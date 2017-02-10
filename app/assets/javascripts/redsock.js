var RedSock = function (url, member_data) {
    this.ws = new WebSocket(url);
    this.bounds = [];

    this.member_id = member_data.member_id;
    this.member_name = member_data.member_name;
    this.member_email = member_data.member_email;

    var redsock = this;
    redsock.ws.onmessage = function (evt) {
        var json = JSON.parse(evt.data);
        //console.log("New message", json);
        redsock.processBounds(json);
    };
};



RedSock.prototype.subscribeToChannel = function (channelName, data) {
    var redsock = this;
    if(!data) {
        data = {};
    }
    redsock.sendData(channelName, "subscribe", null, {
        identifier: redsock.member_id,
        name: redsock.member_name,
        email: redsock.member_email,
        maxConnections: data.maxConnections
    })
};

RedSock.prototype.unsubscribeFromChannel = function (channelName, data) {
    this.sendData(channelName, "unsubscribe", null, null)
};

RedSock.prototype.unlockChannel = function (channelName) {
    this.sendData(channelName, "unlock", null, {
        identifier: redsock.member_id,
        name: redsock.member_name,
        email: redsock.member_email
    })
};

RedSock.prototype.sendData = function (channel, action, message, data) {
    var redsock = this;
    if(redsock.ws.readyState === 1) {
        redsock.ws.send(JSON.stringify({
            channel: channel,
            message: message,
            action: action,
            data: data
        }));
    }
    else {
        setTimeout(function() {
            redsock.sendData(channel, action, message, data)
        }, 5);
    }

};

RedSock.prototype.sendMessage = function(channel, message, data)
{
    this.sendData(channel, "message", message, data);
};

RedSock.prototype.processBounds = function(json) {
    var redsock = this;
    var channelName = json.channel;
    if(channelName in redsock.bounds) {
        var callback = redsock.bounds[channelName][json.message];
        if(callback) {
            callback(json.data);
        }
    }
};

RedSock.prototype.bindMessage = function(channel, message, callback) {
    var redsock = this;
    if(!redsock.bounds[channel]) {
        redsock.bounds[channel] = {};
    }
    redsock.bounds[channel][message] = callback;
};