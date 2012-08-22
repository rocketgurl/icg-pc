var model = {};

function _preflight_credentials () {
    var id = com.ics360.ixdirectory.getAuthorizationHash();
    if(id === false){
        id = cookie.get('mxadmin.login');
    }
    if(!id){
        console.error("Don't have a working set of credentials.");
    }
    return id;
}

function _itemGet (items, key) {
    for (var i = 0, ii = items.length; i < ii; i++) {
        if (items[i].$name === key) {
            return items[i].$value;
        }
    }
}

model.GET = function (url, success, error) {
    var id = _preflight_credentials();
    if (!id) return;

    return $.ajax({
        url        : url,
        dataType   : 'xml',
        beforeSend : com.ics360.ajaxCrippledClient('GET', ['X-Authorization: Basic '+ id, 'Cache-Control: no-cache']),
        error      : error,
        success: function(xml, status, xhr) {
          var crippleSuccess = com.ics360.ajaxCrippleClientSuccess(xhr);
      
          // Cripple success checks the X-True-Statuscode header for a
          // double-dose of header checkin'
          if (crippleSuccess) {
            if (xml) {
              success(objectify.fromXML(xml));
            }
          } else {
            error(xhr, status);
          }
        }
    });
};

model.DELETE = function (url, success, error) {
    var id = _preflight_credentials();
    if(!id) return;
  
    console.log('DELETE ' + url);
  
    return $.ajax({
        url        : url,
        dataType   : 'xml',
        beforeSend : com.ics360.ajaxCrippledClient('DELETE', ['X-Authorization: Basic '+ id]),
        error      : error,
        success: function(xml, status, xhr) {
      var crippleSuccess = com.ics360.ajaxCrippleClientSuccess(xhr);
      
      // Cripple success checks the X-True-Statuscode header for a
      // double-dose of header checkin'
      if (crippleSuccess) {
        if (xml) {
          success(objectify.fromXML(xml));
        }
      } else {
        error(xhr, status);
      }
        }
    });
};

model._UP = function (method) {
  return function (url, data, options) {    
      var id   = _preflight_credentials(),
      settings = null,
      defaults = {
        contentType: 'application/xml',
        success: function () {
          alert("Success");
        },
        error: function (xhr, status) {
          alert('Error ' + status);
        },
        headers: {
          // This header needs to be sent with all requests
          'X-Authorization': 'Basic ' + id,
        }
      },
      headerList = [];

    settings = $.extend(true, defaults, options);
    
    // Build an array of headers from the settings.headers property 
    // to set before sending the ajax request.
    $.each(settings.headers, function (key, val) {
      headerList.push(key + ': ' + val);
    });
    
      if (!id) {
      return;
    }
        
      return $.ajax({
          url         : url,
          dataType    : 'xml',
          type        : 'POST',
          contentType : settings.contentType,
          data        : objectify.toXML(data),
          beforeSend  : com.ics360.ajaxCrippledClient(method, headerList),
          error       : view.message,
          success: function (xml, status, xhr) {
            var crippleSuccess = com.ics360.ajaxCrippleClientSuccess(xhr);
            // Cripple success checks the X-True-Statuscode header for a
            // double-dose of header checkin'
            if (crippleSuccess) {
              if (xml) {
                settings.success(objectify.fromXML(xml));
              }
            } else {
              settings.error(xhr, status);
            }
          }
      });
  };
};

model.POST = model._UP('POST');
model.PUT = model._UP('PUT');

model.mime = {
    'bmp'   : 'images/bmp',
    'css'   : 'text/css',
    'doc'   : 'application/msword',
    'dot'   : 'application/msword',
    'gif'   : 'image/gif',
    'gz'    : 'application/x-gzip',
    'htm'   : 'text/html',
    'html'  : 'text/html',
    'ico'   : 'image/x-icon',
    'jpeg'  : 'image/jpeg',
    'jpg'   : 'image/jpeg',
    'js'    :  'application/javascript',
    'mht'   : 'message/rfc822',
    'mhtml' : 'message/rfc822',
    'pdf'   : 'application/pdf',
    'png'   : 'image/png',
    'pps'   : 'application/vnd.ms-powerpoint',
    'ppt'   : 'application/vnd.ms-powerpoint',
    'svg'   : 'image/svg+xml',
    'tgz'   : 'application/x-compressed',
    'txt'   : 'text/plain',
    'xla'   : 'application/vnd.ms-excel',
    'xlc'   : 'application/vnd.ms-excel',
    'xlm'   : 'application/vnd.ms-excel',
    'xls'   : 'application/vnd.ms-excel',
    'xlt'   : 'application/vnd.ms-excel',
    'xlw'   : 'application/vnd.ms-excel',
    'zip'   : 'application/zip'
};

model.mimeFromExt = function (ext) {
  return model.mime[ext.toLowerCase()] || 'application/octet-stream';
};

model.login = (function () {
  $(document).bind('com.ics360.error', function (e) {
    e.stopPropagation();
    e.preventDefault();
    view.login.error();
  });

  return function (username, password, callback) {
    com.ics360.ixdirectory.loadIdentity(username, password, function () {
      cookie.set('mxadmin.login', com.ics360.ixdirectory.getAuthorizationHash(), 14);

      if (callback && typeof callback == 'function') {
        callback(com.ics360.ixdirectory.getUserEmail());
      }
    });
  };
})();

