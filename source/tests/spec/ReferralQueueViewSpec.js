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
      pxcentral: '/pxcentral/api/rest/v1/tasks/',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    }

    var tasks3 = new ReferralTaskCollection();
    tasks3.url = settings.pxcentral;
    tasks3.digest = settings.digest;

    var ajax_count = 0;

    // Make a view
    var options = {
      collection : tasks3,
      view : {
        el : 'div',
        $el : $('<div><table class="module-referrals"><tbody></tbody></table></div>')
      }
    }

    var view = new ReferralQueueView(options).render();
    // view.CONTAINER = $('<div><table class="module-referrals"><tbody></tbody></table></div>');

    beforeEach(function(){
      if (ajax_count < 1) {
        var callback = jasmine.createSpy();
        tasks3.getReferrals({ 'perPage' : 20, 'page' : 1, 'status' : 'New,Pending', 'OwningUnderwriter' : '' }, callback);
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

    describe('ReferralQueueView can get an assignee list', function () {
      it('can GET an assignees list', function (){
        var callbackz = jasmine.createSpy();
        view.getAssigneeList(
          '/ixlibrary/api/sdo/rest/v1/buckets/underwriting/objects/assignee_list.xml', 
          callbackz
        );
        waitsFor(function() {
          return callbackz.callCount > 0;
        }, "view.getAssigneeList", 10000);
        runs(function(){
          view.assigneeListSuccess(callbackz.mostRecentCall.args[0], callbackz.mostRecentCall.args[1])
          expect(view.ASSIGNEE_LIST.find('Assignee').length).toBe(9);
        });
      });

      it('can PUT as assignees list', function (){
        var callbackz = jasmine.createSpy();
        view.putAssigneeList(
          '/ixlibrary/api/sdo/rest/v1/buckets/underwriting/objects/assignee_list.xml', 
          callbackz,
          view.ASSIGNEE_LIST[0]
        );
        waitsFor(function() {
          return callbackz.callCount > 0;
        }, "view.putAssigneeList", 10000);
        runs(function(){
          view.assigneeListSuccess(callbackz.mostRecentCall.args[0], callbackz.mostRecentCall.args[1])
          console.log(view.ASSIGNEE_LIST[0])
          expect(view.ASSIGNEE_LIST.find('Assignee').length).toBe(9);
        });
      })


    });

    describe ('it can generate ReferralTaskViews from the collection:', function () {
      
      it ('has an array of sub views', function(){
        expect(view.TASK_VIEWS).toEqual(jasmine.any(Array));
      })

      it ('the sub views are objects and have models', function(){
        expect(view.TASK_VIEWS[0]).toEqual(jasmine.any(Object));
        expect(view.TASK_VIEWS[0].model).toEqual(jasmine.any(Object));
      })

      it ('the sub views are table rows', function(){
        console.log(view.TASK_VIEWS[0]);
        expect(view.TASK_VIEWS[0].el instanceof HTMLTableRowElement).toEqual(true);
      })

    });

  });

  

});