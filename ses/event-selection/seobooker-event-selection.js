var AWS = require('aws-sdk');
// Set the region 
AWS.config.update({region: 'eu-west-1'});

// Create createTemplate params
var params = {
  Template: { 
    TemplateName: 'event-selection', /* required */
    HtmlPart: "<p>You have been selected for the event at:<br>{{venue}} at {{datetime}}</p>",
    SubjectPart: 'You have been selected for an event you applied for'
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