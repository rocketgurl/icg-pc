// TODO: knock it off with the global variables
var CTX          = {},
    LOGIN_COOKIE = 'mxadmin.login',
    // this HOME global can start being converted to mxAdmin.homeAddress
    HOME         = 'home';

// Make sure Firefox doesn't shit itself if it doesn't have Firebug installed
if (!window.console || !window.console.log) {
  window.console = { log: function () { }, error: function () { } };
}

// Returns an array of all own enumerable properties upon a given object.
// @param OBJECT o
if (!Object.keys) {
  Object.keys = function (o) {
    if (o !== Object(o)) {
      throw new TypeError('Object.keys called on a non-object');
    }

    var ret = [],
        p;

    for (p in o) {
      if (Object.prototype.hasOwnProperty.call(o, p)) {
        ret.push(p);
      }

      return ret;
    }
  };
}

// Format a number
if (!Number.formatMoney) {
  Number.prototype.formatMoney = function (c, d, t) {
    var n = this,
        c = isNaN(c = Math.abs(c)) ? 2 : c,
        d = d == undefined ? "." : d,
        t = t == undefined ? "," : t,
        s = n < 0 ? "-" : "",
        i = parseInt(n = Math.abs(+n || 0).toFixed(c), 10) + "",
        j = (j = i.length) > 3 ? j % 3 : 0;

    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
  };
}

function loadingOn (form) {
  var submitWrapper = form.find('.form_actions'),
      loader        = $('<span class="loading">Loading</span>');

  submitWrapper.addClass('loadingOn').bind('ajaxComplete', function () {
    submitWrapper.removeClass('loadingOn');
    submitWrapper.find('.loading').remove();
  });

  if (submitWrapper.find('.loading').length === 0) {
    submitWrapper.append(loader);
  }
}

// Here we bind a number of events to the body. We'll use these to
// display global messages about errors or successes
$('body').bind('success error', function (e) {
  view.message.apply(null, arguments);
});

// TODO: Clean up and document this function - tgaw
function show (address, params) {
  var viewName,
      viewObj = {},
      loadTemplate = function (viewName, data) {
        var options      = {},
            templateName = viewName;

        // TODO: We can probably smooth this out later
        if (data.product && viewName !== 'home' && viewName !== 'login') {
          // Appending the product name to the view name here so we
          // cache each product-specific template with a name that
          // is unique to its product.
          templateName = viewName + '-' + data.product;

          options.templateLoc = './products/' + data.product + '/forms/' + viewName.replace(/_/g, '-') + '/';
          options.filename    = 'view';
        }

        mxAdmin.loadTemplate(templateName, data, function (compiledView) {
          $('#contents').html(compiledView);

          try {
            if (typeof(view) !== 'undefined' && view[viewName] && view[viewName].load) {
              view[viewName].load(params || {});
            }

            view.onReady();
          }
          catch (err) {
            if (typeof error !== 'undefined') {
              error('Unhandled error while loading "' + address + '" page', err.message);
            } else {
              if (typeof console.log !== 'undefined') {
                console.log('Unhandled error while loading "' + address + '" page', err.message);
              }
            }
            throw err;
          }
        }, options);
      };

  params = params || {};

  if (!address) {
    return;
  }

  if (address[0] === '/') {
    address = address.substr(1);
  }

  viewName = address;

  document.body.id = address;

  // Here we'll work with views that have a view method, meaning there is
  // processing needed to ensure that all necessary viewObj members are created
  // and passed to the template.
  if (typeof (view) !== 'undefined' && view[viewName] && view[viewName].view) {
    try {
      // This will catch all page refreshes
      // NOTE: This needs to be done better
      if (!CTX.policy) {
        return $.address.value(mxAdmin.homeAddress);
      }

      // NOTE: This was written very quickly, probably needs some work.
      mxAdmin.dataModel({
        productName: CTX.product,

        // TODO: When referring to views, change all "_" to "-"
        // so we don't have to do it here or anywhere else.
        viewName: viewName.replace(/_/g, '-'),

        success: function (dataModel) {
          view[viewName].vocabTerms = dataModel;

          // Retrieve the viewObj from the selected view
          viewObj = view[viewName].view(CTX, params, address);

          // If there is a policy present in the view object
          // we need to add the necessary properties to it to
          // display the policy overview
          if (viewObj.policy) {
            viewObj = $.extend(true, viewObj, mxAdmin.helpers.getPolicyOverview(viewObj.policy.InsurancePolicy));

            // Add this just so we can check for it so we don't
            // just show empty elements
            viewObj.policyOverview = true;
          }

          loadTemplate(viewName, viewObj);
        }
      });
    }
    catch (e) {
      console.error('In base.js:show() There was a problem trying to use Mustache to populate the template.', e);
    }
  }
  // Views without a view method will just be passed the CTX and the
  // policy overview information.
  else {
    if (CTX.policy) {
      viewObj = $.extend(true, CTX, mxAdmin.helpers.getPolicyOverview(CTX.policy.InsurancePolicy));
      viewObj.policyOverview = true;
    }
    else {
      // this is pretty bad.
      if (viewName !== 'home' && viewName !== 'login') {
        return $.address.value(mxAdmin.homeAddress);
      }

      viewObj = CTX;
    }
    loadTemplate(viewName, viewObj);
  }
}

// Hook jquery.address events into the route system
$.address.change(function (address) {
    show(address.pathNames[0]);
}).history(true);

$(function () {
  com.ics360.ixdirectory.init('/ixdirectory/api/rest/v2/');
  model.pxcentral.init('/pxcentral/api/rest/v1/');
  model.ixlibrary.init('/ixlibrary/api/sdo/rest/v1/');
  model.ixdoc.init('/ixdoc/api/rest/v2/');

  if ($.address.value() === '/') {
    $.address.value(mxAdmin.homeAddress);
  }
});