// A Policy Object
// @param OBJ policyXML - Should be the <InsurancePolicy> xml node
// @return OBJ
//
//
// NOTE: Currently in-progress. Moving methods over from
//       model.pxcentral.policy
model.policy = function (policyXML) {
  var that = this,
      px   = model.pxcentral.policy,
      ret  = {};
  
  this.policyXML = policyXML;
  
  this.states = {
    ACTIVE_POLICY      : 'ACTIVEPOLICY',
    ACTIVE_QUOTE       : 'ACTIVEQUOTE',
    CANCELLED_POLICY   : 'CANCELLEDPOLICY',
    EXPIRED_QUOTE      : 'EXPIREDQUOTE',
    NON_RENEWED_POLICY : 'NONRENEWEDPOLICY'
	};
 
  // Determine the state of the policy
  // @return STRING - The state of the policy
  this.state = function () {
    var management     = that.policyXML.Management,
        policyState    = management.PolicyState,
        policyStateVal = null;
    
    // When we convert XML to JSON. If a node has no attributes, the node's
    // text value is returned. When the node has attributes, the node's text
    // value is returned as a member of the JSON object named "$". Because
    // the policyState node may or may not have attributes we need to check
    // for it here.
    if (typeof policyState === 'string') {
      policyStateVal = policyState;
    } else {
      policyStateVal = policyState.$;
    }
    
    return policyStateVal;
  };
  
  // Determine if a policy has been cancelled
  // @param OPTIONAL BOOL - Only return a boolean, defaults to false
  // @return BOOL | OBJ
  this.cancelled = function (onlyBool) {
    var cancelled = false,
        state     = that.state();
    
    if (state === 'CANCELLEDPOLICY') {
      cancelled = true;
    }
    
    return cancelled;
  };
  
  // Whether this policy is actually a quote.
  // @return BOOL
  this.quote = function () {
    var state = that.state();
  
    return state === that.states.ACTIVE_QUOTE ||
           state === that.states.EXPIRED_QUOTE;
  };
  
  // Determine if the policy is pending cancellation
  // @return BOOL | OBJ
  this.pendingCancel = function (onlyBool) {
    var management = that.policyXML.Management,
      pending    = management.PendingCancellation || false;
    
    // At times we only want this to return a boolean instead of
    // the pending cancel object if it exists
    if (onlyBool && pending) {
      pending = true;
    }
    
    return pending;
  };
  
  // Determine the cancellation effective date, if any.
  // @return STRING | NULL
  this.cancellationEffectiveDate = function () {
    var policyState   = that.state(),
      effectiveDate = null,
      pending       = null;
    
    switch (policyState) {
    case 'ACTIVEPOLICY':
      
      pending = that.pendingCancel()
      
      // If the policy is pending cancel, give the cancellation
      // effective date set on the pending cancel element
      if (pending) {
        effectiveDate = pending.$cancellationEffectiveDate;
      }
      
      break;
    case 'CANCELLEDPOLICY':
      effectiveDate = that.policyXML.Management.PolicyState.$effectiveDate;
    }
    
    return effectiveDate;
  };
  
  // Determine the cancellation reason code, if any.
  // @return STRING | NULL
  this.cancellationReasonCode = function () {
    var policyState = that.state(),
      reasonCode  = null,
      pending     = that.pendingCancel();
    
    switch (policyState) {
    case 'ACTIVEPOLICY':
      
      pending = that.pendingCancel()
      
      // If the policy is pending cancel, give the cancellation
      // reason code set on the pending cancel element
      if (pending) {
        reasonCode = pending.$reasonCode;
      }
      
      break;
    case 'CANCELLEDPOLICY':
      reasonCode = that.policyXML.Management.PolicyState.$reasonCode;
    }
    
    return reasonCode;
  };
  
  // Get the Terms of the policy
  // @return ARRAY
  this.terms = function () {
    var terms   = [],
        TermXML = that.policyXML.Terms.Term;
    
    // If the policy has multiple terms then Term will already be
    // an Array, so we'll just set the return value to it
    if ($.isArray(TermXML)) {
      terms = TermXML;
      
    // If the policy has a single term then Term will be the single
    // Term object. In that case we'll push it onto our return value
    } else {
      terms.push(TermXML);
    }
    
    return terms;
  };
  
  // Get the last Term of the policy
  // @return OBJECT - A Term object
  this.lastTerm = function () {
    var t = this.terms();
      l = t.length;    
      return t[l - 1];
  };
  
  // Get Customer data of the specified type
  // @param STRING type
  // @return ARRAY
  this.customerData = function (type) {
    var ret = null,
      arr = that.policyXML.Customers.Customer,
      i   = 0,
      len = arr.length;
    
    for (i; i < len; i += 1) {
      if (arr[i].$type === type) {
        ret = arr[i].DataItem;
        break;
      } 
    }
    
    return ret;
  };
  
  // Retrieve the intervals of the given term
  // @param OBJECT - A Term object
  // @return ARRAY - An Array of Interval objects
  this.intervalsOfTerm = function (term) {
    var intervals = [],
      intOrigin = term.Intervals.Interval;
    
    // If there are multiple intervals, the origin
    // will already be an array
    if ($.isArray(intOrigin)) {
      intervals = intOrigin;
    
    // If there is only one Interval it will be an object
    } else {
      intervals.push(intOrigin);
    }
    
    return intervals;
  };
  
  // Get the last interval of the last term of the policy
  // @return OBJECT
  this.lastInterval = function () {
    var term      = this.lastTerm();
      intervals = this.intervalsOfTerm(term),
      l         = intervals.length;
        
    return intervals[l - 1];
  };
  
  // OBJ - The original policy xml obj
  ret.orig = policyXML;
  
  // STRING - The State of a policy
  ret.state = this.state();
  
  // BOOL - Whether this policy is actually a quote.
  ret.quote = this.quote();
  
  // If this policy is still a quote we want to abandon ship.
  if (ret.quote) {
    return ret;
  }
  
  // BOOL - Is this policy pending cancellation
  ret.pendingCancel  = this.pendingCancel(true);
  
  // STRING | NULL - If the policy is pending cancel, or cancelled,
  //                 this will return the date as a string. Else null.
  ret.cancellationEffectiveDate = this.cancellationEffectiveDate();
  
  // STRING | NULL - If the policy is pending cancel, or cancelled,
  //                 this will return the reasonCode. Else null.
  ret.cancellationReasonCode = this.cancellationReasonCode();
  
  // BOOL - Is this policy cancelled or not
  ret.cancelled = this.cancelled();
  
  // ARRAY - An Array of Term objects
  ret.terms = this.terms();
  
  // OBJ - The last term of the last interval of the policy
  ret.lastInterval = this.lastInterval();
  
  // ARRAY - An Array of Customer DataItems
  ret.insuredData = this.customerData('Insured');
  
  // ARRAY - An Array of Customer DataItems
  ret.mortgageeData = this.customerData('Mortgagee');
  
  // ARRAY - An Array of AdditionalInterest DataItems
  ret.additionalInterestData = this.customerData('AdditionalInterest');
  
  // STRING - The name of the product this policy belongs
  ret.productName = (function () {
    var productName  = null,
      gdi          = mxAdmin.helpers.getDataItem,
      lastTerm     = that.lastTerm(),
      dataItems    = lastTerm.DataItem,
      nameArr      = [
        gdi(dataItems, 'OpProgram'),
        gdi(dataItems, 'OpPolicyType'),
        gdi(dataItems, 'OpPropertyState')
      ];
    
    productName = nameArr.join('-').toLowerCase();
        
    return productName;
  }());
  
// The following properties still rely on the to-be-deprecated 
// pxcentral.policy model. They will be moved over to methods
// with this model
  
  // STRING - The policy identifier
  ret.id =  px.id(that.policyXML);
  
  // BOOL - Has a policy been issued or not
  ret.issued = px.isIssued(that.policyXML);
  
  // OBJ - A Policy Term object
  ret.firstTerm = px.getFirstTerm(that.policyXML);
  
  // OBJ - A Policy Term object
  // TODO: Change this to use the policy.lastTerm() method
  ret.lastTerm = px.getLastTerm(that.policyXML);
  
  // STRING - The effective date of the first Term of a Policy
  ret.effectiveDate = px.getEffectiveDate(that.policyXML);
  
  // STRING - The expiration date of the last Term of a Policy
  ret.expirationDate = px.getExpirationDate(that.policyXML);
  
  return ret;
};

