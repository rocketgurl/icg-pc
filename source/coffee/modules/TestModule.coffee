define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache'
], ($, _, Backbone, Mustache) ->

  class TestModule

    # Modules need to be able to call into the parent
    # WorkspaceCanvasView to manipulate the canvas area
    # in the browser.
    #
    # @param `view` _Object_ WorkspaceCanvasView
    # @param `app` _Object_ Application object
    # @param `params` _Object_ Applications specific params
    #
    constructor : (@view, @app, @params) ->
      # Kick off application
      @load()
      
    # Any bootstrapping should happen here. When done remove the loader image.
    # view.remove_loader will callback Module.render()
    #
    load: ->
      rnd = Math.floor(Math.random() * (4 - 1 + 1)) + 1;
      @callback_delay rnd * 1000, => 
        @view.remove_loader(true)

    # Do whatever rendering animation needs to happen here
    render : ->
      tpl = """
      <div id="test_module">
        <h2>{{label}} Module is rendered</h2>
        <p>Odavno je uspostavljena činjenica da čitača ometa razumljivi tekst dok gleda raspored elemenata na stranici. Smisao korištenja Lorem Ipsum-a jest u tome što umjesto 'sadržaj ovjde, sadržaj ovjde' imamo normalni raspored slova i riječi, pa čitač ima dojam da gleda tekst na razumljivom jeziku. Mnogi programi za stolno izdavaštvo i uređivanje web stranica danas koriste Lorem Ipsum kao zadani model teksta, i ako potražite 'lorem ipsum' na Internetu, kao rezultat dobit ćete mnoge stranice u izradi. Razne verzije razvile su se tijekom svih tih godina, ponekad slučajno, ponekad namjerno (s dodatkom humora i slično).</p>
      </div>
      """

      @view.$el.html Mustache.render(tpl, { label : @app.app_label })

      # Attach a handler
      $('.open_search_app').on 'click', (e) =>
        e.preventDefault()
        $e = $(e.target)
        data = $e.data()

        app =
          app       : "policy_view_#{data.pcPolicy}"
          app_label : "Policy view #{data.pcPolicy}"
          params    : data

        @view.launch_child_app app
        

    # Simple delay fund if we need it.
    callback_delay : (ms, func) ->
      setTimeout func, ms
