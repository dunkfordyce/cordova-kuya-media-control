var cordova_exec = require('cordova/exec'),
    PLUGIN = 'KuyaMediaControl';

console.log('exec', exec, 'cordova', cordova);

function exec(cmd, args) { 
    return $.Deferred(function(p) { 
        cordova_exec( p.resolve, p.reject, PLUGIN, cmd, args || []); 
    });
}

exports.updateNowPlaying = function(props, update) { 
    return exec("updateNowPlaying", [props, !!update]);
};

exports.load = function(src) { 
    return exec("load", [src]).then(function() { 
        cordova.fireDocumentEvent(PLUGIN+'_status', {status: 'loading', url: src});
    });
};

exports.play = function() { 
    return exec("play").then(function() { 
        cordova.fireDocumentEvent(PLUGIN+'_status', {status: 'playing'});
    });
};

exports.pause = function() { 
    return exec("pause").then(function() { 
        cordova.fireDocumentEvent(PLUGIN+'_status', {status: 'paused'});
    });
};  

exports.seek = function(p) { 
    return exec("seek", [p]).then(function() { 

    });
};

exports.duration = function() { 
    return exec("duration");
};

/*
document.addEventListener(PLUGIN+'_status', function(e) { 
    console.log('KM status', e.status);
}, false);

document.addEventListener(PLUGIN+'_loaded', function(e) { 
    console.log('KM loaded', JSON.stringify( e.ranges ));
}, false);

document.addEventListener(PLUGIN+'_seekable', function(e) { 
    console.log('KM seekable', JSON.stringify( e.ranges ));
}, false);

document.addEventListener(PLUGIN+'_progress', function(e) { 
    console.log('KM progress', e.time, '/', e.duration);
}, false);

document.addEventListener(PLUGIN+'_button', function(e) { 
    console.log('KM button', e.button, e.source);
}, false);

exports.test = function() { 
    var u='http://b243.j.dl2.fatdrop.co.uk/stream/200080/_/60732K1170328KEGQGnFlpq3VDjkXKguslwaVeWtLrdwgk/49191b2e40150bc79b12c66d01496dda';
    console.log('loading', u);
    console.promise_log(exports.load(u)).done(function() { 
        console.log('waiting for ready');
        document.addEventListener(PLUGIN+'_status', function(e) { 
            if( e.status == 'readyToPlay' ) { 
                console.log('got ready - playing for 5s');
                exports.play();
                window.setTimeout(function() { 
                    console.log('pausing');
                    exports.pause();
                    console.log('seeking to 150s');
                    exports.seek(150);
                    console.log('playing 2s');
                    exports.play();
                    window.setTimeout(function() { 
                        console.log('seeking back to 150s');
                        exports.seek(150);
                        window.setTimeout(function() { 
                            console.log('done test');
                            exports.pause();
                        });
                    }, 2000);
                }, 5000);
            }
        }, false);
    });
};
*/
