const os = require("os");

exports._envCredentials = function(nothing) {
  return function(just) {
    return function(onError, onSuccess) {
      if (
        process &&
        process.env &&
        process.env.AWS_ACCESS_KEY_ID &&
        process.env.AWS_SECRET_ACCESS_KEY
      ) {
        if (process.env.AWS_SESSION_TOKEN) {
          const credentials = {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
            sessionToken: just(process.env.AWS_SESSION_TOKEN)
          };
          onSuccess(credentials);
        } else {
          const credentials = {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
            sessionToken: nothing
          };
          onSuccess(credentials);
        }
      } else {
        onError(new Error("key/secret were not available on process.env"));
      }
    };
  };
};

exports.homedir = function() {
  return os.homedir;
};

