define(['jquery'], function ($) {
    'use strict';
    return function (options) {
        var uri, method, body, client, deferred, handler;
        uri = options.uri;
        method = options.method;
        body = JSON.stringify(options.body);
        deferred = $.Deferred();
        handler = function () {
            var valueForDeferred;
            if (client.readyState === client.DONE) {
                if (client.response === '') {
                    valueForDeferred = {
                        status: client.status
                    };
                } else {
                    valueForDeferred = {
                        status: client.status,
                        body: JSON.parse(client.response)
                    };
                }
                deferred.resolve(valueForDeferred);
            }
        };

        client = new XMLHttpRequest();
        client.onreadystatechange = handler;
        client.open(method, uri);
        client.setRequestHeader('Content-Type', 'application/json; charset=utf-8');
        client.send(body);
        return deferred.promise();
    };
});
