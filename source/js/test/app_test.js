define([
    'jquery', 
    'underscore',
    'backbone',
    'amplify_core',
    'amplify_store'
], function($, _, Backbone, amplify){
    return {
        init: function(){
            console.log($);
            console.log(_);
            console.log(Backbone);
            console.log(amplify);

            var test = _.map(['a','b','c'], function(letter){
              return letter + "-arity";
            })

            $('#target').html(test.join(', '));
        }
    };
});