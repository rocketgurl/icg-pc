/**
 * Core Javascript ics360 library
 *
 * This file provides a namespace for services adapters.
 *
 * Depends on jQuery 1.6.1+
 *
 * @author Daniel Lacy
 * @author Elijah Insua
 * @author Tyler Gaw
 */
var com = {};
window.com = com;

com.ics360 = function () {
    // Public scope
    var _ret = {
      
      // We'll store information about requests being made, the module
      // the came from, the method and the number of attempts.
      serviceRequests: {},
      
		  // Get an object Code=>Text
		  // 
		  // return {Object}
      getHttpCodes: function () {
        return {
          400:'Bad Request',
          401:'Unauthorized',
          402:'Payment Required',
          403:'Forbidden',
          404:'Not Found',
          405:'Method Not Allowed',
          406:'Not Acceptable',
          407:'Proxy Authentication Required',
          408:'Request Timeout',
          409:'Conflict',
          410:'Gone',
          411:'Length Required',
          412:'Precondition Failed',
          413:'Request Entity Too Large',
          414:'Request-URI Too Long',
          415:'Unsupported Media Type',
          416:'Requested Range Not Satisfiable',
          417:'Expectation Failed',
          500:'Internal Server Error',
          501:'Not Implemented',
          502:'Bad Gateway',
          503:'Service Unavailable',
          504:'Gateway Timeout',
          505:'HTTP Version Not Supported'
        }
      },
      
      // If an request to a service fails with a 50x error we want to
      // attempt the request until it is either successful or it tries
      // the max number of allowed times.
      // 
      // @param OBJECT options - method: FUNCTION,
      //                         args: OBJECT (the arguments array-like object),
      //                         reachedMaxAttempts: FUNCTION
      requestRetry: function (options) {
        var maxAttempts = 3,
            
            requests = com.ics360.serviceRequests,
            
            methodParts = options.method.split('.'),
            
            // For now we're going to assume that all requests
            // are made from com.ics360 modules.
            // NOTE: This may be too brittle
            module = methodParts[2],
            
            // The method we need to retry
            method = methodParts[3];
        
        // We'll add the method to our requests object so we can
        // track the number of times it has been attempted
        if (!requests[module]) {
          requests[module] = {};
        }
        
        if (!requests[module][method]) {
          requests[module][method] = {};
          requests[module][method].attempts = 0;
        }          
        
        requests[module][method].attempts += 1;
        
        // We're going to assume the method is of the com.ics360
        // object for now. If this expands we can make it smarter.
        if (requests[module][method].attempts < maxAttempts) {
          com.ics360[module][method].apply(this, options.args);
        } else {
          options.reachedMaxAttempts();
        }
        
        // We don't want the user to just sit with a "loading..."
        // NOTE: This is a bit too tied to the markup for long-term
        if (requests[module][method].attempts === 2) {
          $('#siteLoading p').html("It's taking a bit longer to load Agent Portal than normal. <br>You can either refresh and try again or wait a little longer for it to load.");
        }
      },
      
		  // Build an error callback for ajax requests
		  // 
		  // This method is meant to be a callback on jQuery.ajax's error or
		  // complete depending on when
		  // 
		  // @return {Function} 
      ajaxError: function (currentMethod, severity, callback, methodArguments) {
              
        var errors = _ret.getHttpCodes();
		  	
        return function (xhr, errorText) {
          var errorMetadata = {
                severity: severity,
                xhr: xhr,
                errorStack: [currentMethod],
                caller: currentMethod
              };
      
          try {
            errorMetadata.statusCode = (xhr.getResponseHeader('X-True-Statuscode')) ? 
                                          (~~xhr.getResponseHeader('X-True-Statuscode')) : 
                                          xhr.status;
          }
          catch (e) {
            //at this point error text is set as "timeout"
          }
		  					
          if (errorText === "parsererror") {
            // This is used to hotwire the response to success.  In the case of pxprogram, 
            // when there are no items in a collection it will return html.
            var fakeData = null;
                          
            switch (this.contentType) {
            // object based
            case 'json':
            case 'jsonp':
              fakeData = {};
              break;
            
            // text based
            case 'html':
            case 'text':
              fakeData = '';
              break;
            }
            
            // send off our faked data and allow the caller to handle this properly.
            this.success(fakeData);
            return true;                  
                          
          } else if (errorText === "timeout") {
            errorMetadata.message = "timeout";
            errorMetadata.details = {service: currentMethod};
                          
            // Emit an error
            $(document).trigger("com.ics360.error", [errorMetadata]);
                          
            // error'ed return false;
            return false;           
               
          } else if (errors[errorMetadata.statusCode]) {
            errorMetadata.message = errors[errorMetadata.statusCode];
            errorMetadata.details = {service: currentMethod};
                          
            // Emit an error
            try {
              
              // If we recieved methodArguments and the user is authorized, 
              //we'll attempt to retry the service call
              if (methodArguments && errorMetadata.statusCode !== 401) {
                com.ics360.requestRetry({
                  method: currentMethod,
                  args: methodArguments,
                  reachedMaxAttempts: function () {
                    // Emit an error
                    jQuery(document).trigger("com.ics360.error", [errorMetadata]);
                    callback(true, null);
                  }
                });
              } else {
                jQuery(document).trigger("com.ics360.error", [errorMetadata]);
                callback(true, null);
              }
		  					
            } catch (e) {}
		  				
            // error'ed return false;
            return false;
          }
      
          // no error.. return true
          return true;
        };
      },
          
		  // Setup an ajax request to use crippled client
		  // 
		  // @param {Object} xhr
		  //         
      ajaxCrippledClient : function (method, extra) {
              var _extra = extra;
              
              // add more items to the array when you want to override default headers
              var _toClean = ["Accept"];
              
              return function(xhr) {
                  xhr.setRequestHeader('X-Crippled-Client', 'yes');
                  // PC 2.0 - CORS
                  // xhr.setRequestHeader('X-Method', method);
                  xhr.setRequestHeader('X-Rest-Method', method);
      
                  if (_extra) {
                      var split = [];
                      for (var i=0; i<_extra.length; i++) {
                          split = _extra[i].split(':');
                          
                          // Never clean headers in webkit, it just appends a ,, and moves on.
                          if (navigator.userAgent.toLowerCase().indexOf("applewebkit") === -1) {
                              xhr.setRequestHeader(split[0], '');
                          }
                          xhr.setRequestHeader(split[0], split[1].replace(/^ *| *$/, ''));
                      }
                  }
              };
          },
		  
		  // Special check for cipple client support
		  ajaxCrippleClientSuccess: function (xhr) {
		  	// perform crippled client checks
		  	var crippledStatus = (xhr.getResponseHeader('X-True-Statuscode')) ? 
		  	                      (~~xhr.getResponseHeader('X-True-Statuscode')) : 0;
      
		  	// Requests to crippled client enabled services should ALWAYS respond with status = 200
		  	// This means that all crippled client statuses need be under crippled status
		  	if (crippledStatus < 400) {
      
		  	    // Ripped from http://jqueryjs.googlecode.com/svn/trunk/jquery/src/ajax.js Line:513
		  	    try {
      
		  	        // IE error sometimes returns 1223 when it should be 204 so treat it as success, see #1450
		  	        return !xhr.status && location.protocol === "file:" ||
		  	            // Opera returns 0 when status is 304
		  	            ( xhr.status >= 200 && xhr.status < 300 ) ||
		  	            xhr.status === 304 || xhr.status === 1223 || xhr.status === 0;
      
		  		} catch(e){}
		  	}
      
		  	return false;
		  },
		          
		  // Create a url with a random query string to prevent caching
		  // @param {String} url
		  // @return {String}
      noCacheUrl: function (url) {
            var marks = url.match(/\?/);
            var delim = (marks && marks.length && marks.length > 0) ? "&" : "?";  
            return url + delim + (new Date()).getTime() + Math.random();  
          }
          
    };
    return _ret;
}();

