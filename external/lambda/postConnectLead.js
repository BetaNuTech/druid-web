// https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/postConnectLead

const https = require('https');
const querystring = require('querystring');

exports.handler = (event, context) => {

	let firstName = event["Details"]["ContactData"]["Attributes"]["callerFirstName"];
	let lastName = event["Details"]["ContactData"]["Attributes"]["callerLastName"];
	let callerID = event["Details"]["ContactData"]["Attributes"]["callerCallerID"];

	if (firstName == '' || firstName == undefined) {
		firstName = callerID;
		lastName = ''
	}

	const callerData = {
		DialedNumber: event["Details"]["ContactData"]["SystemEndpoint"]["Address"],
		CallerNumber: event["Details"]["ContactData"]["Attributes"]["callerNumber"],
		CallerID: callerID,
		PropertyName: event["Details"]["ContactData"]["Attributes"]["propertyName"],
		PropertyId: event["Details"]["ContactData"]["Attributes"]["propertyId"],
		FirstName: firstName,
		LastName: lastName,
		Referrer: event["Details"]["ContactData"]["Attributes"]["propertyCallReferrer"],
		SubmittedAt: Date(Date.now()).toString()
	};

	if (process.env.SLACK_ENABLED == 'true') {
		// Post data to Slack
		const slack_payload = JSON.stringify({
			text: `BlueConnect Incoming call (${callerData['Referrer']}) for ${callerData['PropertyName']} -- NAME: ${callerData['FirstName']} ${callerData['LastName']} -- PHONE: ${callerData['CallerNumber']} -- Wants ${callerData['ApartmentSize']} bedrooms -- SUBMITTED: ${callerData['SubmittedAt']}`
		});

		const slackWebhookPath = process.env.SLACK_WEBHOOK_PATH;

		const slack_options = {
			hostname: "hooks.slack.com",
			method: "POST",
			path: slackWebhookPath
		};

		var errorMessage = "";
		var statusCode = 200;

		const slack_req = https.request(slack_options,
			(res) => {
				res.on("data", (data) => {
					errorMessage = JSON.stringify(data);
					statusCode = 200;
				})
			})

			slack_req.on("error", (error) => {
				errorMessage = JSON.stringify(error);
				statusCode = 500;
			});

			slack_req.write(slack_payload);
			slack_req.end();
	}

	if (process.env.BLUESKY_ENABLED == 'true') {
		// Post Data to Bluesky

		let lead_notes = "Incoming BlueConnect Lead call to " + callerData["DialedNumber"] + " at " + callerData["SubmittedAt"];

		let bluesky_data = JSON.stringify({
			"property_id": callerData["PropertyId"],
			"first_name": callerData["FirstName"],
			"last_name": callerData["LastName"],
			"phone1": callerData["CallerNumber"],
			"referral": callerData["Referrer"],
			"notes": lead_notes
		});

		let bluesky_options = {
			hostname: process.env.BLUESKY_HOST,
			method: "POST",
			path: `/api/v1/leads.json?token=${process.env.TOKEN}`,
			headers: {
				'Content-Type': 'application/json',
				'Content-Length': Buffer.byteLength(bluesky_data)
			}

		}

		console.log("Posting data to Bluesky: " + bluesky_data);

		const bluesky_req = https.request(bluesky_options,
			(res) => {
				res.setEncoding('utf8');
				res.on("data", (data) => {
					errorMessage = JSON.stringify(data);
					console.log(errorMessage);
					statusCode = 200;
				})
			})

			bluesky_req.on("error", (error) => {
				errorMessage = JSON.stringify(error);
				console.log("error")
				console.log(errorMessage);
				statusCode = 500;
			});

			bluesky_req.end(bluesky_data);
	}
};

/*
Environment Variables
====
TOKEN  (string)
BLUESKY_HOST (string: FQDN)
BLUESKY_ENABLED (string: true|false)
SLACK_ENABLED (string: true|false)
SLACK_WEBHOOK_PATH (string: path without domain)
===
*/
