// https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/getBlueskyPropertyInfoSTAGING

const https = require('https');
exports.handler = async(event) => {
  let hostname = process.env.BLUESKY_HOST;
  let token = process.env.TOKEN;
  let apiPath = '/api/v1/property_info.json'
  let incomingNumber = event["Details"]["ContactData"]["SystemEndpoint"]["Address"];
  let apiUrl = `https://${hostname}${apiPath}?token=${token}&number=${incomingNumber}`;
  let dataString = '';

  const response = await new Promise((resolve, reject) => {
    const req = https.get(apiUrl, function(res) {
      res.on('data', chunk => {
        dataString += chunk;
      });
      res.on('end', () => {
        let data = JSON.parse(dataString);
        data["main_number"] = "+1" + data["main_number"];
        data["maintenance_number"] = "+1" + data["maintenance_number"];
        resolve(data);
      });
    });

    req.on('error', (e) => {
      reject({
        statusCode: 500,
        body: 'Something went wrong!'
      });
    });
  });

  return response;
};

/*
Environment Variables
====
TOKEN
BLUESKY_HOST
===
*/


