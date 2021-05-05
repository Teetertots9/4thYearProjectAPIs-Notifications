var AWS = require('aws-sdk');
// Set the region 
AWS.config.update({region: 'eu-west-1'});

// Create createTemplate params
var params = {
  Template: { 
    TemplateName: 'new-event', /* required */
    HtmlPart: "<p>Event Info:<br> Artist: {{artist}}<br>Venue: {{venue}}<br>Date & Time: {{datetime}}</p>",
    SubjectPart: 'An Artist/Venue you follow is holding a new event'
  }
};

// Create the promise and SES service object
var templatePromise = new AWS.SES({apiVersion: '2010-12-01'}).createTemplate(params).promise();

// Handle promise's fulfilled/rejected states
templatePromise.then(
  function(data) {
    console.log(data);
  }).catch(
    function(err) {
    console.error(err, err.stack);
  });