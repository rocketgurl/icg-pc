({
    appDir: "../",
    baseUrl: "js",
    dir: "../../build",
    paths : {
      jquery     : 'lib/jquery-1.7.2.min',
      underscore : 'lib/underscore-min',
      backbone   : 'lib/backbone-min',
      amplify    : 'lib/amplify',
      mustache   : 'lib/requirejs.mustache',
      base64     : 'lib/base64',
      cookie     : 'lib/jquery.cookie',
      xml2json   : 'lib/jquery.xml2json',
      text       : 'lib/text',
      domReady   : 'lib/domReady',
      json       : 'lib/json2',
      loader     : 'lib/heartcode-canvasloader-min'
    },
    modules: [
        {
            name: "main"
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
                "underscore"
            ]
        },
        {
            name : "modules/TestModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify",
                "underscore"
            ]
        }
    ]
})