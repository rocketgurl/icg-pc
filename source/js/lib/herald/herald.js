/*
 * HERALD: A javascript module to update users when a client application's version
 * has been updated.
 */

// JSHint Directives
/* global $, module, exports, define */

(function( root ) {
  // Local copy
  var Herald = {};

  // Default property values
  Herald.h_path        = "/js/herald/";
  Herald.change_path   = "";
  Herald.version       = "0.0";
  Herald.change_file   = "changes.md";
  Herald.inject_point  = "body";
  Herald.textProcessor = function( str ) {
    return str.replace( /\n/g, "<br>" );
  }

  /*------------------------------------------------------------------------*\
    THE PUBLIC API
  \*------------------------------------------------------------------------*/

  /**
   * Configure the instance of the herald module by passing in a config object
   *
   * @param {Object} config The config object. Consists of:
   *    {String} h_path             The path to the herald module folder
   *    {String} change_path        The path to the changes file
   *    {String} change_file        The changes file filename
   *    {String} version            The current version number of the client app
   *    {String} inject_point       The id/class selector of the DOM element into
   *                                which the alert modal will be injected
   *    {function} textProcessor    The function to convert the contents of the
   *                                changes file into HTML
   * @this {Herald}
   */
  Herald.init = function( config ) {
    // Load config values
    for ( var key in config ) {
      if ( key === "textProcessor" && typeof config[key] !== "function" ) {
        // Keep the default textProcessor
        throw new Error( "The textProcessor config property must be a function" );
      } else {
        this[ key ] = config[ key ];
      }
    }

    this.injectCSSLink();

    this.change_str = null;
  }

  /**
   * Check the user's version of the client App and display an update
   * message if appropriate.
   *
   * @this {Herald}
   */
  Herald.execute = function() {
    // If cookie is out of date or doesnt exist, display modal alert
    if ( this.checkCookie() === false ) {
      this.getAndDisplayChanges();
    }

    // Set cookie with current version
    this.setCookie();
  }

  /**
   * Set this.change_str to the contents of the changes file and call
   * renderModal().
   *
   * @this {Herald}
   */
  Herald.getAndDisplayChanges = function() {
    // Get the contents of the changes file
    var jqxhr = $.ajax({
      url: this.change_path + this.change_file,
      context: Herald
    });

    // Render it
    jqxhr.done(function( data ) {
      // Use proxy to refer to Herald as 'this'
      $.when( this.textProcessor(data) ).done( $.proxy(function(result) {
        this.change_str = result;
        this.renderModal();
      }, this));
    });
    jqxhr.fail(function( jqXHR, textStatus, errorThrown ) {
      throw new Error( "Herald couldn't get data from the changes file: " + errorThrown );
    });
  }

  /**
   * Inject the css link for the herald modal popup as the first css link in the
   * DOM's head. It's important that we put the Herald css link before any others
   * so that it can be overwritten.
   *
   * @this {Herald}
   */
  Herald.injectCSSLink = function () {
    // Append herald.css link to head. As the first link so it can be
    // easily overriden.
    var $head = $( "head" )
    var herald_link = "<link rel='stylesheet' href='" + this.h_path + "herald.css'>";
    $head.prepend( herald_link );
  }

  /**
   * Inject the update message modal overlay into the DOM
   *
   * @this {Herald}
   */
  Herald.renderModal = function() {
    // Assemble and prepend alert modal in insert_point DOM element
    var jqxhr = $.ajax({
      url: this.h_path + "alert.html",
      context: Herald
    });
    jqxhr.done( Herald.prependHtml );
    jqxhr.fail(function( jqXHR, textStatus, errorThrown ) {
      throw new Error( "Herald alert modal failed: " + errorThrown );
    });
  }

  /**
   * Assemble a DOM element from the passed in html string, populate it
   * with the text from the changes file, and prepend it to the DOM element
   * specified by this.inject_point
   *
   * @this {Herald}
   * @param {string} alert_html An HTML string (should be ajax'd from alert.html)
   */
  Herald.prependHtml = function( alert_html ) {
    var $alert, $alert_modal, $alert_modal_content;

    $alert = $( alert_html );
    $alert_modal = $alert.find( "#herald-alert" );
    $alert_modal_content = $alert_modal.find( "#herald-content" );

    // Insert changes file contents
    $alert_modal_content.html( this.change_str );

    // Center vertically
    var window_height = $( window ).height();
    $alert_modal.height( 0.7 * window_height );
    $alert_modal.css({
      marginTop: ( window_height / 2 ) - ( $alert_modal.height() / 2 ),
      overflow: "auto"
    });

    // Set up close on click anywhere outside modal
    $alert.click(function() {
      $alert.hide();
      $alert.remove();
    });

    $alert_modal.click(function(e) {
      e.stopPropagation();
    });

    // Set up close on button click
    $alert.find( "button" ).click(function() {
      $alert.hide();
      $alert.remove();
    });

    $( this.inject_point ).prepend( $alert );
  }

  /**
   * Sets the 'herald' cookie on the user's browser to the current version
   * of the client App
   *
   * @this {Herald}
   */
  Herald.setCookie = function() {
    this.Cookie.set( "herald", this.version, 3650 );
  }

  /**
   * Returns the value of the 'herald' cookie on the user's browser
   *
   * @this {Herald}
   * @return The current value of the herald cookie
   */
  Herald.getCookie = function() {
    return this.Cookie.get( "herald" );
  }

  /**
   * Checks for the 'herald' cookie on the user's browser. If it exists and
   * its value matches the current version of the client app (as described in
   * the config parameter passed to Herald's init method), returns true.
   * Otherwise returns false.
   *
   * @this {Herald}
   * @return {boolean} Cookie exists and is current OR not
   */
  Herald.checkCookie = function() {
    var ck_value, ck_valid;

    ck_value = this.getCookie();

    if ( ck_value !== null && ck_value === this.version ) {
      ck_valid = true;
    } else {
      ck_valid = false;
    }

    return ck_valid;
  }


  /*------------------------------------------------------------------------*\
    COOKIE MANAGEMENT
  \*------------------------------------------------------------------------*/

  var Cookie = {};

  /**
   * Replace all '+' characters in a string with white spaces
   *
   * @this {Cookie}
   * @param {string} str The string to be decoded
   * @return {string} The decoded string
   */
  Cookie.decoded = function( str ) {
    return decodeURIComponent( str.replace( this.pluses, ' ' ) );
  };

  /**
   * Set a cookie with the specified key, to the specified value.
   *
   * @this {Cookie}
   * @param {string} key The cookie key
   * @param {string} value The cookie value
   * @param {number} days The number of days from today until the cookie expires
   * @return {string} The cookie-setting string
   */
  Cookie.set = function( key, value, days ) {
    var expires, date;

    if ( days ) {
      date = new Date();
      date.setTime( date.getTime() + (days * 24 * 60 * 60 * 1000) );
      expires = "expires=" + date.toGMTString();
    } else {
      expires = "";
    }

    var cookie_str = key + "=" + value + ";" + expires + ";" + "path=/";

    document.cookie = cookie_str;
    return cookie_str;
  };

  /**
   * Grabs the value of the cookie with the specified name string
   *
   * @this {Cookie}
   * @param {string} key The cookie key
   * @return {string} The cookie value. (Or null)
   */
  Cookie.get = function( key ) {
    var cookie, cookies, parts, _i, _len;

    cookies = document.cookie.split( '; ' );

    for ( _i = 0, _len = cookies.length; _i < _len; _i++ ) {
      cookie = cookies[ _i ];
      if ( parts = cookie.split( '=' ) ) {
        if ( parts.shift() === key ) {
          return this.decoded( parts.join( '=' ) );
        }
      }
    }
    return null;
  };

  /**
   * Remove the cookie specified by the given key from the user's browser.
   * Returns true if deletion is performed, false otherwise.
   *
   * @this {Cookie}
   * @param {string} key The cookie key
   * @return {boolean} Success OR the cookie didn't exist
   */
  Cookie.remove = function( key ) {
    if ( key != null ) {
      this.set( key, "", -1 );
      return true;
    } else {
      return false;
    }
  };

  Herald.Cookie = Cookie;

  /*------------------------------------------------------------------------*\
    EXPORT
  \*------------------------------------------------------------------------*/
  // Node
  if ( typeof module === "object" && module && typeof module.exports === "object" ) {
    module.exports = Herald;
  }
  // CommonJS
  else if ( typeof exports === "object" && exports ) {
    exports.Herald = Herald;
  }
  // AMD
  else if ( typeof define === "function" && define.amd ) {
    define( "herald", [], function() { return Herald; } );
  }
  // <script>
  else {
    root.Herald = Herald;
  }

} ( this ) );