model.pxcentral = {
    init: function (url) {
        this._url = url;
        if (url[url.length - 1] !== '/') this._url += '/';
    },
    policy: {
        id: function (policyDoc) {
            if (!policyDoc) {
        return null;
      }
      
            return _itemGet((policyDoc.InsurancePolicy || policyDoc).Identifiers.Identifier,'InsightPolicyId');
        },
        get: function (policy_id, callback, errback) {
            var url = model.pxcentral._url + 'policies/' + policy_id;
            url += '?media=insurancepolicy.2.6';
            return model.GET(url, callback, errback);
        },

    // Update a policy
    // @param String policy_id
    // @param Object payload - The data that will be sent with the request
    // @param Object options
    set: function (policy_id, payload, options) {
            
      var defaults = {
          contentType: 'application/xml;',
          url: model.pxcentral._url + 'policies/' + policy_id,
          headers: {
            'Accept': 'application/vnd.ics360.insurancepolicy.2.6+xml',
            'X-Commit': true
          },
          callback: view.request_success(),
          err: view.request_error
        },
        settings = null,
        
        // We need to inspect the payload to determine what type of transaction
        // it is and the schemaVersion. As of 1.1.0 the type can be a 
        // PolicyChangeSet or a TransactionRequest.
        payloadType    = payload.__rootName.toLowerCase(),
        payloadVersion = payload.$schemaVersion,
        payloadSchema  = ' schema=' + payloadType + '.' + payloadVersion;
      
      // Add the schema to the default content type
      defaults.contentType = defaults.contentType + payloadSchema;
      
      // Override defaults with any given options
      settings = $.extend(true, defaults, options);
            
      return model.POST(settings.url, payload, {
        contentType: settings.contentType,
        headers: settings.headers,
        success: settings.callback,
        error: settings.err
      });
    },
    
    // Determine if a policy has been issued
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @return BOOL
        isIssued: function (policy) {
            if (policy.History && policy.History.Event) {
                for (var i = 0, ii = policy.History.Event.length; i < ii; i++) {
                    if (policy.History.Event[i].$type.toLowerCase().indexOf('issue') === 0) {
                        return true;
                    }
                }
            }
            return false;
        },
    
    // Retrieve a specific term of a policy.
    //
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @param INT - termNumber, Base 1
    // @return OBJ - The requested term
    getTerm: function (policy, termNumber) {
      var terms            = policy.Terms.Term,
        
        // Since we'll be dealing with an array if there are multiple
        // terms we need to switch to base zero indices.
        requestedTerm    = termNumber - 1,
        
        numberOfTerms    = this.getNumberOfTerms(policy),
        ret              = null;
            
      // If there are multiple terms, we'll be dealing with an Array of Terms.
      if (numberOfTerms > 1) {
                
        // We need to make sure the requested term is present. If not we'll
        // log the error and return the first term
        try {
          if (termNumber > numberOfTerms) {
            throw new Error();
          }
        } catch (e) {
          requestedTerm = 0;
          console.error('Term number ' + termNumber + ' was requested, but the policy only contains ' + numberOfTerms + ' terms. Term 1 has been returned.');
        }
        
        ret = terms[requestedTerm];
      
      // If there is a single term, we'll be dealing with a Term Object
      } else {
        
        // If a term has been requested that does not exist, we need to
        // log it.
        try {
          if (requestedTerm > 0) {
            throw new Error();
          }
        } catch (e) {
          console.error('Term number ' + termNumber + ' was requested, but the policy only contains 1 term.');
        }
        
        ret = terms;
      }
      
      return ret;
    },
    
    // Helper method for retrieving the first term of a policy
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @return OBJ - The requested term.
    getFirstTerm: function (policy) {
      return this.getTerm(policy, 1);
    },
    
    // Helper method for retrieving the last term of a policy
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @return OBJ - The requested term.
    getLastTerm: function (policy) {
      var lastTermNum = this.getNumberOfTerms(policy);
      
      return this.getTerm(policy, lastTermNum);
    },
    
    // Determine the number of terms in a policy
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @return INT - The number of terms
    getNumberOfTerms: function (policy) {
      var terms            = policy.Terms.Term,
        hasMultipleTerms = jQuery.isArray(terms),
        ret              = null;
      
      if (hasMultipleTerms) {
        ret = terms.length;
      } else {
        ret = 1;
      }
      
      return ret;
    },
    
    // A helper method for retrieving a type of date from a term
    //
    // @param OBJ policy - Should be the <InsurancePolicy> xml node 
    // @param STRING dateType - Can be one of 'effective'|'expiration'
    // @return STRING - A date string in DateJS yyyy-MM-dd format
    getTermDate: function (policy, dateType) {
      var term, date;
      
      switch (dateType) {
      case 'effective':
        term = this.getFirstTerm(policy);
        date = term.EffectiveDate;
        break;
      case 'expiration':
        term = this.getLastTerm(policy);
        date = term.ExpirationDate;
        break;
      default:
        throw new Error(dateType + ' is not a recognized date type.');
      }
      
      // We'll use our stripTimeFromDate helper to before parsing the date
      // to make sure nothing weird happens do to having a timestamp.
      date = mxAdmin.helpers.stripTimeFromDate(date);
      
      return Date.parse(date).toString('yyyy-MM-dd');
    },
    
    // Determine the policy expiration date by retrieving the EffectiveDate
    // of the policy's first term.
    //
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @return STRING - A date string in DateJS yyyy-MM-dd format
    getEffectiveDate: function (policy) {
      return this.getTermDate(policy, 'effective');
    },
    
    // Determine the policy expiration date by retrieving the ExpirationDate
    // of the policy's last term.
    //
    // @param OBJ policy - Should be the <InsurancePolicy> xml node
    // @return STRING - A date string in DateJS yyyy-MM-dd format
    getExpirationDate: function (policy) {
      return this.getTermDate(policy, 'expiration');
    }
  }
};

