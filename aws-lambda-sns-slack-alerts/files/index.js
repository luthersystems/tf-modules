'use strict';

const AWS = require('aws-sdk');
const url = require('url');
const https = require('https');
const zlib = require('zlib');

const slackChannel = process.env['slackChannel'];
const webHookUrlSecretId = process.env['webHookUrlSecretId'];
const secretsManagerRegion = process.env['webHookUrlSecretRegion'];
const secretsManager = new AWS.SecretsManager({
    region: secretsManagerRegion
});

function postMessage(message, callback) {
    const body = JSON.stringify(message);
    secretsManager.getSecretValue({SecretId: webHookUrlSecretId}, (err, data) => {
        if (err) {
            console.error("Error retrieving secret", err);
            callback({});
            return;
        }

        const webHookUrl = data.SecretString;
        const options = url.parse(webHookUrl);
        options.method = 'POST';
        options.headers = {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(body)
        };
        const postReq = https.request(options, (res) => {
            const chunks = [];
            res.setEncoding('utf8');
            res.on('data', (chunk) => chunks.push(chunk));
            res.on('end', () => {
                if (callback) {
                    callback({
                        body: chunks.join(''),
                        statusCode: res.statusCode,
                        statusMessage: res.statusMessage
                    });
                }
            });
            return res;
        });

        postReq.write(body);
        postReq.end();
    });
}

function processEvent(subject, message, callback) {
    const attachment = [{
        "text": message
    }];

    const slackMessage = {
        channel: slackChannel,
        text: subject,
        attachments : attachment
    };

    postMessage(slackMessage, (response) => {
        if (response.statusCode < 400) {
            console.info('Message posted successfully');
            callback(null);
        } else if (response.statusCode < 500) {
            console.error(`Error posting message to Slack API: ${response.statusCode} - ${response.statusMessage}`);
            callback(null);
        } else {
            callback(`Server error when processing message: ${response.statusCode} - ${response.statusMessage}`);
        }
    });
}

exports.handler = (event, context, callback) => {
    console.log('Received event:', JSON.stringify(event, null, 4));
    const record = event.Records[0].Sns;
    processEvent(record.Subject, record.Message, callback);
};
