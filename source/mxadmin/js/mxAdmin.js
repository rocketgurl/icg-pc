var mxAdmin         = {};
window.mxAdmin      = mxAdmin;
mxAdmin.homeAddress = 'home';

// ICS-979 - loading favicons
mxAdmin.FAVICON_DEFAULT = 'favicon_insight.png';
mxAdmin.FAVICON_LOADING = 'favicon_loading_e.ico';

// Make a request to retrieve an html template.
// @param OBJECT options
mxAdmin.loadTemplate = function (templateName, data, callback, options) {
  var defaults  = {
        // Providing a filename will allow for naming the ich template
        // one name and then requesting a different file from the server
        filename    : templateName,
        extension   : 'html',
        dataType    : 'html',
        templateLoc : './templates/',
        error: function (jqxhr) {
          console.log('There was an error retrieving the template', jqxhr);
        }
      },
      settings  = null,
      template  = null,
      url       = null,
      tmplReady = function () {
        template = ich[templateName](data);
        if ($.isFunction(callback)) {
          callback(template);
        }
      };

  settings = $.extend(defaults, options || {});

  // If we've used the template before, it will be in the ich
  // cache and we can just pull it from there.
  if (ich[templateName]) {
    tmplReady();
  }
  // If not, we'll make an ajax request to grab the template html
  else {
    url  = (settings.templateLoc + settings.filename);
    url += '.' + settings.extension;

    $.ajax({
      url: url,
      type: 'GET',
      dataType: settings.dataType,
      success: function (res) {
        ich.addTemplate(templateName, res);

        tmplReady();
      },
      error: settings.error
    });
  }
};

// Load a favicon in the page to indicate things at work.
mxAdmin.loadFavicon = function(filename) {
  // Change favicon back to default
  $('#favicon').remove();
  var link = document.createElement('link');
    link.type = 'image/x-icon';
    link.rel  = 'icon';
    link.href = './images/' + filename;
    link.id   = 'favicon';
  $('head').append(link);
};

// We'll use this to cache all requested dataModels
// Each product will have a member that will contain
// a member for each view that is requested. When a view
// is opened, if it already exists in the cache we won't
// need to make the ajax request
mxAdmin.dataModelCache = {};

// Retrieve a data model to use with a view
// @param OBJECT options
mxAdmin.dataModel = function (options) {
  var defaults       = {},
      settings       = $.extend(defaults, options || {}),
      needsRequest   = true,
      // OBJECT
      productCache   = mxAdmin.dataModelCache[settings.productName],
      // ARRAY
      dataCache      = null,
      // @param ARRAY data
      dataModelReady = function (data) {
        if ($.isFunction(settings.success)) {
          settings.success(data);
        }
      };

  // Check for the dataModel in our cache object
  if (productCache) {
    dataCache = productCache[settings.viewName];

    if (dataCache) {
      needsRequest = false;

      dataModelReady(dataCache);
    }
  }
  else {
    // Add the requested items to the cache
    mxAdmin.dataModelCache[settings.productName] = {};
    productCache = mxAdmin.dataModelCache[settings.productName];
  }

  // Only make the ajax request if necessary
  if (needsRequest) {
    try {
      $.ajax({
        type     : 'GET',
        url      : './products/' + settings.productName + '/forms/' + settings.viewName + '/model.json',
        dataType : 'json',
        success: function (res) {
          var data = null;

          // Some datamodels will be empty. Empty
          // data causes issues with how the views
          // are handled so we just give an empty array.
          if (res) {
            data = res.terms;
          }
          else {
            data = [];
          }

          // Add the datamodel to the cache
          productCache[settings.viewName] = data;

          // Give the datamodel back to the caller
          dataModelReady(data);
        },
        error: function (jqxhr) {
          if (jqxhr.status === 404) {
            alert('Unable to find a data model for the ' + settings.viewName + ' action of the ' + settings.productName + ' product. Aborting request.');
            $.address.value(mxAdmin.homeAddress);
          }
          else {
            console.log('There was an error making the Ajax request', jqxhr);
          }
        }
      });
    }
    catch (e) { }
  }
};
