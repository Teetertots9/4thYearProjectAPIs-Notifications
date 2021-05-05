// Load the AWS SDK for Node.js
var AWS = require('aws-sdk');
// Set the region 
AWS.config.update({ region: process.env.region });
const logger = require('pino')({ name: 'Event Selection', level: 'info' });
// Create DynamoDB document client
const ses = new AWS.SES({ apiVersion: '2012-08-10' });
const CognitoISP = new AWS.CognitoIdentityServiceProvider();

const { userpool_id } = process.env;

const getCognitoUserDetails = async (username) => {
    const cognitoParams = {
        UserPoolId: userpool_id,
        Username: username
    };
    const userDetails = await CognitoISP.adminGetUser(cognitoParams).promise();

    return userDetails;
}

const getAttributeFromUserDetails = async (userDetails, targetAttribute) => {
    for (var i = 0; i < userDetails.UserAttributes.length; i++) {
        if (userDetails.UserAttributes[i]["Name"] === targetAttribute) return userDetails.UserAttributes[i]["Value"];
    }
}

const sendEmail = async (toEmail, templateData) => {
    try{
        let emailParams = {
            Source: "seobooker4@gmail.com",
            Template: "event-selection"
        }
        emailParams["Destination"] = { ToAddresses: [toEmail] };
        emailParams["TemplateData"] = templateData;
        logger.info("Email Params", emailParams);
        const sesResponse = await ses.sendTemplatedEmail(emailParams).promise();
        logger.info("SES Response", sesResponse);
        return sesResponse;
    } catch (error) {
        logger.error(error);
        throw error;
    }
}

exports.handler = async (event) => {
try{
    logger.info(event);
    const { body } = event;

    const { notificationEvent } = body;

    const templateData = JSON.stringify({
        venue: notificationEvent.venueName,
        datetime: notificationEvent.sortDate
    })

    const askerDetails = await getCognitoUserDetails(notificationEvent.artistId);
    const toEmail = await getAttributeFromUserDetails(askerDetails, "email");

    const emailResponse = await sendEmail(toEmail, templateData);

      logger.info(emailResponse);
      return emailResponse;
} catch (error) {
    logger.error(error);
}
};