model.ixdoc = {
    init: function (url) {
        model.ixdoc._url = url;
        if (url[url.length - 1] !== '/') this._url += '/';
        model.ixdoc._url += 'templates/';
    },
    // ixdoc doesn't have a cripple client interface (afaik) so this method
    // calls the main interface with the given XML and has ixdoc write the
    // response to ixlib and calls the callback with the returned URL.
    template: function (template_key, template_xml_data, callback, errback, extra) {
        var id = _preflight_credentials();
        if (IXDOC_PDF_TEMPLATES[template_key]) {
            $.ajax({
                url : model.ixdoc._url + IXDOC_PDF_TEMPLATES[template_key] + extra,
                type: 'POST',
                contentType: 'application/xml',
                data: template_xml_data,
                beforeSend: function(xhr) {
                    xhr.setRequestHeader('X-Authorization', 'Basic '+id);
                    xhr.setRequestHeader('X-Storage-Location', 'http://ics-test-services.arc/cru-4' + model.ixlibrary.policy.url(model.pxcentral.policy.id(CTX.policy), template_key));
                },
                error: errback,
                success: function(xml,status,xhr) {
                    if (xhr.status === 201) {
                        callback.call(this, xhr.getResponseHeader('Location'));
                    } else {
                        errback.call(this, xhr);
                    }
                }
            });
        } else {
            throw new Error('template key "'+template_key.toString()+'" is not in IXDOC_PDF_TEMPLATES');
        }
    }
};

