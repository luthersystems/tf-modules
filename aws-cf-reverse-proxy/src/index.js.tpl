function handler(event) {
    var newurl = `${REDIRECT_URL}`
    var response = {
        statusCode: ${REDIRECT_HTTP_CODE},
        statusDescription: 'Found',
        headers:
            { "location": { "value": newurl } }
        }

    return response;
}
