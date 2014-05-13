// Favicon.js - Simple animated favicons
// USAGE:
// * var favicon = new Favicon(['img1', 'img2', ..], 250);
//     Initiates (preloads & caches) the image sequence; Sets the interval; Locates the <link>.
//     Tip: Use '' as the last element in the sequence to make an empty icon between cycles.
//     (Optional 2nd arg is animation interval in milliseconds, overwrites the default.)
// * favicon.set('/icon/done.ico', 'Work Done');  (Optional 2nd arg is new title.)
// * favicon.animate('Working...');
//     Starts the animation sequence; Optionally sets the docTitle.
//     To stop the animation, call set() and pass in the new image url or '' for no icon.
;(function (doc) {
  'use strict';

  // -- CONSTRUCTOR ----------------------------------------------------------

  function Favicon(iconSequence, optInterval) {
    if (iconSequence.constructor === Array) {
      var interval = 500;
      this.interval = optInterval != null ? optInterval : interval;
      this.iconSequence = this._preloadIcons(iconSequence);
      this.linkTag = this._retrieveLinkTag();
      this._running = false;
      return this;
    } else {
      throw TypeError('Error: iconSequence must be an Array!');
    }
  }

  // -- PUBLIC ----------------------------------------------------------------

  Favicon.prototype.set = function (iconURL, optDocTitle) {
    this._running = false;
    if (optDocTitle) doc.title = optDocTitle;
    this.linkTag.href = iconURL;
    return this;
  };

  Favicon.prototype.animate = function (optDocTitle) {
    if (this._running) return this;
    var iconSequence = this.iconSequence,
        interval = this.interval,
        tag = this.linkTag,
        favicon = this,
        index = 0;
    this.set(iconSequence[index], optDocTitle);
    this._running = true;
    setTimeout(function loop() {
      if (favicon._running) {
        index = (index + 1) % iconSequence.length;
        tag.href = iconSequence[index];
        setTimeout(loop, interval);
      }
    }, interval);
    return this;
  };

  // -- PRIVATE ---------------------------------------------------------------

  Favicon.prototype._preloadIcons = function (iconSequence) {
    var index = iconSequence.length - 1,
        preloaded = [];
    while (index > -1) {
      preloaded[index] = new Image();
      preloaded[index].src = iconSequence[index];
      index -= 1;
    }
    return iconSequence;
  };

  Favicon.prototype._retrieveLinkTag = function() {
    var tags = doc.head.getElementsByTagName('link'),
        index, len, tag;
    for (index = 0, len = tags.length; index < len; index++) {
      tag = tags[index];
      if (tag.rel === 'shortcut icon') {
        return tag;
      }
    }
    return this._createLinkTag();
  };

  Favicon.prototype._createLinkTag = function () {
    var tag = doc.createElement('link');
    tag.rel = 'shortcut icon';
    doc.head.appendChild(tag);
    return tag;
  };

  // Make it work with require.js, people!
  if (typeof define === 'function' && define.amd) {
    define('favicon', function() {
      return Favicon;
    });
  }

}(document));