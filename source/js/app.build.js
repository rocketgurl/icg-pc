({
    appDir: "../",
    baseUrl: "js",
    dir: "../../build",
    mainConfigFile: 'main.js',
    paths : {
      jquery     : 'lib/jquery-1.7.2.min',
      underscore : 'lib/underscore-min',
      backbone   : 'lib/backbone-min',
      amplify    : 'lib/amplify',
      mustache   : 'lib/requirejs.mustache',
      base64     : 'lib/base64',
      xml2json   : 'lib/jquery.xml2json',
      text       : 'lib/text',
      domReady   : 'lib/domReady',
      json       : 'lib/json2',
      loader     : 'lib/heartcode-canvasloader',
      swfobject  : 'lib/swfobject'
    },
    modules: [
        {
            name: "main"
            exclude: [
              "swfobject"
            ]
        },
        {
            name : "modules/PolicyModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore"
            ]
        },
        {
            name : "modules/SearchModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore",
                "swfobject"
            ]
        },
        {
            name : "modules/TestModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore",
                "swfobject"
            ]
        }
    ]
})