model.ixlibrary = {
    init: function (url) {
        model.ixlibrary._url = url;

        if (url[url.length - 1] !== '/') {
      this._url += '/';
    }
    
        model.ixlibrary._url += 'buckets/';
    },
    policy: {
        url: function (policy_id, doc_id) {
            return model.ixlibrary._url + 'policy_' + policy_id + '/objects' + (doc_id ? '/'+ doc_id : '');
        },
        get: function (policy_id, doc_id, callback, errback) {
            if (typeof doc_id === 'function'){
                errback = callback;
                callback = doc_id;
                doc_id = null;
            }
            return model.GET(this.url(policy_id, doc_id), function(res){
                if (!res || res.Error){
                    if (errback && errback.call) errback(res);
                } else {
                    if(callback && callback.call) callback(res);
                }
            }, errback);
        },
        set: function (policy_id, doc_id, value, callback, errback) {
            if (typeof doc_id === 'function') {
                errback = callback;
                callback = doc_id;
                doc_id = null;
            }

      // NOTE: The call to PUT here is wrong and appears to have been wrong
      // for some time. It's not in use anywhere as have 1.1.0 - tgaw
            return model.PUT(this.url(policy_id, doc_id), callback, errback);
        },
        
    // What does this do...?
    bindField: function (element_id, url, object_key, callback) {
            var id = _preflight_credentials(),
                uploader;

            if (!id) return;
            
      url += '?x-crippled-client=true&x-crippled-client-envelope=true';
      
      try { 
          uploader =  new AjaxUpload(element_id, {
              action: url,
              name: 'object-data-file',
              responseType: false,
              data: {
                  //"X-Method" : 'PUT',
                  //"X-Rest-Method" : 'PUT',
                  "name"       : element_id,
                  "auth-token" : "Basic " + id,
                  "object-key" :  object_key,
                  "content-type": 'application/octet-stream'
              },
              onChange: function (file, ext) {
                  $(element_id + '>.filename').text(file);
                  $(element_id + '>.action').text('Uploading...');
                  uploader._settings.data['content-type'] = model.mimeFromExt(ext);
              },
              onSubmit: function (file, ext) {
                  this.disable();
                  $('input[type=submit]').attr('disabled', true);
              },
              onComplete: function (filename, response) {
                  var root       = response.firstChild,
                      status     = ~~(root.getAttribute('statusCode')),
                      statusText = root.getAttribute('statusText');
          
                  if (status >= 400) {
                      $('body').trigger('error', ['Upload Error: ' + status + ' ' + statusText, 'Form submission disabled. Try again or check the <a href="' + url.split('?')[0] + '">ixLibrary Bucket</a>.']);
                      $(element_id + '>.action').text('Choose File');
                      this.enable();
                  } else {
                      $(element_id).find('.action').text('Uploaded');
                      $('input[type=submit]').removeAttr('disabled');
                      callback.apply(this, arguments);
                  }
              }
          });
      } catch (e){}
    }
    },
  
  // These are names that will be used when creating things...?
  slugs: {
    issue: {
      objKey: 'PolicyNewBusinessPackage',
      docId: 'PolicyNewBusinessPackage',
      decKey: 'DeclarationofCoverage',
      decId: 'DeclarationofCoverage'
    },
    
    invoice: {
      objKey: 'PolicyInvoice',
      docId: 'PolicyInvoice'
    },
    
    cancel: {
      objKey: 'CancelNotice',
      docId: 'CancelNotice',
      
    },
    
    pendingCancel: {
      objKey: 'PendingCancelNotice',
      docId: 'PendingCancelNotice'
    },
    
    rescind: {
      objKey: 'RescindPendingCancelNotice',
      docId: 'RescindPendingCancelNotice'
    },
    
    reinstate: {
      objKey: 'ReinstateNotice',
      docId: 'ReinstateNotice'
    }
  }
};

// For each of the templates, create a member in set.
// In the view, we'll be able to call each template as
// a member and pass it changes from a form. It. Is. Confusing.
//
// This is used for both PolicyChangeSet(s) and for TransactionRequest(s)
//
// NOTE: Naming here may be a little strange?
model.changeSpec = function (policyDoc, templates) {
  var set = {};
  
  for (var k in templates) {
        if (k === '_skeleton' || k === 'context'){
            continue;
        }
    
        set[k] = (function (tpl) {
            return function (formObj) {
                var // Context is mostly just making sure our object of submitted
          // values is valid for the PolicyChangeSet. Checks for valid dates,
          // version number, document names, etc.
          context = templates.context(policyDoc, formObj, tpl),
          
          // Here we just combine the template skeleton with the
          // template for the action we are taking. out is a full template
          // that the values of the context object will be inserted.
                  out     = $.extend(true, {}, templates._skeleton, templates[tpl]);

        return model.changeSpecReplacement(out, context);
            };
        })(k);
    }

  return set;
};

// This is where we determine which values from the submitted form data will
// be inserted into object that will be converted into xml and sent.
// @param OBJ item    - The full object template that values will be inserted
// @param OBJ context - The data that is sent from the form.
// TODO: It'd be better to just toXML the templates and do the replace on those.
model.changeSpecReplacement = function (item, context) {
  var tmp;
  
  // TODO: Figure out what this does exactely and document!
    function strreplace (str) {
        return (str.toString() || '').replace(/\{\{\s*(\S+)\s*\}\}/g, function (x, v) {
            return context[v] || '';
        });
    }
  
  // For each of the members of the template object we are trying
  // to replace any key:values that are, right now, tokens like '$name':'$value'
  // with the actual name:values. I think?????
    for (var k in item) {
    
    // We have a number of members that we want to leave
    // just as they are, bypass them here.
        if (k.slice(0, 2) === '__') continue;
    
    // If the member we're working with is an object itself
    // we need to iterate over its members.
        if (typeof item[k] === 'object') {
      
            if (item[k].length > 0) {
                for (var i = 0, ii = item[k].length; i < ii; i++) {
          
          // We test to make sure the value is not empty.
                    if (item[k][i].hasOwnProperty('__test')) {
                        tmp = strreplace(item[k][i].__test);
                        if (!tmp) {
                            delete item[k][i];
                            continue;
                        }
                    }
          
                    item[k][i] = model.changeSpecReplacement(item[k][i], context);
                }
            } else {
                if (item[k].hasOwnProperty('__test')) {
                    tmp = strreplace(item[k].__test);
                    if (!tmp) {
                        delete item[k];
                        continue;
                    }
                }
                item[k] = model.changeSpecReplacement(item[k], context);
            }
    
    // If the member we're working with is not an object
    // we can just work with its value directly.
    // This is what we're trying to get to for every item.
    // replace() will keep being called deeper and deeper into
    // an object and everything has gotten here.
        } else {      
            item[k] = strreplace(item[k]);
      
      // Our __test doesn't seem to work on optional properties, in the view
      // we'll set empty, optional fields to the special value
      if (item[k] === '__deleteEmptyProperty') {
        delete item[k];
      }
        
      // Last check for fields that we are clearing by
      // sending an empty value.
      if (item[k] === '__setEmptyValue') {
        item[k] = '';
      }
        }
    }
  
    return item;
};