/* extend array to provide a remove function */
Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length);
  this.length = from < 0 ? this.length + from : from;
  return this.push.apply(this, rest);
};

/**
 * Error handling for ics360 libraries
 * 
 * Depends on jQuery 1.3+
 * 
 * Description of functionality
 * ----------------------------
 * 
 * Upon inclusion (as a 'module') this script 
 * will attach an error handler for events
 * of type "com.ics360.error" onto the document 
 * 
 * Whenever a module throws an error, it should be
 * done by triggering a com.ics360.error event with
 * as much pertinent information as possible.  Some
 * things to include are: 
 *  + caller library (Object)
 *  + message
 *  + severity
 *  etc..
 *  
 *  Example:
 *   jQuery(document).trigger("com.ics360.error", [{caller:com.ics360.ixconfig, message:'document not ready','SEVERE'}]);
 * 
 *  Note: this is used for delegating events to other event handlers, such as Login Failure, Permission Denied, Etc.
 * 
 *  Delegation is done as follows.
 *   
 *   
 *   TODO: figure out exactly how this should work.
 *   jQuery(document).trigger("com.ics360.error.SEVERE", [{caller:com.ics360.ixconfig, message:'document not ready','SEVERE'}]);
 *  
 * 
 */
com.ics360.error = (function() {
    // ** Setup private scope **
    var _ret = {};
    
    var _defaultErrorMetadata = {
        severity: 'DEBUG',
        caller: '',
        message: 'no message provided',
        eventStack: []
    };
    
    
    /**
     * Event handler
     * 
     * @param {Object} event
     * @param {Object} metadata
     */
    _ret.errorDelegator = function(event, metadata)
    {
        var meta = jQuery.extend(_defaultErrorMetadata, metadata);

        // ** Log to ixlog if log is loaded **
        if (com.ics360.ixlog.initialized)
        {
            var details = {};
            details.service = metadata.caller || event.type;
            details.username = com.ics360.ixdirectory.getUserLogin();

            var callerSplit = meta.caller.split(".");
            var callerMethod = callerSplit.pop();
            var callerLibrary = callerSplit.pop();
            
     
            if (meta.statusCode && meta.statusCode > 499 && meta.statusCode < 600) {
                meta.severity = "SEVERE";
                meta.message = com.ics360.getHttpCodes()[meta.statusCode];
            }

            var code = (meta.statusCode) ? " with code " + meta.statusCode : '';
            
            // Setup error params (level, message, logClass, detail, method, tags, thread, user)
            var logArguments = [meta.severity, 
                                callerLibrary + "::" + callerMethod + " failed" + code + ". (" + meta.message + ")",
                                'error',
                                JSON.stringify(details), 
                                meta.caller, 
                                '', 
                                '', 
                                com.ics360.ixdirectory.getUserLogin()];
            
            // Log the error
            jQuery(document).trigger('ixlog.log', logArguments);
        }
        
        // ** Route off to a subset of the namespace (error.com.ics360.<library>) **
        jQuery(document).trigger("error." + meta.caller, [meta]);
        // ** Delegate the error to other listeners **
        if (meta.errorStack) {
            for (var i = 0; i < meta.errorStack.length; i++) {
                jQuery(document).trigger(meta.errorStack[i], [meta]);
            }
        }
    };

    // ** Setup error delegator **
    jQuery(document).ready(function() {
        jQuery(document).bind("com.ics360.error", _ret.errorDelegator);
    });
         
     // ** Setup public scope **
     return _ret;
})();

