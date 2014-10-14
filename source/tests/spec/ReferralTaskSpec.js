define([
  'xml2json',
  'modules/ReferralQueue/ReferralTaskCollection'
], function (xml2json, ReferralTaskCollection) {

  describe('ReferralTaskCollection', function () {

    // media=application/xml&page=1&perPage=50&status=New,Pending

    var settings = {
      url     : '/base/tests/mocks/referral_queue/tasks.xml',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    }

    var async = new AsyncSpec(this);
    var tasks = new ReferralTaskCollection();
    var ReferralTaskModel = tasks.model;
    
    tasks.url = settings.url;
    tasks.digest = settings.digest;

    async.beforeEach(function (done) {
      tasks.getReferrals();
      tasks.on('reset', function () { done(); });
    });

    it ('should be an instance of Backbone.Collection', function () {
      expect(tasks).toEqual(jasmine.any(Backbone.Collection));
    });

    it ('should fetch a collection of ReferralTaskModels', function () {
      tasks.each(function (task) {
        expect(task).toEqual(jasmine.any(ReferralTaskModel));
      });
    });

    // it ('has a URL', function () {
    //   runs(function(){
    //     console.log(tasks);
    //     expect(tasks.url).toBe('/pxcentral/api/rest/v1/tasks/');
    //   });
    // });

    // it ('has a PerPage count', function () {
    //   runs(function(){
    //     expect(tasks.perPage).toBe('25');
    //   });
    // });

    // it ('has a totalItems count', function () {
    //   runs(function(){
    //     expect(tasks.totalItems).toBe('298');
    //   });
    // });

    // it ('knows what page it is on (1)', function () {
    //   runs(function(){
    //     expect(tasks.page).toBe('1');
    //   });
    // });

    // it ('knows what its search criteria is', function () {
    //   runs(function(){
    //     expect(tasks.criteria).toBe('status=new,pending&isAdmin=true&isPolicyManager=false');
    //   });
    // });

    // it ('has a default collection of 25 models', function () {
    //   runs(function(){
    //     expect(tasks.length).toBe(25);
    //     expect(tasks.models).toEqual(jasmine.any(Array));
    //     expect(tasks.models.length).toEqual(25);
    //   });
    // });

    // it ('can limit collection to 50 tasks', function () {
    //   var callback = jasmine.createSpy();
    //   tasks.getReferrals({ 'perPage' : 50, 'OwningUnderwriter' : '' }, callback);
    //   waitsFor(function() {
    //     return callback.callCount > 0;
    //   }, "Timeout BOOM!", 10000)
    //   runs(function(){
    //     expect(tasks.length).toBe(50);
    //     expect(tasks.models).toEqual(jasmine.any(Array));
    //     expect(tasks.models.length).toEqual(50);
    //     expect(tasks.perPage).toBe('50');
    //   });
    // });

    // it ('can get page number 4 of result set', function () {
    //   var callback = jasmine.createSpy();
    //   tasks.getReferrals({ 'page' : 4 }, callback);
    //   waitsFor(function() {
    //     return callback.callCount > 0;
    //   }, "Timeout BOOM!", 10000)
    //   runs(function(){
    //     expect(tasks.page).toBe('4');
    //   });
    // });

    // it ('can get just my referrals (darren.newton@arc90.com - 0)', function () {
    //   var callback = jasmine.createSpy();
    //   tasks.getReferrals({ 'OwningUnderwriter' : 'darren.newton@arc90.com' }, callback);
    //   waitsFor(function() {
    //     return callback.callCount > 0;
    //   }, "Timeout BOOM!", 10000)
    //   runs(function(){
    //     console.log(['tasks.length', tasks.length])
    //     expect(tasks.length).toBe(0);
    //     expect(tasks.criteria).toBe('owningUnderwriter=darren.newton@arc90.com&isAdmin=false&isPolicyManager=false');
    //   });
    // });

    //   describe('ReferralTaskModel', function () {
    //     var settings = {
    //       pxcentral: '/pxcentral/api/rest/v1/tasks/',
    //       digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    //     }

    //     var tasks2 = new ReferralTaskCollection();
    //     tasks2.url = settings.pxcentral;
    //     tasks2.digest = settings.digest;

    //     var ajax_count = 0;
    //     var callback = jasmine.createSpy();

    //     beforeEach(function(){
    //       if (ajax_count < 1) {
    //         var callback = jasmine.createSpy();
    //         tasks2.getReferrals({ 'perPage' : 50, 'page' : 1, 'status' : 'New,Pending', 'OwningUnderwriter' : '' }, callback);
    //         waitsFor(function() {
    //           ajax_count++;
    //           return callback.callCount > 0;
    //         }, "Timeout BOOM!", 10000)
    //       }
    //     })

    //     it('is an object', function(){
    //       expect(tasks2.models[0]).toEqual(jasmine.any(Object));
    //       console.log(tasks2);
    //     })

    //     it('is assigned to someone', function(){
    //       var count = [0,11,42,32,24,15,6,7];
    //       var names = [
    //         'e01625j',
    //         'rachel@thepaceagency.com',
    //         'sslifer1',
    //         'e56461a',
    //         'e25808a',
    //         'jessicarobson@allstate.com',
    //         'e41848a',
    //         'e61731c'
    //       ]
    //       _.each(count, function(num, index){
    //         expect(tasks2.models[num].getAssignedTo()).toEqual(names[index]);
    //       });
    //     })

    //     it('has an Owning Agent', function(){
    //       var count = [0,1,23,31,13,25,48,17];
    //       var names = [
    //         'e01625j',
    //         'sedenfield@aiasc.com',
    //         'e01691j',
    //         'e65496a',
    //         'e40220n',
    //         'e72247d',
    //         'maullc@nationwide.com',
    //         'TracyKimble'
    //       ]
    //       _.each(count, function(num, index){
    //         expect(tasks2.models[num].getOwningAgent()).toBe(names[index]);
    //       });
    //     })

    //     it('is returns an object for its view', function(){
    //       expect(tasks2.models[0].getViewData()).toEqual(jasmine.any(Object));
    //       var keys = [
    //         'relatedQuoteId',
    //         'insuredLastName',
    //         'status',
    //         'Type',
    //         'lastUpdated',
    //         'SubmittedBy'
    //       ]
    //       _.each(keys, function(key){
    //         expect(_.has(tasks2.models[0].getViewData(), key)).toEqual(true);
    //       })
    //       console.log(tasks2.models[0].getViewData());
    //     })

    //   });

  });

});