model.policyChangeSet = function (policyDoc) {
    var set       = null,
        templates = model.policyChangeSet.templates;
  
  set = model.changeSpec(policyDoc, templates);

    //XXX hacky!
    set.edit_term = function (changeObj) {
        var policy    = model.policy(policyDoc.InsurancePolicy),
      formatted = [],
            context   = templates.context(policyDoc, {}, 'edit_term'),
            out,
            effectiveDate  = policy.lastTerm.EffectiveDate,
            expirationDate = policy.lastTerm.ExpirationDate;

        for (var i in changeObj) if (changeObj.hasOwnProperty(i)) {
            formatted.push({$name: i, $value: changeObj[i]});
        }

        out = $.extend(true, {}, model.policyChangeSet.templates._skeleton, {
            Terms: {
                Term: {
                    EffectiveDate: effectiveDate,
                    ExpirationDate: expirationDate,
                    Changes: {
                        Set: {
                            DataItem: formatted
                        }
                    }
                }
            },
            EventHistory: { Event: {
                $type: 'DataCorrection',
                DataItem : formatted
            } }
        });
        return model.changeSpecReplacement(out, context);
    }
    
  return set;
}

model.transactionRequest = function (policyDoc) {
  var set       = null,
      templates = model.transactionRequest.templates;
  
  set = model.changeSpec(policyDoc, templates);
    
  return set;
};

// Certain actions that can be taken on policies are considered transations.
// These actions require different handling on the server than those that use
// Policy change sets. The xsd is very similar, but we'll set up a separate 
// model for it to allow for future changes that may cause it to differ more.
model.transactionRequest.templates = {
  _skeleton: {
    "__rootName": "TransactionRequest",
    $schemaVersion: "1.4",
    Initiation: {
      Initiator: {
        $type: "user",
        $: "{{user}}"}
    },
    Target: {
      Identifiers: {
        Identifier: {
          $name: "InsightPolicyId", 
          $value: "{{id}}"
        }
      },
      SourceVersion: "{{version}}"
    },
    EffectiveDate: "{{effectiveDate}}",
  },
  
  // Cancellation related change sets
  // Includes: Cancel, Set to pending cancel, Rescind pending cancel and Reinstate
  'cancellation': {
    $type: '{{pcsType}}',
    ReasonCode: "{{reasonCode}}",
    Comment: '{{comment}}'
  },
  
  'endorse': {
    $type: '{{transactionType}}',
    ReasonCode: '{{reasonCode}}',
    Comment: '{{comment}}',
    IntervalRequest: {
      StartDate: "{{effectiveDate}}"
    }
  },

  'change_customer': {
    $type: '{{transactionType}}',
    ReasonCode: "{{reasonCode}}",
    CustomerChanges: {
      Set: {}
    }
  },
  
  'change_additional_interest': {
    $type: '{{transactionType}}',
    ReasonCode: "{{reasonCode}}",
    CustomerChanges: {
      Set: {}
    }
  },
  
  'issue': {
    $type: '{{transactionType}}',
    AppliedDate: '__deleteEmptyProperty'
  },
  
  'renew': {
    $type: '{{transactionType}}',
    Comment: '{{comment}}'
  },
  
  'update_mortgagee' : {
    $type: '{{transactionType}}',
    ReasonCode: "53",
    CustomerChanges: {
      Set: {}
    }
  },
  
  // Make sure that all the members of our form object have values
  // that are valid. Especially for dates and documents.
  // NOTE: This is almost an exact copy of the PCS context method.
  // TODO: Learn a bit more about this so we can keep from DRY
  context: function (policyDoc, form, type) {
    var P  = policyDoc.InsurancePolicy || policyDoc,
        id = _itemGet(P.Identifiers.Identifier, 'InsightPolicyId'),
        possibleTimestamp,
        k;
      
    // Some special handling of documents and dates
    // NOTE: This type of for..in..if shit is no good. Very confusing.
    // We need to use something that is easier to follow. -tgaw
    for (k in form) if (form.hasOwnProperty(k)) {
      if (k.indexOf('Date') >= 0) {
    
        // I don't like having the check for '__delete...' here. We need
        // to figure out a different way to handle optional properties like it.
        if (form[k] && form[k] !== '__deleteEmptyProperty') {         
          form[k] = Date.parse(form[k]).toString('yyyy-MM-dd');
        }
      }
    }
    
    return $.extend(true, form, {
      user: CTX.user,
      id: id,
      version: P.Management.Version,
      timestamp: form.timestamp || (new Date()).toISOString(),
      datestamp: Date.today().toString('MM/dd/yy'),
      effectiveDate: form.effectiveDate || Date.today().toString('yyyy-MM-dd'),
      comment: form.comment || ''
    });
  }
};

