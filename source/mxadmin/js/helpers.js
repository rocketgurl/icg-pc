// Helper methods used throughout the application.
(function (app) {
	"use strict";
	
	app.helpers = (function () {
		
		var ret = {};
		
		// Retrieve the value for the key in the given array of objects.
		// This is used to retrieve values from InsurancePolicy DataItems
		// @param ARRAY dataItems
		// @param STRING key
		// @return MIXED
		ret.getDataItem = function (dataItems, key) {
			// We really need the array of values or this method is worthless.
	    if (!dataItems) {
				return;
			}

			var ret      = null,
				  i        = 0,
				  j        = 0,
				  len      = dataItems.length,
				  opVal    = null,
				  cur      = null;
			
			// This is a little strange. InsurancePolicy(s) contain 
			// Non-Op and Op variables/DataItems. We always want to
			// favor the Op value, but we don't want to have the client
			// looking twice. So, here, we'll first try to retrieve a
			// value from the Op var, if it is empty we'll look for the
			// Non-Op. Ex: OpTotalPremium / TotalPremium
			
			// First time through we're just looking for the Op var
	    for (i; i < len; i += 1) {
				cur = dataItems[i];
				
				// Ignore any vars that don't start with "Op"
				if (cur.$name.substr(0, 2) === 'Op') {
					
					// If the current DataItem's name matches the key
					if (cur.$name.substr(2) === key) {
						
						// Store the value of the DataItem for later use
						opVal = cur.$value;
												
						// We can now stop this loop to save some time.
						break;
					}
				} else {
					continue;
				}
	    }
			
			// If we did not retreive an Op value we need to look for
			// a non-Op value
			if (!opVal) {
				for (j; j < len; j += 1) {
					cur = dataItems[j];

					// Check that the current item's name matches our key
					if (cur.$name === key) {
						
						// Setting the 
						ret = cur.$value;
						break;
					}
		        }
			} else {
				
				// If we did recieve an Op value, we want that! Even
				// if the value is 0
				ret = opVal;
			}
			return ret;
	    };
	
		// Retrieve an object containing key:value members of needed data items
		// and their values. The needed data items will come from the terms provided.
		// @param ARRAY dataItems - An array of policy DataItems
		// @param ARRAY terms - An array of ixvocab term objects
		// @return OBJECT
		ret.getDataItemValues = function (dataItems, terms) {
			var obj     = {},
				i       = 0,
				curTerm = '',
				len     = terms.length;
						
			for (i; i < len; i += 1) {
				curTerm = terms[i].name;
				obj[curTerm] = ret.getDataItem(dataItems, curTerm);
				
				// Null objects squash values in jQuery.extend() so
				// we need to remove from obj or we lose data in form
				if (obj[curTerm] === null) {
					delete obj[curTerm];
				}			
			}
			
			// Coverage D is a special case. It should always be 20% of Coverage A.
			// Throwing in a try just in case one of those is not present in
			// the policy at all.
			// NOTE: Tying directly to vocab terms may not be the best way
			// to handle this. I kind of think this type of checking and
			// rounding should be on the server only.
			try {
				if (obj.CoverageA && obj.CoverageD) {
					obj.CoverageD = Math.round(~~(obj.CoverageA) * .2);
				}
			} catch (e) {}
			
			// Run through the items again to set any enums
			// NOTE: This may be a bit inefficent, might need to
			// move it to getDataItem()
			obj = ret.setEnumerations(obj, terms);
			
			return obj;
		};
		
		// Dynamically create an array of objects to be used as DataItems
		// in a PCS or TR. Each object will contain a $name and $value member
		// @param OBJECT params - An object that is generated from a form submission
		// @param ARRAY terms - An array of ixVocab term objects
		// @return ARRAY - An array of objects or an empty array
		ret.getChangedDataItems = function (params, terms) {
			var changes = [],
				i       = 0,
				len     = params.$changed.length,
				curObj  = {},
				item    = null;
			
			// If nothing has changed, do nothing
			if (len > 0) {
				
				// Look through the changed params if a param 
				// matches a vocab term, create an object for it
				// in the changes array.
				for (i; i < len; i += 1) {
					item = params.$changed[i];
					
					// This makes sure the changed item is included in
					// the ixvocab terms
					if (mxAdmin.helpers.objectInArray(item, terms, 'name') > -1) {
													
						// Create the members that our JSON to XML parser
						// will look for.
						curObj['$name']  = item;
						curObj['$value'] = params[item];
						
						// Finally, had the new object to the array
						changes.push(curObj);
						
						// Reset curObj or shit will get nasty
						curObj = {};
					}
				}
			}
			
			return changes;
		};
		
		// Retreive a number of items from the policy that will be displayed
		// on each action to offer a quick way to verify that it is the 
		// correct policy.
		// @param OBJECT policy - The InsurancePolicy element of a policy
		// @return OBJECT
		ret.getPolicyOverview = function (policy) {	
			var	customers = policy.Customers.Customer,
            	dataItems = [],
				// These are the items we want to display in the overview
				// they are the names of DataItems in a policy
				terms = [
					{					
						'name': 'InsuredFirstName'
					},
					{
						'name': 'InsuredMiddleName'
					},
					{
						'name': 'InsuredLastName'
					},
					{
						'name': 'InsuredMailingAddressLine1'
					},
					{
						'name': 'InsuredMailingAddressLine2'
					},
					{
						'name': 'InsuredMailingAddressCity'
					},
					{
						'name': 'InsuredMailingAddressState'
					},
					{
						'name': 'InsuredMailingAddressZip'
					}
				],
				i;
			
			for (i in customers) {
				if (customers[i].$type && customers[i].$type === 'Insured') {
          dataItems = customers[i].DataItem;
          break;
        }
      }
						
			return ret.getDataItemValues(dataItems, terms);
		};
		
		// We need to create members for the view for any fields that have
		// enumerations. We'll look through all the terms and grab any
		// with enums and add a member for it in toRet with a key of
		// it's name prefixed with "Enums"
		// @param OBJECT viewObj - This object will be modified
		// @param ARRAY terms - The ixVocab terms
		// @return OBJECT - The modified view object
		ret.setEnumerations = function (viewObj, terms) {
			var i   = 0,
				  len = terms.length,
				  cur = null,
				  emptyOpt = {
				  	'value': '',
				  	'label': 'Select'
				  };
			
			for (i; i < len; i += 1) {
				cur = terms[i];
			
				if (cur.enumerations && cur.enumerations.length > 0) {
			
					// Create the array by combining the empty option
					// and the enumerations into a new array
					viewObj['Enums' + cur.name] = [].concat(emptyOpt, cur.enumerations);
				}
			}
			
			return viewObj;
		};
		
		// Search for a specified value within an object in an array.
		// Returns the index or -1 if not found
		// @param MIXED value
		// @param ARRAY array
		// @param member - The member of the object searching for
		// @return INT - Index of item or -1 if not found
		ret.objectInArray = function (value, array, member) {
		    var i       = 0,
		        inArray = -1,
				    len     = array.length;

		    for (i; i < len; i += 1) {
				  if (array[i][member] == value) {
					  inArray = i;
					  break;
				  }
		    }

		    return inArray;
		};
		
		// Determine if a value given is a float
		// @param INT value
		// @return BOOL
		// TODO: Should check to see if there are two digits
		// after the decimal so we can add a trailing zero
		// to a value like "200.1"
		ret.isFloat = function (value) {
			
			var ret = null;
			
			if (isNaN(value) || value.indexOf('.') < 0) {
				ret = false;
			} else {
				if (parseFloat(value)) {
					ret = true;
				} else {
					ret = false;
				}
			}
			
			return ret;
		};

		// Add a trailing ".00" to a value.
		// @param MIXED (INT or STRING) value
		// @return STRING
		// TODO: Determine if only a trailing zero
		// should be added instead of just adding the
		// decimal and two zeros
		ret.formatMoney = function (value) {
			return value + '.00';
		};
		
		// Determine if an object contains members
		// @param OBJ obj
		// @return BOOL
		ret.isEmpty = function (obj) {
			var ret = true,
				k;
			
		    for (k in obj) {
				if (obj.hasOwnProperty(k)) {
					ret = false;
				}
			}

		    return ret;
		};
		
		// Some date strings we'll be dealing with are formatted with a full
		// timestamp like: "2011-01-15T23:00:00-04:00". The time, after the "T"
		// can sometimes cause weird rounding issues with the day. To safegaurd
		// against it, we'll just remove the "T" and everything after it.
		//
		// @param STRING - A date string
		// @return STRING
		ret.stripTimeFromDate = function (dateString) {
			var ret          = dateString,
				hasTimestamp = dateString.indexOf('T');
			
			if (hasTimestamp > -1) {
				ret = ret.substring(0, hasTimestamp);
			}
			
			return ret;
		};
		
		// We have a number of areas where we need to parse and format dates.
		// I'm tired of writing the same thing over and over and mussing up
		// the code. Abstraction works friend.
		// @param STRING - The date string
		// @param STRING - A DateJS valid format string. Will default to 'MM/dd/yyyy'
		// @return STRING - A formatted date in the default 02/23/1985 or given format
		ret.cleanDate = function (dateString, dateFormat) {
			var format = dateFormat || 'MM/dd/yyyy';
						
			return Date.parse(ret.stripTimeFromDate(dateString)).toString(format);
		};

		// Display a standard message on the page.
		// @param OBJ options
		//
		// Options:
		//     type: 'info'|'error'|'warning'
		//     title: 'The title of the msg'
		//     msg: 'The message'
		//
		// Example HTML:
		//  <div class="content_msg {type}">
		//    <h3>Warning</h3>
		//    <p>This action can cause irreversible changes to the policy. Make sure you know what you're doing.</p>
		//  </div>
		ret.displayMsg = function (options) {
			
			var defaults = {
					type: '',
					title: '',
					msg: ''
				},
				settings = $.extend(defaults, options),
				con      = $('<div />', {
					'class': 'content_msg'
				});
				
			con.addClass(settings.type);
			
			if (settings.title) {
				con.append('<h3>' + settings.title + '</h3>');
			}
			
			if (settings.msg) {
				con.append('<p>' + settings.msg + '</p>');
			}
			
			// prevent duplicates
		    $('div.content_msg.' + settings.type).remove();
			
			$('div.content_body').before(con);
		};
		
		return ret;
	}());	
}(mxAdmin));
