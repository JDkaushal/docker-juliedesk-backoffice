class RedsockClient {
    constructor(params) {
        this.ws = new WebSocket(params.url);
        this.bounds = [];

        this.member_id = params.member_id;
        this.member_name = params.member_name;
        this.member_email = params.member_email;

        let self = this;
        this.ws.onmessage = function (evt) {
            var json = JSON.parse(evt.data);
            self.processBounds(json);
        };
    }


    sendData(channel, action, message, data) {
        let self = this;
        if(this.ws.readyState === 1) {
            this.ws.send(JSON.stringify({
                channel: channel,
                message: message,
                action: action,
                data: data
            }));
        }
        else {
            setTimeout(() => self.sendData(channel, action, message, data), 5);
        }
    };


    subscribeToChannel(channelName, options={}) {
        this.sendData(channelName, "subscribe", null, {
            identifier: this.member_id,
            name: this.member_name,
            email: this.member_email,
            maxConnections: options.maxConnections
        });
    };


    unsubscribeFromChannel(channelName) {
        this.sendData(channelName, "unsubscribe", null, null)
    };


    unlockChannel(channelName) {
        this.sendData(channelName, "unlock", null, {
            identifier: this.member_id,
            name: this.member_name,
            email: this.member_email
        })
    };


    sendMessage(channel, message, data) {
        this.sendData(channel, "message", message, data);
    };

    processBounds(json) {
        let channelName = json.channel;
        if(channelName in this.bounds) {
            let callback = this.bounds[channelName][json.message];
            if(callback) {
                callback(json.data);
            }
        }
    };

    bindMessage(channel, message, callback) {
        if(!this.bounds[channel]) {
            this.bounds[channel] = {};
        }
        this.bounds[channel][message] = callback;
    };

}

export default RedsockClient;