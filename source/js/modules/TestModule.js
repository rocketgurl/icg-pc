// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'mustache', 'amplify'], function($, _, Backbone, Mustache, amplify) {
    var TestModule;
    return TestModule = (function() {

      function TestModule(view, app, params) {
        this.view = view;
        this.app = app;
        this.params = params;
        this.load();
      }

      TestModule.prototype.load = function() {
        var rnd,
          _this = this;
        rnd = Math.floor(Math.random() * (4 - 1 + 1)) + 1;
        return this.callback_delay(rnd * 1000, function() {
          return _this.view.remove_loader();
        });
      };

      TestModule.prototype.render = function() {
        var tpl,
          _this = this;
        tpl = "<div id=\"test_module\">\n  <h2>{{label}} Module is rendered</h2>\n  <p>Odavno je uspostavljena činjenica da čitača ometa razumljivi tekst dok gleda raspored elemenata na stranici. Smisao korištenja Lorem Ipsum-a jest u tome što umjesto 'sadržaj ovjde, sadržaj ovjde' imamo normalni raspored slova i riječi, pa čitač ima dojam da gleda tekst na razumljivom jeziku. Mnogi programi za stolno izdavaštvo i uređivanje web stranica danas koriste Lorem Ipsum kao zadani model teksta, i ako potražite 'lorem ipsum' na Internetu, kao rezultat dobit ćete mnoge stranice u izradi. Razne verzije razvile su se tijekom svih tih godina, ponekad slučajno, ponekad namjerno (s dodatkom humora i slično).</p>\n</div>";
        this.view.$el.html(Mustache.render(tpl, {
          label: this.app.app_label
        }));
        return $('.open_search_app').on('click', function(e) {
          var $e, app, data;
          e.preventDefault();
          $e = $(e.target);
          data = $e.data();
          app = {
            app: "policy_view_" + data.pcPolicy,
            app_label: "Policy view " + data.pcPolicy,
            params: data
          };
          return _this.view.launch_child_app(app);
        });
      };

      TestModule.prototype.callback_delay = function(ms, func) {
        return setTimeout(func, ms);
      };

      return TestModule;

    })();
  });

}).call(this);
