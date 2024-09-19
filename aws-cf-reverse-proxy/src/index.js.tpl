function handler(event) {
    var request = event.request;
    var newUrl = '${REDIRECT_URL}' + request.uri;
    if (request.querystring) {
        newUrl += '?' + request.querystring;
    }
    var response = {
        statusCode: ${REDIRECT_HTTP_CODE},
        statusDescription: 'Found',
        headers:
            { "location": { "value": newurl } }
        }

    return response;
}
