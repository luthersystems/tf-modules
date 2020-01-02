'use strict';

const AWS = require('aws-sdk');
const url = require('url');
const https = require('https');
const zlib = require('zlib');

const slackChannel = process.env['slackChannel'];
const minSeverityLevel = process.env['minSeverityLevel']; // LOW, MED
const webHookUrlSecretId = process.env['webHookUrlSecretId'];
const secretsManagerRegion = process.env['webHookUrlSecretRegion'];
const secretsManager = new AWS.SecretsManager({
    region: secretsManagerRegion
});

// These words in a log entry will trigger a red color in Slack
const DANGER_MESSAGES = ["error", "exception", "fatal"];

// These words in a log entry will trigger a yellow color in Slack
const WARNING_MESSAGES = ["warn"];


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

function getSeverityLevel(message) {
    const lowerMessage = message.toLowerCase();
    let severity = "Low";
    for (let dangerMessagesItem of DANGER_MESSAGES) {
        if (lowerMessage.indexOf(dangerMessagesItem) != -1) {
            severity = "High";
            break;
        }
    }
    if (severity == "Low") {
        for (let warningMessagesItem of WARNING_MESSAGES) {
            if (lowerMessage.indexOf(warningMessagesItem) != -1) {
                severity = "Medium";
                break;
            }
        }
    }
    return severity;
}

function processEvents(events, callback) {
    console.log(JSON.stringify(events));

    const messages = events.map( (e) => e.message).join('\n');
    const logGroup = events[0] && events[0].logGroupName || 'Missing logGroup';
    const logStream = events[0] && events[0].logStreamName || 'Missing logStream';

    let color = '#7CD197';
    let severity = getSeverityLevel(messages);

    if (severity == "Low") {
        if (minSeverityLevel !== 'LOW') {
            console.info("Ignoring low severity event");
            callback(null);
            return;
        }
    } else if (severity == "Medium") {
        if (minSeverityLevel !== 'MED') {
            console.info("ignoring medium severity event");
            callback(null);
            return;
        }
        color = '#e2d43b';
    } else {
        color = '#ad0614';
    }

    const attachment = [{
        "text": `${messages}`,
        "fields": [
            {"title": "Severity","value": `${severity}`, "short": true}
        ],
        "color": color
    }];

    const slackMessage = {
        channel: slackChannel,
        text: '*' + logGroup + '* - ' + logStream,
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

function parseEvent(logEvent, logGroupName, logStreamName) {
    return {
        message: logEvent.message,
        logGroupName: logGroupName,
        logStreamName: logStreamName,
        timestamp: new Date(logEvent.timestamp).toISOString()
    };
}

exports.handler = (event, context, callback) => {
    const payload = new Buffer(event.awslogs.data, 'base64');
    zlib.gunzip(payload, (error, result) => {
        if (error) {
            console.error("Error unzipping event", error);
            callback(null);
            return;
        }
        const resultParsed = JSON.parse(result.toString('ascii'));
        const parsedEvents = resultParsed.logEvents.map( (logEvent) => 
            parseEvent(logEvent, resultParsed.logGroup, resultParsed.logStream)
        );
        processEvents(parsedEvents, callback);
    });
};
