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
      domReady   : 'lib/domReady'
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
                "amplify"
            ]
        },
        {
            name : "modules/SearchModule",
            exclude: [
                "jquery",
                "backbone",
                "mustache",
                "amplify"
            ]
        }
    ]
})