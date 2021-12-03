const functions = require("firebase-functions");
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

exports.pushConfig = functions.remoteConfig.onUpdate(metadata => {
    const payload = {
        data: {
            feature_flags_status: 'STALE'
        }
    };

    const options = {
        content_available: true
    };

    // Use the Admin SDK to send the ping via FCM.
    return admin
        .messaging()
        .sendToTopic('feature_flags', payload, options)
        .then(response => {
            console.log(response);
        
            return null;
        });
});

