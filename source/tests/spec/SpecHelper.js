beforeEach(function() {

  this.addMatchers(EquivalentXml.jasmine);

  this.addMatchers({
    toBePlaying: function(expectedSong) {
      var player = this.actual;
      return player.currentlyPlayingSong === expectedSong && 
             player.isPlaying;
    }
  });
});
