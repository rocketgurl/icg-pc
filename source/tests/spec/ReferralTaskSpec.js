define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/Search/SearchContextCollection",
  "modules/Policy/PolicyModel",
  "modules/ReferralQueue/ReferralTaskCollection",
  "modules/ReferralQueue/ReferralQueueView",
  "amplify",
  "loader"], 
  function(
    $, 
    _, 
    WorkspaceController, 
    SearchContextCollection,
    PolicyModel,
    ReferralTaskCollection,
    ReferralQueueView,
    amplify, 
    CanvasLoader
) {


// REFERRAL QUEUE COLLECTION
describe('ReferralTaskCollection', function () {

  // media=application/xml&page=1&perPage=50&status=New,Pending

  var settings = {
    pxcentral: '/pxcentral/api/rest/v1/tasks/',
    digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
  }

  var tasks = new ReferralTaskCollection();
  tasks.url = settings.pxcentral;
  tasks.digest = settings.digest;

  var ajax_count = 0;

  beforeEach(function(){
    if (ajax_count < 1) {
      var callback = jasmine.createSpy();
      tasks.getReferrals({ OwningUnderwriter : '' }, callback);
      waitsFor(function() {
        ajax_count++;
        return callback.callCount > 0;
      }, "Timeout BOOM!", 10000)
    }
  })

  it ('is an object', function () {
    expect(tasks).toEqual(jasmine.any(Object));
  });

  it ('has a URL', function () {
    runs(function(){
      console.log(tasks);
      expect(tasks.url).toBe('/pxcentral/api/rest/v1/tasks/');
    });
  });

  it ('has a PerPage count', function () {
    runs(function(){
      expect(tasks.perPage).toBe('25');
    });
  });

  it ('has a totalItems count', function () {
    runs(function(){
      expect(tasks.totalItems).toBe('1299');
    });
  });

  it ('knows what page it is on (1)', function () {
    runs(function(){
      expect(tasks.page).toBe('1');
    });
  });

  it ('knows what its search criteria is', function () {
    runs(function(){
      expect(tasks.criteria).toBe('isAdmin=false&isPolicyManager=false');
    });
  });

  it ('has a default collection of 25 models', function () {
    runs(function(){
      expect(tasks.length).toBe(25);
      expect(tasks.models).toEqual(jasmine.any(Array));
      expect(tasks.models.length).toEqual(25);
    });
  });

  it ('can limit collection to 50 tasks', function () {
    var callback = jasmine.createSpy();
    tasks.getReferrals({ 'perPage' : 50, 'OwningUnderwriter' : '' }, callback);
    waitsFor(function() {
      return callback.callCount > 0;
    }, "Timeout BOOM!", 10000)
    runs(function(){
      expect(tasks.length).toBe(50);
      expect(tasks.models).toEqual(jasmine.any(Array));
      expect(tasks.models.length).toEqual(50);
      expect(tasks.perPage).toBe('50');
    });
  });

  it ('can get page number 4 of result set', function () {
    var callback = jasmine.createSpy();
    tasks.getReferrals({ 'page' : 4 }, callback);
    waitsFor(function() {
      return callback.callCount > 0;
    }, "Timeout BOOM!", 10000)
    runs(function(){
      expect(tasks.page).toBe('4');
    });
  });

  it ('can get just my referrals (darren.newton@arc90.com - 0)', function () {
    var callback = jasmine.createSpy();
    tasks.getReferrals({ 'OwningUnderwriter' : 'darren.newton@arc90.com' }, callback);
    waitsFor(function() {
      return callback.callCount > 0;
    }, "Timeout BOOM!", 10000)
    runs(function(){
      expect(tasks.length).toBe(0);
      expect(tasks.criteria).toBe('owningUnderwriter=darren.newton@arc90.com&isAdmin=false&isPolicyManager=false');
    });
  });

    describe('ReferralTaskModel', function () {
      var settings = {
        pxcentral: '/pxcentral/api/rest/v1/tasks/',
        digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
      }

      var tasks2 = new ReferralTaskCollection();
      tasks2.url = settings.pxcentral;
      tasks2.digest = settings.digest;

      var ajax_count = 0;
      var callback = jasmine.createSpy();

      beforeEach(function(){
        if (ajax_count < 1) {
          var callback = jasmine.createSpy();
          tasks2.getReferrals({ 'perPage' : 50, 'page' : 1, 'status' : 'New,Pending', 'OwningUnderwriter' : '' }, callback);
          waitsFor(function() {
            ajax_count++;
            return callback.callCount > 0;
          }, "Timeout BOOM!", 10000)
        }
      })

      it('is an object', function(){
        expect(tasks2.models[0]).toEqual(jasmine.any(Object));
        console.log(tasks2);
      })

      it('is assigned to someone', function(){
        var count = [0,11,42,32,24,15,6,7];
        _.each(count, function(num){
          expect(tasks2.models[num].getAssignedTo()).toEqual("Underwriter");
        });
      })

      it('has an Owning Agent', function(){
        var count = [0,1,23,31,13,25,48,17];
        var names = [
          'cru4t@cru360.com',
          'cru4t@cru360.com',
          'cru4t@cru360.com',
          'geicova1',
          'cru4t@cru360.com',
          'cru4t@cru360.com',
          '',
          'cru4t@cru360.com'
        ]
        _.each(count, function(num){
          expect(tasks2.models[num].getOwningAgent()).toBe(names[_.indexOf(count, num)]);
        });
      })

      it('is returns an object for its view', function(){
        expect(tasks2.models[0].getViewData()).toEqual(jasmine.any(Object));
        var keys = [
          'relatedQuoteId',
          'insuredLastName',
          'status',
          'Type',
          'lastUpdated',
          'SubmittedBy'
        ]
        _.each(keys, function(key){
          expect(_.has(tasks2.models[0].getViewData(), key)).toEqual(true);
        })
        console.log(tasks2.models[0].getViewData());
      })

    });

});

});