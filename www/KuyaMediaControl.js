var cordova = require('cordova'),
    exec = require('cordova/exec'),
    PLUGIN = 'KuyaMediaControl';

exports.updateNowPlaying = function(props, update, success, error) { 
    cordova.exec( success, error, PLUGIN, "updateNowPlaying", [props, update] );
};
