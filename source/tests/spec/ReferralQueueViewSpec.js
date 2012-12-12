define([
  "jquery", 
  "underscore", 
  "modules/ReferralQueue/ReferralTaskCollection",
  "modules/ReferralQueue/ReferralQueueView",
  "amplify",
  "loader"], 
  function(
    $, 
    _, 
    ReferralTaskCollection,
    ReferralQueueView,
    amplify, 
    CanvasLoader
) {

  // REFERRAL QUEUE VIEW
  describe('ReferralQueueView', function () {

    // We need a Collection to test our View
    var settings = {
      pxcentral: '/pxcentral/api/rest/v1/tasks',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    }

    var tasks3 = new ReferralTaskCollection();
    tasks3.url = settings.pxcentral;
    tasks3.digest = settings.digest;

    var ajax_count = 0;

    // Make a view
    var options = {
      collection : tasks3,
      ixlibrary : '/ixlibrary/api/sdo/rest/v1/buckets/underwriting/objects/assignee_list.xml',
      view : {
        el : 'div',
        $el : $('<div><table class="module-referrals"><tbody></tbody></table></div>')
      }
    }

    var view = new ReferralQueueView(options).render();
    view.AssigneeList.set('digest', 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM=');

    beforeEach(function(){
      if (ajax_count < 1) {
        var callback = jasmine.createSpy();
        tasks3.getReferrals({ 'perPage' : 25, 'page' : 1, 'status' : 'New,Pending', 'OwningUnderwriter' : '' }, callback);
        waitsFor(function() {
          ajax_count++;
          return callback.callCount > 0;
        }, "Timeout BOOM!", 10000)
      }
    })

    it ('is an object', function () {
      expect(view).toEqual(jasmine.any(Object));
      console.log(view);
    });

    describe('ReferralQueueView can manage an assignee list via ReferralAssigneesModel', function () {

      var assignee_xml = '<AssigneeList><Assignee identity="art.greitzer@cru360.com" active="true" new_business="false" renewals="false" /><Assignee identity="ms@cru360.com" active="false" new_business="true" renewals="false" /><Assignee identity="ctn@ics360.com" active="false" new_business="false" renewals="false" /><Assignee identity="michele.williams@cru360.com" active="true" new_business="false" renewals="true" /><Assignee identity="ck@cru360.com" active="true" new_business="false" renewals="false" /><Assignee identity="ak@cru360.com" active="false" new_business="false" renewals="false" /><Assignee identity="mm@ics360.com" active="true" new_business="false" renewals="false" /><Assignee identity="dtuser03" active="true" new_business="false" renewals="false" /><Assignee identity="allenr" active="true" new_business="false" renewals="false" /></AssigneeList>';

      var assignee_json = { Assignee : [ { identity : 'art.greitzer@cru360.com', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'ms@cru360.com', active : 'false', new_business : 'true', renewals : 'false' }, { identity : 'ctn@ics360.com', active : 'false', new_business : 'false', renewals : 'false' }, { identity : 'michele.williams@cru360.com', active : 'true', new_business : 'false', renewals : 'true' }, { identity : 'ck@cru360.com', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'ak@cru360.com', active : 'false', new_business : 'false', renewals : 'false' }, { identity : 'mm@ics360.com', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'dtuser03', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'allenr', active : 'true', new_business : 'false', renewals : 'false' } ] };


      it('View can GET an assignees list via model', function (){
        var callbackz = jasmine.createSpy();
        var error = function(model, xhr, options) {
          console.log(['putList ERROR', model, xhr, options]);
        };
        // view.AssigneeList.fetch({
        //   success : callbackz,
        //   'error' : error
        // });
        // waitsFor(function() {
        //   return callbackz.callCount > 0;
        // }, "view.getAssigneeList", 2000);
        runs(function(){
          console.log(['view.getAssigneeList', callbackz.mostRecentCall.args]);
          expect(view.AssigneeList.get('json')).toEqual(assignee_json);
          expect(view.AssigneeList.get('json')).toEqual(jasmine.any(Object));
          expect(view.AssigneeList.get('document').find('Assignee').length).toBe(9);
        });
      });

      it('ReferralAssigneesModel can provide an array of just renewals', function(){
        var renewals = view.AssigneeList.getRenewals();
        var test = [{"identity":"michele.williams@cru360.com","active":true,"new_business":false,"renewals":true}];
         expect(renewals).toEqual(test);
      });

      it('model can convert assignees list JSON to XML', function (){
        xml = view.AssigneeList.json2xml();
        expect(xml).beEquivalentTo(assignee_xml);
      });

      it('can PUT as assignees list and get the model back', function (){
        var callbackz = jasmine.createSpy();
        var error = function(model, xhr, options) {
          console.log(['getAssigneeList ERROR', model, xhr, options]);
        };
        view.AssigneeList.putList(callbackz, error);
        waitsFor(function() {
          return callbackz.callCount > 0;
        }, "view.putAssigneeList", 10000);
        runs(function(){
          console.log(['putList', callbackz.mostRecentCall.args])
          var success = callbackz.mostRecentCall.args[1];
          expect(success).toEqual(jasmine.any(Object));
          expect(view.AssigneeList.get('json')).toEqual(assignee_json);
        });
      });

      it('can change the Assignees JSON and PUT the new XML', function (){

        var new_json = { Assignee : [ { identity : 'art.greitzer@cru360.com', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'ms@cru360.com', active : 'false', new_business : 'true', renewals : 'false' }, { identity : 'ctn@ics360.com', active : 'false', new_business : 'false', renewals : 'false' }, { identity : 'michele.williams@cru360.com', active : 'true', new_business : 'false', renewals : 'true' }, { identity : 'ck@cru360.com', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'ak@cru360.com', active : 'false', new_business : 'false', renewals : 'false' }, { identity : 'mm@ics360.com', active : 'true', new_business : 'false', renewals : 'false' }, { identity : 'dtuser03', active : 'true', new_business : 'true', renewals : 'false' }, { identity : 'allenr', active : 'true', new_business : 'false', renewals : 'true' } ] };

        view.AssigneeList.set('json', new_json);

        var callbackz = jasmine.createSpy();
        var error = function(model, xhr, options) {
          console.log(['putList ERROR', model, xhr, options]);
        };
        view.AssigneeList.putList(callbackz, error);
        waitsFor(function() {
          return callbackz.callCount > 0;
        }, "view.putAssigneeList", 10000);
        runs(function(){
          console.log(['putList', callbackz.mostRecentCall.args])
          var success = callbackz.mostRecentCall.args[1];
          expect(success).toEqual(jasmine.any(Object));
          expect(view.AssigneeList.get('json')).toEqual(new_json);

          // Return to old version
          view.AssigneeList.set('json', assignee_json);
          view.AssigneeList.putList(callbackz, error);
        });
      })

      it('can parse real booleans from strings in the JSON', function(){
        var json = view.AssigneeList.get('json');
        var bools = [ { identity : 'art.greitzer@cru360.com', active : true, new_business : false, renewals : false }, { identity : 'ms@cru360.com', active : false, new_business : true, renewals : false }, { identity : 'ctn@ics360.com', active : false, new_business : false, renewals : false }, { identity : 'michele.williams@cru360.com', active : true, new_business : false, renewals : true }, { identity : 'ck@cru360.com', active : true, new_business : false, renewals : false }, { identity : 'ak@cru360.com', active : false, new_business : false, renewals : false }, { identity : 'mm@ics360.com', active : true, new_business : false, renewals : false }, { identity : 'dtuser03', active : true, new_business : false, renewals : false }, { identity : 'allenr', active : true, new_business : false, renewals : false } ]
        var parsed = view.AssigneeList.parseBooleans(json.Assignee);
        expect(parsed).toEqual(bools);
      });
    });

    it('ReferralAssigneesModel can provide an array of just new business', function(){
      var newbz = view.AssigneeList.getNewBusiness();
      var test = [{ identity : 'ms@cru360.com', active : false, new_business : true, renewals : false }];
       expect(newbz).toEqual(test);
    });

    describe ('it can generate ReferralTaskViews from the collection:', function () {
      
      it ('has an array of sub views', function(){
        expect(view.TASK_VIEWS).toEqual(jasmine.any(Array));
      });

      it ('the sub views are objects and have models', function(){
        expect(view.TASK_VIEWS[0]).toEqual(jasmine.any(Object));
        expect(view.TASK_VIEWS[0].model).toEqual(jasmine.any(Object));
      });

      it ('the sub views are table rows', function(){
        console.log(view.TASK_VIEWS[0]);
        expect(view.TASK_VIEWS[0].el instanceof HTMLTableRowElement).toEqual(true);
      });

    });
  });
});