// This is the most common (as of now) payload that needs to be sent to pxCentral
// to affect changes on a policy.
model.policyChangeSet.templates = {
    _skeleton: {
        "__rootName": "PolicyChangeSet",
        $schemaVersion: "3.1",
        Initiation: {
            Initiator: {
                $type: "user",
                $: "{{user}}"}
        },
        Target: {
            Identifiers: {
                Identifier: {$name:"InsightPolicyId", $value:"{{ id }}"}
            },
            SourceVersion: "{{ version }}"
        },
        EffectiveDate: "{{ effectiveDate }}",
        AppliedDate: "{{ appliedDate }}",
        Comment: "{{ comment }}"
    },

    'apply_charges' : {
        Ledger: {
            LineItem: {
                $value: '{{amount}}',
                $type: '{{lineItemType}}',
                $timestamp: '{{timestamp}}',
                Memo: {$:''}
            }
        },
        EventHistory: { Event: {
            $type: 'ChargeApplied',
            DataItem : [{
                $name: 'Amount',
                $value: '{{amount}}'
            },
            {
                $name: 'ReasonCode',
                $value: '{{reasonCode}}'
            },
            {
                $name: 'ReasonCodeLabel',
                $value: '{{reasonCodeLabel}}'
            }]
        } }
    },

    'issue_manual': {
        DocumentChanges: {
            Set: {
                DocumentRef: [
                {
          $type: model.ixlibrary.slugs.issue.docId,
                    $label: 'Policy New Business Package',
                    $href: '{{packageDocUrl}}',
                    $id: model.ixlibrary.slugs.issue.docId + '-{{idtimestamp}}'
                },
                {
                    __test: '{{declarationDoc}}',
                    $type: model.ixlibrary.slugs.issue.decId,
                    $label: 'Declaration of Coverage {{formattedMDY}}',
                    $href: '{{declarationDocUrl}}',
                    $id: 'DeclarationOfCoverage-{{idtimestamp}}'
                }]
            }
        },
        EventHistory: {
            Event: {
                $type: 'Issue'
            }
        }
    },

    'invoice' : {
    DocumentChanges: {
      Set: {
        DocumentRef: {
          $type: '{{documentType}}',
          $label: '{{documentLabel}}',
          $href: '{{documentHref}}',
                    $id: '{{documentId}}'
        }
      }
    },
        Ledger: {
            __test: '{{installmentCharge}}',
            LineItem: {
                $value: '{{installmentCharge}}',
                $type: 'INSTALLMENT_CHARGE',
                $timestamp: '{{timestamp}}',
                Memo: {$:''}
            }
        },
        AccountingChanges: {
            Set: {
                DataItem : [{
                    $name: 'InvoiceAmountCurrent',
                    $value: '{{InvoiceAmountCurrent}}'
                },
                {
                    $name: 'InvoiceDateCurrent',
                    $value: '{{InvoiceDateCurrent}}'
                },
                {
                    $name: 'InvoiceDateDueCurrent',
                    $value: '{{InvoiceDateDueCurrent}}'
                }]
            }
        },
        EventHistory: { Event: {
            $type: 'Invoice',
            DataItem : [{
                $name: 'InvoiceAmountCurrent',
                $value: '{{InvoiceAmountCurrent}}'
            },
            {
                $name: 'InvoiceDateCurrent',
                $value: '{{InvoiceDateCurrent}}'
            },
            {
                $name: 'InvoiceDateDueCurrent',
                $value: '{{InvoiceDateDueCurrent}}'
            }]
        } }
    },

    'make_payment': {
        Ledger: {
            LineItem: {
                $value: "{{paymentAmount}}",
                $type: "PAYMENT",
                $timestamp: "{{timestamp}}",
                Memo: '',
                DataItem: [
                    {$name: 'Reference', $value: '{{paymentReference}}'},
                    {$name: 'PaymentMethod', $value: '{{paymentMethod}}'}
                ]
            }
        },
        EventHistory: {
            Event: {
                $type: 'Payment',
                DataItem: [
                    {$name: 'PaymentAmount', $value: '{{positivePaymentAmount}}'},
                    {$name: 'PaymentMethod', $value: '{{paymentMethod}}'},
                    {$name: 'PaymentReference', $value: '{{paymentReference}}'},
                    {$name: 'PaymentBatch', $value: '{{paymentBatch}}'},
                    {$name: 'PostmarkDate', $value: '{{postmarkDate}}'},
                    {$name: 'AppliedDate', $value: '{{appliedDate}}'}
                ]
            }
        }
    },
  
  'generate_document': {
    DocumentChanges: {
      Set: {
        DocumentRef: {
          $type: '{{documentType}}',
          $label: '{{documentLabel}}',
          $href: '{{documentHref}}',
                    $id: '{{documentId}}'
        }
      }
    }
  },
  
    'premium_disbursement': {
        Ledger: {
            LineItem: {
                $value: "{{amount}}",
                $type: "DISBURSE",
                $timestamp: "{{timestamp}}",
                Memo: 'Return Premium',
                DataItem: [
                    {$name: 'Amount', $value: '{{amount}}'},
                    {$name: 'Reference', $value: '{{reference}}'}
                ]
            }
        },
        EventHistory: {
            Event: {
                $type: 'ReturnPremium',
                DataItem: [
                    {$name: 'Amount', $value: '{{amount}}'},
                    {$name: 'Reference', $value: '{{reference}}'}
                ]
            }
        }
    },
    'reverse_disbursement': {
        Ledger: {
            LineItem: {
                $value: "-{{amount}}", // NOTE: The negative here is important!
                $type: "REVERSE_DISBURSE",
                $timestamp: "{{timestamp}}",
                Memo: {$:''},
                DataItem: [
                    {$name: 'Amount', $value: '{{amount}}'},
                    {$name: 'Reference', $value: '{{reference}}'}
                ]
            }
        },
        EventHistory: {
            Event: {
                $type: 'VoidStopPay',
                DataItem: [
                    {$name: 'Amount', $value: '{{amount}}'},
                    {$name: 'Reference', $value: '{{reference}}'}
                ]
            }
        }
    },
    'reverse_payment': {
        Ledger: {
            LineItem: {
                $value: "{{paymentAmount}}",
                $type: "REVERSE_PAYMENT",
                $timestamp: "{{timestamp}}",
                Memo: {$:''},
                DataItem: [
                    {$name: 'Reference', $value: '{{paymentReference}}'},
                    {$name: 'PaymentMethod', $value: '{{paymentMethod}}'}
                ]
            }
        },
        EventHistory: {
            Event: {
                $type: 'Chargeback',
                DataItem: [
                    {$name: 'Amount', $value: '{{paymentAmount}}'},
                    {$name: 'Reference', $value: '{{paymentReference}}'},
                    {$name: 'PaymentMethod', $value: '{{paymentMethod}}'}
                ]
            }
        }
    },
  
    'change_payment_plan': {
    Intervals: {
      Interval: {
        StartDate: '{{startDate}}',
        EndDate: '{{endDate}}',
        Changes: {
          Set: {
            DataItem: [
              {
                $name: 'OpPaymentPlanType',
                $value: '{{paymentPlanType}}'
              },
              {
                $name: 'PaymentPlanType',
                $value: '{{paymentPlanType}}'
              }
            ]
          }
        }
      }
    },
        PaymentPlan: {
            $type: "{{paymentPlanType}}",
            Installments: {}
        },
        EventHistory: {
            Event: {
                $type: 'Endorse',
                DataItem: [
                    {
            $name: 'reasonCode', 
            $value: '155'
          },
                    {
            $name: 'reasonCodeLabel', 
            $value: 'Change Payment Plan'
          },
                    {
            $name: 'AppliedDate', 
            $value: '{{appliedDate}}'
          },
          {
            $name: 'OpPaymentPlanType',
            $value: '{{paymentPlanType}}'
          },
                    {
            $name: 'PaymentPlanType', 
            $value: '{{paymentPlanType}}'
          }
                ]
            }
        }
    },

    //update_mortgagee special cased above
    'update_risk': {
        Intervals: {
            Interval: {
                StartDate: "{{appliedDate}}",
                DataItem: [
                    {$name: "SquareFootUnderRoof", $value: "{{squareFootUnderRoof}}"},
                    {$name: "ReplacementCostBuilding", $value: "{{replacementCostBuilding}}"}
                ]
            }
        },
        EventHistory: {
            Event: {
                $type: "Endorse",
                DataItem: [
                    {$name: 'AppliedDate', $value: '{{appliedDate}}'},
                    {$name: 'EffectiveDate', $value: '{{effectiveDate}}'},
                    {$name: 'reasonCode', $value: '85'},
                    {$name: 'reasonCodeLabel', $value: 'Change Rating Characteristics Based On Physical Inspection'},
                    {$name: "SquareFootUnderRoof", $value: "{{squareFootUnderRoof}}" },
                    {$name: "ReplacementCostBuilding", $value: "{{replacementCostBuilding}}" }
                ]
            }
        }
    },

  // Write off charges
    'write_off' : {
        Ledger: {
            LineItem: {
                $value: '-{{amount}}',
                $type: 'WRITE_OFF_CHARGE',
                $timestamp: '{{timestamp}}',
                Memo: 'Installment Charge',
                DataItem: [
                    {$name:"Reference", $value:"{{reasonCodeLabel}}"}
                ]
            }
        },
        EventHistory: { Event: {
            $type: 'WriteOffCharge',
            DataItem : [
                {$name: 'Amount', $value: '{{amount}}'},
                {$name: 'Reference', $value: '{{reasonCodeLabel}}'}
            ]
        } }
    },
  
  // Make sure that all the members of our form object have values
  // that are valid. Especially for dates and documents.
    context: function (policyDoc, form, type) {
        var P  = policyDoc.InsurancePolicy || policyDoc,
            id = _itemGet(P.Identifiers.Identifier, 'InsightPolicyId'),
            possibleTimestamp,
            k;
      
    // Some special handling of documents and dates
    // NOTE: This type of for..in..if shit is no good. Very confusing.
    // We need to use something that is easier to follow. -tgaw
        for (k in form) if (form.hasOwnProperty(k)) {
            if (k.indexOf('Doc') >= 0) {
        
        // I'm not sure why the IXLIB_BASE is needed here
        
        try {
          form[k + 'Url'] = IXLIB_BASE + model.ixlibrary.policy.url(id, form[k]).replace(/(\/)?ixlibrary(\/)?/, "");
        } catch(e) {}
 
            } else if (k.indexOf('Date') >= 0) {
        
                if (form[k]) {
          form[k] = Date.parse(form[k].replace('.000Z','Z')).toISOString();
        }
            }
        }
    
        return $.extend(true, form, {
            user: CTX.user,
            id: id,
            version: P.Management.Version,
            timestamp: form.timestamp || (new Date()).toISOString(),
            datestamp: Date.today().toString('MM/dd/yy'),
            effectiveDate: form.effectiveDate || Date.today().toISOString(),
            appliedDate: form.appliedDate || Date.today().toISOString(),
            comment: form.comment || 'posted by mxAdmin'
        });
    }
};