/**
 * ixDirectory Adapter
 * 
 * Depends on com.ics360.js
 * Depends on XMLObjTree.js
 * 
 */
com.ics360.ixdirectory = (function () {
    
	// Setup Private Scope
    var _identity           = null,
		_username           = null,
		_password           = null,
		_ixdirectoryUrl     = null,
		_ixdirectoryPostUrl = null,
		_authorizationHash  = null,
		_collections        = {},
		_agencyUserNames    = null,
		_agencyDetails      = null,
		_ret                = null;

    // Setup the actual com.ics360.ixdirectory object
    _ret = {
		
		// Initialize the ixdirectory adapter
		// 
		// @param String ixdirectoryUrl
    init: function (ixdirectoryUrl) {
            _ixdirectoryUrl = ixdirectoryUrl;
            _ixdirectoryPostUrl = ixdirectoryUrl;
        },
		
		// Load an identity asynchronously.
		// 
		// Note: if you request an identity without the password, this method
		//       will attempt to load the identity using previously stored
		//       credentials.
		// 
		// The callback param takes 1 argument which is the resulting
		// jQuery'd xml doc from the response
		// 
		// @param string   username
		// @param string   password
		// @param function callback
		// @return null
    loadIdentity: function (username, password, callback, raw) {
			var authHash  = '',
			    args      = arguments,
				  ajaxError = com.ics360.ajaxError('com.ics360.ixdirectory.loadIdentity', 'INFO', callback, args);
			
			if (username && password) {
			    _username = username;
			    _password = password;
			    _authorizationHash = Base64.encode(username + ':' + password);
			}
			
      // allow for retrieval of other users
      authHash = _authorizationHash;
      
      // Parse ixDirectory
      jQuery.ajax({
        url: com.ics360.noCacheUrl(_ixdirectoryUrl + 'identities/' + username),
        type: "POST",
        
        // Removing this as of 1.2.1. ixDirectory will have a content-type of application/xml
        // if the request is not a 401. If a 401 is given back, the content-type will be text/plain.
        // This causes a parseerror in Firefox as it should.  
        dataType: raw ? "text" : null,
        beforeSend: com.ics360.ajaxCrippledClient("GET", ['X-Authorization: Basic ' +  authHash]),
        error: ajaxError,
        success: function (xml, status, xhr) {
	        var data,
		          crippleSuccess = com.ics360.ajaxCrippleClientSuccess(xhr);
	
	        // Extra check for cripple client support					
	        if (crippleSuccess) {
		        data = (raw) ? xml : jQuery(xml);
	
		        // if a login attempt, save the identity for later
		        if (username && password) {
		          _identity = jQuery(data);
	
		          if ($.isFunction(callback)) {
				        callback(false, _ret);
		          }
	
		        // retrieve another user's identity
		        // I don't understand this - tgaw
		        } else {
		          if ($.isFunction(callback)) {
		            callback(false, data);
		          }
		        }
	        } else {
		        ajaxError(xhr, status);
	        }
        }
      });
    },
		
		// getAuthorizationHash
		// 
		// @param String
   // PC 2.0 ALERT
    // We are short circuiting this to use the Auth Digest passed into
    // the iFrame as a data attribute from the PolicyModule.
    getAuthorizationHash: function () {
      if (mxAdmin.AUTH !== undefined || mxAdmin.AUTH !== null) {
        return mxAdmin.AUTH;
      }
      return false;
    },

		// Get the current config object
		// 
		// @return Object
    getUserIdentity: function () {
        return _identity;
    },

		// Get the current User's Login
		// 
		// @return string
    getUserLogin: function () {
        return _username;
    },

		// Get the current User's Password
		// 
		// @return string
    getUserPassword: function () {
        return _password;
    },

		// Get the current User's Display Name
		// 
		// @return string
    getUserDisplayName: function () {
        return _ret.getUserIdentity().find("Name").text();
    },

		// Get the current User's Email Address
		// 
		// @return string
    getUserEmail: function () {
        return _ret.getUserIdentity().find("Email").text();
    },

		// Get the current User's Phone Number
		// NOTE: This appears to be an optional piece of data - tgaw
		// @return string
    getUserTelephone: function () {
        return _ret.getUserIdentity().find("DataItem[name=phoneNumber]").attr("value");
    },

		// Get the current User's locationId
		// NOTE: This appears to be an optional piece of data - tgaw
		// @return Object
    getUserLocationId: function () {
        return _ret.getUserIdentity().find("Affiliation[type=agent_location]").attr("target");
    },

		// Get the current User's default programID. They should only have one.
		//
		// @depends on ixConfig
		// 
		// Note: There's nothing in ixDirectory that allows a user to have a Primary program 
		//       so we're basing it off the first one we find.
		// 
		// @return array
    getUserProgramId: function () {
    
      var programAffiliation = _ret.getUserIdentity().find("Affiliation[type=identity_program]"),
          programsLength     = programAffiliation.length;
				
			try {
				organizationId = new RegExp(com.ics360.ixconfig.getConfig().application.organizationId, "i");
			} catch (e) {
				throw new Error('ics360.ixdirectory.getUserProgramId() depends on a valid ixConfig configuration');
				return null;
			}
			
      if (programsLength > 1) {
          for (var i = 0; i < programsLength; i++) {
              var thisProgram = jQuery(programAffiliation[i]);
      
              if (thisProgram.attr("target").search(organizationId) !== -1) {
                  return thisProgram.attr("target");
              }
          }
      } else {
          return programAffiliation.attr("target");
      }
    },

		// Get the current User's default organizationID. They should only have one.
		// 
		// Note: does not handle sidecase where a users identity has multiple affiliations 
		// 
		// @return string
    getUserCompanyId: function () {
        return _ret.getUserIdentity().find("Affiliation[type=employee_company]").attr("target");
    },

		// Get the current identity's role as text.
		// 
		// @depends on ixConfig
		// 
		// @return string
		//
		// TODO: Don't getConfig().application for each item below, just get it once and reuse it.
    getUserRole: function () {
        return _ret.getUserIdentity().find("ApplicationSettings" +
            "[applicationName=" + com.ics360.ixconfig.getConfig().application.applicationName + "]" +
            "[organizationId=" + com.ics360.ixconfig.getConfig().application.organizationId + "]" +
            "[environmentName=" + com.ics360.ixconfig.getConfig().application.environmentName + "]" +
            " roles").text();
    },

		// Get the organization's attachment notes.
		// 
		// @return array
    getLocationFiles: function () {
        return _ret.getAgencyDetails().find("Notes Note Attachment");
    },

		// Get the organization's Program Affiliation.
		// 
		// @return string
    getLocationProgramId: function () {
        return _ret.getAgencyDetails().find("Affiliation[type=organization_program][side=organization]").attr("target");
    },

		// Get all Users in the same locationId as our current ixDirectory admin.
		// 
		// @return xml
    getAgencyAgents: function () {
        return _agencyUserNames || false;
    },

		// Load Agency Agents asynchronously
		// 
		// @param {Object} callback
		// @return null
    loadAgencyAgents: function (callback) {
      jQuery.ajax({
        url: com.ics360.noCacheUrl(_ixdirectoryUrl + 'identities/?AgentsOfLocation=' + _ret.getUserLocationId()),
        dataType: "xml",
        type: "POST",
        beforeSend: com.ics360.ajaxCrippledClient("GET", ['X-Authorization: Basic ' +  _authorizationHash, "X-Accept: application/xml"]),
        error: com.ics360.ajaxError('com.ics360.ixdirectory.loadAgencyAgents','SEVERE'),
        success: function (xml) {
          _agencyUserNames = xml;
          
          if (callback && jQuery.isFunction(callback)) {
              callback.call(_ret, xml);
          }
        }
      });
    },

		// Get the Agency Identity from the locationId of our current ixDirectory admin.
		// 
		// TODO: differentiate between raw:extended/jquery'd:extended and raw/jquery'd
		//       - could cause some problem with the raw representation as the developer
		//         cannot possibly know the state in which the representations are, without
		//         doing another load. (caching)
		// 
		// @return xml or false
    getAgencyDetails: function (raw, extended) {
        raw = raw || false;
        extended = extended || false;
        
        // check for cached agency details (see above todo)
        if (_agencyDetails) {
            return (raw) ? _agencyDetailsRaw : _agencyDetails;
        }
        else
        {
            return false;
        }
    },

		// Load Agency Details Asynchronous
		// 
		// @param {Object} callback
		// @return null
    loadAgencyDetails: function (callback, raw, extended, agencylocationid) {
        extended = extended || false;
        raw = raw || false;
        var url = _ixdirectoryUrl + "organizations/";
        url += (agencylocationid) ? agencylocationid : _ret.getUserLocationId();
        url += (extended) ? "?mode=extended" : '';
        jQuery.ajax({
            url        : com.ics360.noCacheUrl(url),
            dataType   : raw ? "text" : "xml",
            beforeSend : com.ics360.ajaxCrippledClient("GET", ['X-Authorization: Basic ' +  _authorizationHash]),
            error      : com.ics360.ajaxError('com.ics360.ixdirectory.loadAgencyDetails','SEVERE'),
            success    : function(xml)
            {
                _agencyDetails = raw ? xml : jQuery(xml);
                _agencyDetailsRaw = xml;
                if (callback && jQuery.isFunction(callback)) {
                    callback.call(_ret, _ret.getAgencyDetails(raw));
                }
            }
        });
    },

		// Save the agency details asynchronously
		// 
		// {Street1:'',Street2:'',Street3:'',City:'',County:'',Province:'',PostalCode:'',Country:''}
		// 
		// This is done to avoid re-generating whole representation and possibly
		// losing data.
		// 
		// 
		// @param Object data
		// @param Function callback
		// @return null
    updateAgencyDetails: function (data, callback) {
        
        _ret.loadAgencyDetails(function(raw) 
        {
            raw = raw + "";
            var toReplace = raw.match(/<Address type="mailing">(.+)<\/Address>/ig)[0];
            var replaceWith = toReplace;
            
            function setAddressValue(key, value)
            {
                var regex = new RegExp("<" + key + "[^\/]*\/>|<" + key + "[\\W]*>[^<]+<\/" + key + ">", "gi");
                replaceWith = replaceWith.replace(regex, "<" + key + ">" + value + "</" + key + ">");
            }
            
            jQuery("form fieldset.mailing input").each(function() {
                setAddressValue(jQuery(this).attr("name"),jQuery(this).val());
            });
            var toPut = raw.replace(toReplace, replaceWith);
    
            toPut = toPut.replace(/<DataItem[ ]+name="PhoneNumber"[^\/]+\/>/,'<DataItem name="PhoneNumber" value="' + data.PhoneNumber  + '" />');
    
            // clean Affiliations
            jQuery.ajax({
                url         : _ixdirectoryPostUrl + "organizations/" + _ret.getUserLocationId(),
                dataType    : "xml",
                type        : 'POST',
                contentType : 'application/xml',
                data        : toPut,
                beforeSend  : com.ics360.ajaxCrippledClient("PUT", ['X-Authorization: Basic ' +  _authorizationHash]),
                error       : com.ics360.ajaxError('com.ics360.ixdirectory.updateAgencyDetails','SEVERE'),
                success     : function(xml)
                {
                    _agencyDetails = jQuery(xml);
                    if (callback && jQuery.isFunction(callback)) {
                        callback.call(_ret, _ret.getAgencyDetails());
                    }
                }
            });                
        }, true, false); // raw and not extended
    },

		// TODO: Document this method
		// 
		// @param {Object} data  {email,name,password,company,location,program, programLabel}
		// @param {Object} callback
    addIdentity: function (data, callback) {
        var environment = com.ics360.ixconfig.getConfig().application.environmentName;
    
        data = jQuery.extend({
            program: "",
            programLabel: "",
            location: "",
            organization: "",
            environment : "",
            name : "",
            email : "",
            identity: "",
            telephone : "",
            admin : null,
            fax : "",
            roles : []
            
        }, data);
    
        // process data
        var userIdentityString = '<Identity id="' + data.identity + '" password="' + data.password + '" apiVersion="2" archived="false">' +
            '<Name>' + data.name + '</Name><Email>' + data.email + '</Email>' +
            '<DataItem name="phoneNumber" value="' + data.telephone + '"/>' +
            '<DataItem name="faxNumber" value="' + data.fax + '"/>' +
            '<DataItem name="serviceSetName" value="' + data.programLabel + '"/>' +
            '<Affiliation target="' + data.location + '" type="agent_location" side="agent" />' +
            '<Affiliation target="' + data.program + '" type="identity_program" side="identity"/>';
    
            // If admin was selected, add ixDirectory role.
            // Note: organizationId should always be "ics".
            if (data.admin && data.admin === true) {
                userIdentityString += '<ApplicationSettings applicationName="ixdirectory" organizationId="ics" environmentName="' + environment + '">' + 
                    '<roles>location_own_admin</roles>' +
                    '</ApplicationSettings>';
            }
    
            userIdentityString += '<ApplicationSettings applicationName="pxserver" organizationId="' + data.organization + '" environmentName="' + environment + '">' + 
            '<DataItem name="SecurityClearanceLevel" value="3"/>' +
            '<Roles>';
    
            for (var i=0; i<data.roles.length; i++) {
                userIdentityString += '<Role id="' + data.roles[i] + '"/>';
            }
    
            // If admin was selected, add the pxServer role.
            if (data.admin && data.admin === true) {
                userIdentityString += '<Role id="AGENCY_OWN_ADMINISTRATOR"/>';
            }
    
            userIdentityString += '</Roles>' +
                '</ApplicationSettings>' +
            '</Identity>';
    
        // send request
        jQuery.ajax({
            type        : "POST",
            url         : _ixdirectoryPostUrl + "identities/",
            contentType : "application/xml",
            dataType    : "application/xml",
            beforeSend  : com.ics360.ajaxCrippledClient("POST", ['X-Authorization: Basic ' +  _authorizationHash]),
            error       : com.ics360.ajaxError('com.ics360.ixdirectory.addIdentity','SEVERE'),
            data        : userIdentityString,
            success     : function(response)
            {
                if (callback && jQuery.isFunction(callback)) {
                    callback.call(_ret);
                }
            }
        });
    },
        
		// TODO: Document this method
		// 
		// @param {Object} data  {email,name,password,company,location,program}
		// @param {Object} callback
    updateIdentity: function (data, callback) {
        var environment = com.ics360.ixconfig.getConfig().application.environmentName;
        var organization = com.ics360.ixconfig.getConfig().application.organizationId;
    
        data = jQuery.extend({
            program: "",
            programLabel: "",
            location: "",
            organization: "",
            environment : "",
            name : "",
            email : "",
            identity: "",
            telephone : "",
            admin : null,
            fax : ""
        }, data);
    
        _ret.loadIdentity(data.identity, false, function(err, rawIdentity){
            // replace vars with new data.
            rawIdentity = rawIdentity + "";
    
            // Change Password
            // <Identity passwordHash="...">
            if (data.password && data.password.length > 0) {
                rawIdentity = rawIdentity.replace(/passwordHash="[^"]+"/i,'password="' + data.password + '"');
            }
    
            // change name
            // <Name>John Doe</Name>
            rawIdentity = rawIdentity.replace(/<Name[ ]*\/>|<Name>[^<]+<\/Name>/i,'<Name>' + data.name + '</Name>');
    
            // change email
            // <Email>johnd@acme.com</Email>
            rawIdentity = rawIdentity.replace(/<Email[ ]*\/>|<Email>[^<]+<\/Email>/i,'<Email>' + data.email + '</Email>');
    
            // change phonenumber
            // <DataItem name="phoneNumber" value=" "/>
            rawIdentity = rawIdentity.replace(/<DataItem[ ]+name="phoneNumber"[ ]+value="[^"]*"/i,'<DataItem name="phoneNumber" value="' + data.telephone + '"');
    
            // change faxnumber
            // <DataItem name="faxNumber" value=" "/>
            rawIdentity = rawIdentity.replace(/<DataItem[ ]+name="faxNumber"[ ]+value="[^"]*"/i,'<DataItem name="faxNumber" value="' + data.fax + '"');
    
            var pxServerPos = rawIdentity.indexOf('ApplicationSettings applicationName="pxserver" organizationId="' + organization + '" environmentName="' + environment + '">');
            var ixDirextoryPos = rawIdentity.indexOf('<ApplicationSettings applicationName="ixdirectory" organizationId="ics" environmentName="' + environment + '">');
    
            // change admin status
            if (data.admin === true && data.admin !== "pass") {
                // Add ixDirectory role
                if (ixDirextoryPos < 0) {
                    rawIdentity = rawIdentity.replace(/<ApplicationSettings[ ]+applicationName="pxserver"/i,'<ApplicationSettings applicationName="ixdirectory" organizationId="ics" environmentName="' + environment + '"><roles>location_own_admin</roles></ApplicationSettings><ApplicationSettings applicationName="pxserver"');
                }
                else {
                    // Do something if they already have an ixDirectory app setting.
                }
                // Add pxServer role
                if (rawIdentity.indexOf('AGENCY_OWN_ADMINISTRATOR', pxServerPos) < 0) {
                    var pxRolesPos = rawIdentity.indexOf('<Roles>', pxServerPos) + 7;
                    rawIdentity = rawIdentity.substr(0, pxRolesPos) + '<Role id="AGENCY_OWN_ADMINISTRATOR" />' + rawIdentity.substr(pxRolesPos, rawIdentity.length);
                }
                else {
                    // Do something if they already have administrator in the designated pxServer.
                }
            }
            else if (data.admin === false && data.admin !== "pass") {
                // Remove ixDirectory role
                if (ixDirextoryPos > 0) {
                    var ixdirectoryRole = new RegExp('<ApplicationSettings applicationName="ixdirectory" organizationId="ics" environmentName="' + environment + '"><roles>\\w*<\/roles><\/ApplicationSettings>', 'i');
                    rawIdentity = rawIdentity.replace(ixdirectoryRole,'');
                }
                // Remove pxServer role
                if (rawIdentity.indexOf('AGENCY_OWN_ADMINISTRATOR', pxServerPos) > 0) {
                    var agencyOwn = new RegExp('<Role id="AGENCY_OWN_ADMINISTRATOR"\\s\/>', 'i');
                    rawIdentity = rawIdentity.replace(agencyOwn,'');
                }
            }
    
            // send request
            jQuery.ajax({
                url         : _ixdirectoryPostUrl + "identities/" + data.identity,
                type        : "POST",
                dataType    : "xml",
                contentType : "application/xml",
                beforeSend  : com.ics360.ajaxCrippledClient("PUT", ['X-Authorization: Basic ' +  _authorizationHash]),
                error       : com.ics360.ajaxError('com.ics360.ixdirectory.addIdentity','SEVERE'),
                data        : rawIdentity,
                success     : function(response)
                {
                    if (callback && jQuery.isFunction(callback)) {
                        callback.call(_ret);
                    }
                }
            });
        }, true);
    },
        
		// Remove an Identity Asynchronously
		// 
		// @param {Object} email
		// @param {Object} callback
    deleteIdentity: function (login, callback) {
        // Parse ixDirectory
        jQuery.ajax({
            url        : _ixdirectoryPostUrl + 'identities/' + login,
            type       : "POST",
            beforeSend : com.ics360.ajaxCrippledClient("DELETE", ['X-Authorization: Basic ' +  _authorizationHash]),
            error      : com.ics360.ajaxError('com.ics360.ixdirectory.deleteIdentity','SEVERE'),
            success    : function() 
            {
                if (callback && jQuery.isFunction(callback)) {
                    callback.call(_ret);
                }
            }
        });
    },
        
		// Retrieve the cached version of notes/attachments
		// 
		// @return jQuery object or false
    getNotes: function () {
      return _collections.notes || false;
    },
        
		// Asynchronously retrieve notes/attachments
		// 
		// @param {Object} callback
    loadNotes: function (callback, raw) {
      jQuery.ajax({
        url        : com.ics360.noCacheUrl(_ixdirectoryPostUrl + "organizations/" + _ret.getUserLocationId() + "/notes"),
        type       : "GET",
        dataType   : "xml",
        beforeSend : com.ics360.ajaxCrippledClient("GET", ['X-Authorization: Basic ' +  _authorizationHash, "Content-type: application/xml"]),
        error      : com.ics360.ajaxError('com.ics360.ixdirectory.loadNotes','SEVERE'),
        success    : function(data) 
        {
          _collections.notes = data;
          if (callback && jQuery.isFunction(callback)) {
              callback.call(_ret, _ret.getNotes());
          }
        }
      }); 
    },
        
		// Add a note asynchronously
		// 
		// callback returns the ajax config object
		// 
		// @param {String} content
		// @param {String} source (user|system)
		// @param {Object} attachment {name:'',contentType:'',description:'',location:''}
    createNote: function (content, source, attachment, callback) {
      if (attachment){ 
          attachment = jQuery.extend({name:'',contentType:'text/plain',description:'',location:''}, attachment);
      }
      
      var xml = '<Note source="' + source + '">';
      
      xml += "<Content>" + content + "</Content>";
      
      if (attachment) {
      
          xml += '<Attachment name="' + attachment.name + '" contentType="' + attachment.contentType + '">';
          xml += '<Description>' + attachment.description + '</Description>';
          xml += '<Location>' + attachment.location + '</Location>'; 
          xml += '</Attachment>';
      }
      xml +="</Note>";
      
      jQuery.ajax({
        url         : _ixdirectoryPostUrl + "organizations/" + _ret.getUserLocationId() + "/notes",
        type        : "POST",
        contentType : 'application/xml',             
        data        : xml,
        beforeSend  : com.ics360.ajaxCrippledClient("POST", ['X-Authorization: Basic ' +  _authorizationHash]),
        error       : com.ics360.ajaxError('com.ics360.ixdirectory.createNote','SEVERE'),
        success     : function() 
        {
          if (callback && jQuery.isFunction(callback)) {
              callback.call(_ret);
          }
        }
      });            
    },
		
		// TODO: Document this method
		getMarketingMessageInfo: function () {
      var toRet = {lastSeen: 0, displayedDuaration: 0},
          settingsEl = _ret.getUserIdentity().find("ApplicationSettings" +
          "[applicationName=agentportal]" +
          "[organizationId=" + com.ics360.ixconfig.getConfig().application.organizationId + "]" +
          "[environmentName=" + com.ics360.ixconfig.getConfig().application.environmentName + "]");
      if(settingsEl.length) {
          toRet.lastSeen = parseInt(settingsEl.find('marketingLastSeen').text(), 10) || 0;
          toRet.displayedDuration = parseInt(settingsEl.find('marketingDisplayedDuration').text(), 10) || 0;
      }
      return toRet;

    },

		// data = {lastSeen:timestamp_in_ms, displayedDuration: x_s}
        // both optional.
		updateMarketingMessageInfo: function (marketingData, callback) {
            
			// NOTE: DANGER ZONE STARTING, THIS CODE IS CRAZY! Âº_Âº
			_ret.loadIdentity(_username, false, function (err, rawIdentity) {
            
				// this is actually just here to check that the appropriate setting exists.
            	// also, this is probably the ugliest chunk of code I've ever
            	// written in my life. I'm sorry. - Someone?
				// NOTE: Yes, yes it is - tgaw
            	var settingsTest = _ret.getUserIdentity().find("ApplicationSettings" +
            	    "[applicationName=agentportal]" +
            	    "[organizationId=" + com.ics360.ixconfig.getConfig().application.organizationId + "]" +
            	    "[environmentName=" + com.ics360.ixconfig.getConfig().application.environmentName + "]" );
            	    
				var settingsEl;
            
				if (!settingsTest.length) {
                	settingsEl = '<ApplicationSettings applicationName="agentportal" organizationId="'+
                               com.ics360.ixconfig.getConfig().application.organizationId +
                               '" environmentName="' +
                               com.ics360.ixconfig.getConfig().application.environmentName +'">' +
                             '<marketingLastSeen>'+(marketingData.lastSeen ? marketingData.lastSeen : '')+'</marketingLastSeen>' +
                             '<marketingDisplayedDuration>'+(marketingData.displayedDuration ? marketingData.displayedDuration : '') + '</marketingDisplayedDuration>' +
                             '</ApplicationSettings>';
                	
					rawIdentity = rawIdentity.replace('</Identity>',settingsEl+'</Identity>');
					
            	} else {
                	rawIdentity = rawIdentity.replace('(<ApplicationSettings[^>]+agentportal[^>]+>)(.*?)(</ApplicationSettings>)', function (noReplace, startTag, content, endTag) {
                    	//check if we have the right tag
                    	if (startTag.indexOf(com.ics360.ixconfig.getConfig().application.organizationId) >= 0 && startTag.indexOf(com.ics360.ixconfig.getConfig().application.environmentName )) {
						
							if (marketingData.lastSeen) {
								content = content.replace('<marketingLastSeen>.*</marketingLastSeen>','<marketingLastSeen>'+marketingData.lastSeen+'</marketingLastSeen>');
							}
						
                        	if (marketingData.displayedDuaration) {
								content = content.replace('<marketingDisplayedDuration>.*</marketingDisplayedDuration>','<marketingDisplayedDuration>'+marketingData.displayedDuaration+'</marketingDisplayedDuration>');
							}
						
                        	return startTag + content + endTag;
                    	} else {
                        	return noReplace;
                    	}
                	});
				}
			
            	// send request
            	jQuery.ajax({
            	    url: _ixdirectoryPostUrl + "identities/" + _username,
            	    type: "POST",
            	    dataType: "xml",
            	    contentType: "application/xml",
            	    beforeSend: com.ics360.ajaxCrippledClient("PUT", ['X-Authorization: Basic ' +  _authorizationHash]),
            	    error: com.ics360.ajaxError('com.ics360.ixdirectory.addIdentity','SEVERE'),
            	    data: rawIdentity,
            	    success: function (response) {
            	        if (callback && jQuery.isFunction(callback)) {
            	            callback.call(_ret);
            	        }
            	    }
            	});
        	}, true); // End of _ret.loadIdentity
       	}
    };

    // Return the configured object
    return _ret;

}());