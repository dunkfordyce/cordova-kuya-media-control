var cordova = require('cordova'),
    exec = require('cordova/exec'),
    PLUGIN = 'KuyaMediaControl';

exports.updateNowPlaying = function(args, success, error) { 
    cordova.exec( success, error, PLUGIN, "updateNowPlaying", [args] );
};
