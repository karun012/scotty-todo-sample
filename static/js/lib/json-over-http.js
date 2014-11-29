define(['jquery'], function ($) {
    'use strict';
    return function (options) {
        var uri, method, body, client, deferred, handler;
        uri = options.uri;
        method = options.method;
        body = JSON.stringify(options.body);
        deferred = $.Deferred();
        $.ajax({
            url: uri, 
            type: method, 
            data: body
        }).done(function (data, textStatus, jqXHR) {
            var createdAt;
            if (jqXHR.getResponseHeader("Location")) {
                createdAt = jqXHR.getResponseHeader("Location");
            }
            deferred.resolve(data, createdAt);
        });
        return deferred.promise();
    };
});
