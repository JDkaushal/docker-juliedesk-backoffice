var ErrorManager = function(endpoint, credentials) {
    this.endpoint = endpoint;
    this.credentials = credentials || {};
    this.errors = [];
};

ErrorManager.prototype.init = function() {
  var errorManager = this;
  window.onerror = function(msg, url, line) {
      var data = {};
      data.operatorId = $('body').data('operatorId');
      data.occurredAt = new Date().toISOString();

      var error = new Error(msg, url, line, data);
      errorManager.errors.push(error);
      errorManager.sendError(error)
  }
};

ErrorManager.prototype.sendError = function(error) {
    var data = error.data;
    data.url = error.url;
    data.line = error.line;
    data.message = error.message;

    this.sendData(data, "error");
};

ErrorManager.prototype.sendInfo = function(data, callback) {
    if(callback)
        this.sendData(data, "info", callback);
    else
        this.sendData(data, "info");
};

ErrorManager.prototype.sendData = function(data, level, callback) {
    var errorManager = this;
    data.level = level || "info";
    data.application = "backoffice";
    data.referer = window.location.href;

    $.ajax({
        url: this.endpoint,
        type: "POST",
        tryCount: 0,
        retryLimit: 2,
        data: { data: data } ,
        beforeSend: function (xhr) {
            xhr.setRequestHeader("Authorization", errorManager.credentials.auth);
        },
        success: callback || function() { return true; }
    });
};

var Error = function(msg, url, line, data) {
    this.message = msg;
    this.url = url;
    this.line = line;
    this.data = data || {};
};
