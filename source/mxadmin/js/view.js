var view            = {},
    view_validators = {
      money: function (el) {
        return parseFloat(el.val()) > 0;
      },

      dateRange: function (el) {
        var minDate = Date.parse(el.data('minDate')),
            maxDate = Date.parse(el.data('maxDate')),
            date    = Date.parse(el.val());

        return date.between(minDate, maxDate);
      }
    },
    

    
    // Do validation checks on specific to the input type
    // NOTE: These will probably be newer HTML types, right now we're
    // trying out the number type. In the future this type of validation
    // may be handled by the browser.
    elemValidToType = function (elem) {
      var validators = {
            number: function (el) {
              var valid = true,
                  val   = parseInt(el.val(), 10),
                  min   = null,
                  max   = null;
              
              if (el.attr('min')) {
                min = parseInt(el.attr('min'), 10);

                if (val < min) {
                  valid = false;
                }
              }

              if (el.attr('max')) {
                max = parseInt(el.attr('max'), 10);
              }
              
              return valid;
            }
          },
          
          validator = validators[elem.attr('type')] || null;
      
      if (validator) {
        return validator(elem);
      } else {
        return true;
      }
    },
    
    // PC 2.0
    fieldIsValid = function (field) {
      var el         = $(field),
          address    = el.parents("form").attr('action') || $('#address_store').val() || mxAdmin.homeAddress,
          validators = view[address].validators || null,  
          label      = $("label[for='"+el.attr("id")+"']"),
          val        = el.val() || null,
          required   = (el.attr('required')) ? true : false,
          errorClass = 'validation_error';
      if (
        (required && val === null) || // Validate required fields
        !elemValidToType(el) || // Validate on the type of the input.
        (validators && val && validators[el.attr('name')] && !validators[el.attr('name')](el))// Custom element validators. Only run if the element has a value.
      ){
          label.addClass(errorClass);
            el.addClass(errorClass);
            return false;
        }
        else{
          label.removeClass(errorClass);
          el.removeClass(errorClass);
          return true;
        }
        
    }
    
    // Form validation for all forms in mxadmin
    // @return BOOL
    formIsValid = function (theForm) {
      var valid      = true,
          address    = $(theForm).attr('action') || $('#address_store').val() || mxAdmin.homeAddress,
          validators = view[address].validators || null;

      
      $(':input', theForm).each(function (i, element) {
        if (!fieldIsValid(element)){
          valid = false;
        }
      });
      return valid;  
    },
    
    // Make sure the user knows where the error is located in the form
    notifyOfError = function (theForm) {
      var invalidField   = theForm.find('.validation_error:eq(0)'),
          fieldContainer = invalidField.closest('.collapsibleFieldContainer'),
          scrollTimeOut  = 0;
            
      // If the field is in a collapsed section, it should be opened
      if (fieldContainer.length > 0) {
        if (fieldContainer.is(':hidden')) {
          scrollTimeOut = 95;
          fieldContainer.parent().find('h3:eq(0)').click();
        }
      }
      
      // Since we might need to wait on the section to slide open,
      // add a short wait before trying to scroll.
      setTimeout(function () {
        window.scrollTo(0, invalidField.offset().top);
      }, scrollTimeOut);
    };
    
    // Handler for all forms in mxadmin
    formSubmitHandler = function (e) {


      // PC 2.0 ALERT
      // We brute force our policy id from PolicyModule into
      // the form field #id_identifier so that all actions
      // will take place on that policy
      $('#id_identifier').val(mxAdmin.POLICY);

      // ICS-979 - Switch Favicon to loading state
      mxAdmin.loadFavicon(mxAdmin.FAVICON_LOADING);

      var theForm        = $(this),
          address        = theForm.attr('action') || $('#address_store').val() || mxAdmin.homeAddress,
          formValues     = null,
 
          // Convert a serialized array of form elements into an object
          // @return OBJECT
          createFormValuesObj = function (form) {
            var obj = {};
            
            $.each(form.serializeArray(), function (i, item) {
              var name = item.name,
                  val  = item.value;

              if (obj[name]) {
                if (!obj[name].push) {
                  obj[name] = [obj[name]];
                }

                obj[name].push(val);
              } else {
                obj[name] = val;
              }
            });
            
            return obj;
          },
          
          // @return ARRAY - An array of :input names that have changed values
          determineChangedValues = function (form) {
            var changed = [];
            
            $(':input', form).each(function (i, element) {
              var el      = $(element),
                  val     = el.val(),
                  name    = el.attr('name');

              // Check to see if the element is a <select> We'll need to check
              // the data-value attribute for an existing value
              if (el.is('select')) {

                if (el.data('value') != val) {
                    changed.push(name);
                }
                
              } else if (el.is('textarea')) {
                if (val.trim() !== '') {
                  changed.push(name);
                }

                // Textareas are a special case.
                // We want to be able to submit an empty value for them,
                // but only if they previously had a value. That allows
                // for them to be "cleared".
                // In the view, if they have a value, a special data
                // attribute will be set, data-hadValue
                if (val.trim() === '' && el.data('hadValue')) {
                  changed.push(name);
                }
                
              } else {
                if (val != element.getAttribute('value')) {
                  changed.push(name);
                }
              }
            });
            
           return changed;
          };
      
      e.preventDefault();
      
      if (!formIsValid(theForm)) {
        notifyOfError(theForm);
        
        try {
          view[address].error();
        } catch (e) {}

        return false;
      } else {
        
        // Display the loading indicator
        // TODO: Create and use a custom loading event for our forms
        loadingOn(theForm);
        
        // Create an object of element name: value pairs to pass along
        formValues = createFormValuesObj(theForm);
        
        // Determine which inputs have values that have changed
        formValues.$changed = determineChangedValues(theForm);
        
        // Special consideration for actions with a preview step   
        if (formValues.preview) {
          CTX.preview = formValues.preview;
        }

        if (view[address]) {
          view[address].load(formValues);
        } else {
          show(address, formValues);
        }
      }      
    };

// This will be called each time a new page has been called and finished
// rendering, template completed, etc
view.onReady = function () {

  // ICS-979 Change favicon back to default
  mxAdmin.loadFavicon(mxAdmin.FAVICON_DEFAULT);

  var coverage_calculations,
      $coverage_a = $('#id_CoverageA');

  // We need to check if CoverageA is holding any data-calculations
  // information, and if it is, add it to $coverage_calculations,
  // and eval into an object. We do this so we can modify items 
  // that don't have a corresponding select field. For instance,
  // in OFCC-HO3-VA/endorse CoverageD does not have a corresponding
  // select that modifies it, it has a custom calculation based on
  // CoverageA.
  //
  // Example data (id : multiple):
  //
  // { CoverageD : '.2' }
  //
  if ($coverage_a.length > 0) {
    var data = $coverage_a.data('calculations');
    coverage_calculations = (eval('(' + data + ')'));
  }

  // Make calculations on the val of CoverageA based
  // on the multiples stashed in $coverage_calculations
  // and apply to the id stashed in $coverage_calculations
  var coverageACalcs = function() {
    var val;
    if ($coverage_a.length > 0) {
      val = $coverage_a.val();
    }
    if (typeof val !== 'undefined' || val !== null) {
      if (coverage_calculations !== null) {
        for (i in coverage_calculations) {
          var calc_val = val * parseFloat(coverage_calculations[i]);
          $('input[name=' + i + ']').val(calc_val);
        }
      };
    };
  }

  // We have a number of select elems that, when another text input
  // is updated, need to be checked for a value. That value is then
  // used to calculate another field that each select is related.
  var coverageFieldCalcs = function () {
      $('select[data-affects]').each(function (e) {
        var el = $(this);
        if (el.val()) {
          $('input[name=' + el.data('affects') + ']').trigger('coverage.calculate', el.val());
        }
      });
    };


    $('select[data-value]').val(function (index, value) {
      return $(this).attr('data-value');
    });

    // if this is a DP3 NY form and has a Coverage L & Coverage M field we
    // need to set M to 0 when L is 0, as per Andy Levens instructions.
    var coverage_l = $('select[name=CoverageL]');
    var coverage_m = $('select[name=CoverageM]');

    if (CTX.product === "ofcc-dp3-ny" && coverage_l !== null && coverage_m !== null) {
      coverage_l.change(function(){
        if ($(this).val() === '0') {
          coverage_m.val("0");
        }

        // If L > 0 && M == 0 set M to null (select..)
        if (parseInt($(this).val(), 10) > 0 && coverage_m.val() === '0') {
            coverage_m.val("");
        }
      });

      // Ensure that M stays at 0 is L is at 0
      coverage_m.change(function(){
        if ($(this).val() !== '0' && coverage_l.val() === '0') {
          $(this).val('0');
        }
      });
    }

    // 
    // ICS-1010 : Add Policy Limits option to VA mxAdmin form for Water Backup
    //
    // In HO3 VA policies, when "Policy Limits" is selected for the
    // WaterBackupCoverage field the value of that field should reflect
    // whatever is in Coverage A. Additionally, on form load, if Coverage A
    // is the same as whatever the value of WaterBackupCoverage is, then 
    // WBC should be set to "Policy Limits" with the value of Coverage A.
    // ALSO : There is a call to these functions on Line 424 below
    // 
    var $water_backup_coverage = $('#id_WaterBackupCoverage');
    
    // Determine if we're an HO3 VA form
    var check_ho3va = function() {
      if (CTX.product === "ofcc-ho3-va" && $water_backup_coverage.length > 0) {
        return true;
      }
      return false;
    }

    // Are we HO3 VA? Then check a few items
    if (check_ho3va()) {
      // if Coverage_A value == WaterBackupCoverage value then set WBC value
      // to Coverage A and 'select' it.
      if (parseInt($water_backup_coverage.val(), 10) === parseInt($coverage_a.val(), 10)) {
        $water_backup_coverage.find('option[value="33"]').attr('value', $coverage_a.val());
        $water_backup_coverage.val($coverage_a.val());
      }
    }

    // If WaterBackupCoverage is set to Policy Limits then it's val must
    // always be that of Coverage A. So when Coverage A changes, change the
    // val of WaterBackupCoverage.
    var waterBackupCoverage = function() {
      if ($water_backup_coverage.find('option:selected').text() === "Policy Limits") {
        $water_backup_coverage.find('option:selected').attr('value', $coverage_a.val());
      };
    }

    // Anytime WaterBackupCoverage changes check it against Coverage A
    $water_backup_coverage.change(function(){
      waterBackupCoverage();
    })

    // 
    // ICS-964 : mxAdmin should only allow the user to select cancellation date for certain reason codes.
    // (If certain reason codes are selected then hide the effective date form)
    //
    var $form_action_cancel_pending = $('form[action=cancel_pending]');

    // Are we on the right view?
    if ($form_action_cancel_pending.length > 0) {

      // Grab the reason code select and the parent div of effectiveDate
      var $reason_code = $('#id_reasonCode');
      var $effective_date = $('#id_effectiveDate').parent();

      // Loop through the codes that turn off the date field. If the
      // currently selected value matches then switch off date. Before
      // the loop we switch the date back on as a default
      $reason_code.change(function(){
        var code_switches = [2, 7, 8, 9, 10, 11];
        var code = parseInt($(this).val(), 10); // we need an Int to compare
        $effective_date.show();
        for (var i = 0; i < code_switches.length; i++) {
          if (code === code_switches[i]) {
            $effective_date.hide();
            $effective_date.find('input[type=text]').val('') // clear value
          } 
        };
      })
    }
    

  // We're using some HTML5 input types and the form validation is
  // pretty wonky still, so we'll just turn off the html validation for now.
  // Bind all forms' submit event to our handler.
  $('form').attr('novalidate', 'novalidate')
    .bind('submit', formSubmitHandler)
    .each(function(i, form){
      formIsValid(form);
    });
  


  $('#content .datepicker:not(.custom)').each(function () {
    var minDate   = $(this).data('minDate') || null,
        maxDate   = $(this).data('maxDate') || null,
        yearRange = $(this).data('yearRange') || '-30:+10';

    // On some datepickers we will have data attributes to allow for only
    // a certain date range.
    if (minDate !== null) {
      minDate = mxAdmin.helpers.cleanDate(minDate);
    }

    if (maxDate !== null) {
      maxDate = mxAdmin.helpers.cleanDate(maxDate);
    }

    $(this).datepicker({
      yearRange: yearRange,
      minDate: minDate,
      maxDate: maxDate,
      changeMonth: true,
      changeYear: true
    });
  });

  // Any changes to Coverage A affect change on Covs B, C, D
  $('input[name=CoverageA]').bind('input', function(){
    coverageFieldCalcs();
    coverageACalcs();
    // ICS-1010 If we're a VA policy we need to do some extra work
    if (check_ho3va()) {
      waterBackupCoverage();
    }
  });

  // A number of select elements should trigger a change in certain
  // read-only text inputs.
  $('select[data-affects]').change(function (e) {
    var affected = $(this).data('affects');

    // NOTE: The value is not a percentage in the label. It is the
    // enumeration value which is the percentage * 100
    $('input[name=' + affected + ']').trigger('coverage.calculate', $(this).val());
  });

  // This will be called each time a select[data-affects]'s change event
  // is trigger AND any time Coverage A is updated
  $('input').bind('coverage.calculate', function (e, val) {
      var covA   = parseInt($('input[name=CoverageA]').val(), 10),
          newVal = Math.round((covA * val) / 10000);

    $(this).val(newVal);
  });

  // Bind appropriate links to trigger jquery.address
  $('a').live('click', function (e) {
    var href = $(this).attr('href');

    e.preventDefault();

    if (href && href !== '#') {
      $address.trigger('nav', [href]);
    }
  });

  // Calling this once when the view first loads will make sure
  // we update any fields that need calculating if their related
  // field has a value.
  coverageFieldCalcs();

  // Prepare open/close-able sections.
  view.editableFormSections.init();
  $(":input").on("change", function(event) {
    fieldIsValid(event.target);
  });
};

// Display a message at the top of the page. Used for success and error
// messages.
view.message = function (e, title, desc, details) {

  // ICS-979
  // If we're throwing a message it usually means that something
  // has stopped, so we need to switc the favicon back to normal
  mxAdmin.loadFavicon(mxAdmin.FAVICON_DEFAULT);

  var msgHtml = $('<div />', {
    'class': 'content_msg'
    }),
    msgType = e.type,
    message  = desc || null;

  // This will add a class that is the name of the event type,
  // 'error' or 'success'
  msgHtml.addClass(msgType);

  // Create the error title
  msgHtml.append($('<h3 />', {
    text: title
  }));

  // Create the message
  if (message !== null) {
    msgHtml.append($('<p />', {
      html: message
    }));
  }

  // Check for error details. Details should be an html <ol> or <ul>
  if (details) {
    (function () {
      var showText    = 'Show error details +',
        hideText    = 'Hide error details -',
        detailsLink = $('<a />', {
          'text': showText,
          'href': '#',
          click: function (e) {
            e.preventDefault();

            $(this).next().toggle();
          }
        }),
        detailsCon  = $('<div />', {'class': 'error_details'});

      detailsCon.append(detailsLink).append(details);
      msgHtml.append(detailsCon);

      detailsLink.toggle(
        function () {
          $(this).text(hideText);
        },
        function () {
          $(this).text(showText);
        }
      );
    }());
  }

  // Remove any loading indicators
  $('.loading').remove();

  // Enable any temp disabled inputs
  $('#home li input.tempDisabled').removeClass('tempDisabled').removeAttr('disabled');

    // prevent duplicates
  // TODO: This in a better way, the substr is too brittle.
    $('div.content_msg').remove();

  // template message
    $("#content_header, #policy_num_input").after(msgHtml);

  // We want success messages to fade away after a short amount of time
  if (msgType === 'success') {

    setTimeout(function () {
      $('div.content_msg.' + msgType).animate({'opacity': 0}, 200)
        .delay(150).animate({'height': 0}, 150, function () {
          $(this).remove();
        });
    }, 8000);
  }
};

// A default success handler for all ajax requests
// @param OBJECT options
// @return FUNCTION
view.request_success = function (options) {
  var defaults = {
      title: 'Action completed successfully',
      desc: null
    },
    settings = $.extend(true, defaults, options);

  return function () {
    $address.trigger('nav', [HOME]);
    $('body').trigger('success', [settings.title, settings.desc]);
  };
};

// ICS-1042 & ICS-429
// 
// The new Rate Validation system requires an override switch
// to be thrown if necessary.
// 
view.checkRateValidationError = function () {
  var body_data = $('body').data();
  if (body_data['error-message'] === 'Rate Validation Failed') {
    $('#rate_validation_override').fadeIn('fast');
  }
}; 

// ICS-1042 & ICS-429
// 
// We need to intercept errors and check for JSON payloads coming from mxServer.
// Rate validation will throw a specific error, and can be overidden only after
// that error is thrown, so we need to do a couple of things:
// 
// 1. Check for JSON payloads and parse
// 2. Let our view know what happened by setting a data attr on body
// 
// A default error handler for all ajax requests
// 
view.request_error = function (response, status, errorThrown) {

  var errorTitle, errorDesc, errorDetails, re, json, resp;

  // Erroracolypse handling
  if (!response) {
      $('body').trigger('error', [status || 'Unknown HTTP error', "Some sort of major problem occurred with the request. It's bad enough that mxAdmin didn't even get an error message."]);
  }

  if (response.responseText) {
    re   = /\[(.*?)\]/g;
    json = re.exec(response.responseText);
  }

  // Slap an error flag into a data element on BODY. We will use this in view.js
  if (json && document.body.id === 'endorse') {

    resp = (json && json[0]) ? JSON.parse(json[0]) : null;

    // Assemble a message and drop into data element on BODY
    if (resp[0] && resp[0].message) {
      errorTitle   = resp[0].message || null;
      errorDesc    = resp[0].detail || null;
      errorDetails = null;

      $('body').data({
        'error-view'    : 'endorse',
        'error-message' : errorTitle,
        'error-detail'  : errorDesc
      });

      // Tell Endorse to check errors
      view.checkRateValidationError();
    }
  } else {

    // Build the usual HTML response
    var statusCode = response.status,
    trueStatusCode = response.getResponseHeader('X-True-Statuscode') || null,

    // We need to pull some info from the responseText so we'll create and
    // append an element to the DOM containing the html, pull the text we need
    // from it, then remove the temp element.
    tmpElem        = $('<div />', {
      'css': {
        'display': 'none'
      },
      html: response.responseText
    }),
    errorTitle   = null,
    errorDesc    = null,
    errorDetails = null;

    // Retrieve the error title and desc from the tmp response text element
    $('body').append(tmpElem);
    errorTitle   = tmpElem.find('h1:first').text();
    errorDesc    = tmpElem.find('p:first').text();
    errorDetails = tmpElem.find('ol:first');

    // Since checking for the <ol> will return an empty array, we want to make
    // sure there is actually something there before we send it to be poplulated
    // in the error message.
    // We'll check first for the <ol> because that is what we're supposed to get,
    // then a second time for the <ul>. Some of the services incorrectly give that
    // instead of the <ol>
    if (errorDetails.length <= 0) {
      errorDetails = tmpElem.find('ul:first');

      if (errorDetails.length <= 0) {
        errorDetails = null;
      }
    }

    // Be sure to remove the temp elem. Bad things will happen if you don't
    tmpElem.remove();

    // In case we don't recieve a trueStatusCode from the server, we need to
    // display the status that was returned with the request.
    if (trueStatusCode === null) {
      errorTitle = statusCode + ' ' + errorTitle;
    }
  }

  $('body').trigger('error', [errorTitle, errorDesc, errorDetails]);
};

// Some forms will have numerous sections that we'll initally hide and
// provide an open/close button.
view.editableFormSections = {
  init: function () {
    $('form.collapsedSections fieldset h3').click(function (e) {
      try {
        var indicator = $(this).find('a'),
            newText   = indicator.data('altText'),
            altText   = indicator.text();

        // Set the text of the indicator link
        indicator.text(newText).data('altText', altText);
      } catch (e) {}

      // Open or Close the container
      $(this).parent().find('div.collapsibleFieldContainer').slideToggle(75);
    });

    // Auto open any sections with a class of defaultOpen
    $('form.collapsedSections fieldset.defaultOpen h3').click();
  }
}

// This view is a different from the others. It isn't a full 'page', it is only
// a partial section.
view.banner = {
  update: function () {
    var logout = $('#user_info a:last').detach();
    $('#user_info').text(CTX.user + ' | ').append(logout);
  }
}

// We have a couple of preview screens that have inputs that can be
// changed to adjust values. They have similar enough characteristics
// that we can abstract the functionality here.
// @param STRING bodyId - The id of the body element. Will be used to
//                        store data about the initialization of the inputs
view.initPreview = function (bodyId) {

  $('#updatePreview').attr('disabled', true);

  // The following may prove to be a bit brittle. Tread carefully.
  //
  // If the Adjustment value is changed for either of the categories,
  // we'll need to re-calculate that category's Adjusted value.
  $('tr.calc_row input').each(function (i, val) {
    var parentRow     = $(this).closest('tr.calc_row'),
      unadjustedVal = parseInt($(this).parent().prev().text(), 10) || 0,
      adjustedElem  = $(this).parent().next(),
      subTotalElem  = parentRow.find('td.subtotal');

    // As we type into the input, update the following:
    // - This category's Adjusted value
    $(this).bind('keyup', function (e) {
      // For an explaination of the "~~" see:
      // http://petemilkman.com/?p=48
      var adjustmentVal  = ~~(this.value),
        subTotalVal    = ~~(subTotalElem.text());

      // Update this adjusted value
      adjustedElem.text((unadjustedVal + adjustmentVal));

      // Recalculate the subtotal
      subTotalElem.trigger('adjust');

      // Enabled preview update
      // TODO: This should be disabled if adjustments are
      // changed back to their original value.
      $('#updatePreview').attr('disabled', false);
    });
  });

  // Also, each time either of the categorys' adjustment values are changed
  // we'll need to update the Premium Before Fees (grandSubtotal).
  $('tr.calc_row').each(function (i, val) {
    var calculatedVals = $(this).find('td.calculated_value'),
      subtotalElem   = $(this).find('td.subtotal'),
      feesElem       = $(this).find('td.fees'),
      totalElem      = $(this).find('td.total'),
      originSubtotal = parseInt(subtotalElem.text(), 10) || 0,
      fees           = parseInt(feesElem.text(), 10) || 0,
      originTotal    = parseInt(totalElem.text(), 10) || 0;

    subtotalElem.bind('adjust', function () {
      var newSubtotal = 0,
        newTotal    = 0;

      // Set the subtotal to the sum of the calculated values.
      calculatedVals.each(function (i, val) {
        var amt = parseInt($(this).text(), 10) || 0;
        newSubtotal = newSubtotal + amt;
      });

      // Subtotal is Cat plus NonCat Adjusted values. 1000 format
      subtotalElem.text(newSubtotal);

      // Total is Subtotal plus fees. 1000 format
      totalElem.text((newSubtotal + fees));
    });
  });

  // Checking for initialized data here so that we only execute these
  // items the first time we land on preview?
    if (!$(bodyId).data('initialized')) {
        $(bodyId).data('initialized', true);

        $('#updatePreview').live('click', function () {
      $(this.form).append('<input type="hidden" id="id_preview" name="preview" value="re-preview">').submit();
    });
    }
};

view.login = {
  load: function (params) {
    if (params.username && params.password) {
        model.login(params.username, params.password, function (userEmail) {
        CTX.user = userEmail;
        view.banner.update();
        show($.address.path());
      });
    }
  },

  error: function () {
    mxAdmin.helpers.displayMsg({
      type: 'error',
      title: 'Invalid username or password'
    });
  }
}

view.home = {
    load: function (params) {
        $('#id_identifier').focus();

    // If the Enter key is pressed, we do not want to submit the form
    if ($('#id_identifier').is(':focus')) {
      $('#id_identifier').keydown(function (e) {
        if (e.which === 13) {
          e.preventDefault();
        }
      });
    }

    // When submitting the form, set the value of the page action to the
    // one clicked.
        $('input[type=submit]').live('click', function (e) {
            $('#page_action').val($(this).attr('name'));
        });

        // clear out preview functionality that might be sticking around
        delete CTX.params;
        delete CTX.preview;

        if (params.identifier) {

      // Disable all actions to prevent multiple requests
      $('#home li input').addClass('tempDisabled').attr('disabled', 'disabled');

      // this may not be the best place for this.
      // We need to display a loading indicator has it might take a bit
      // for the policy to load.
      $('#id_identifier').parent().append($('<span />', {'class': 'loading'}));

      model.pxcentral.policy.get(params.identifier, function (res) {

        if (!res.InsurancePolicy) {
          $('body').trigger('error', ['Could not find Policy ' + params.identifier]);
          return false;
        }

        var policy     = model.policy(res.InsurancePolicy),
            action     = params.page_action,
            errorTitle = null,
            errorDesc  = null;

        // Prevent any action and display an error message if the policy is
        // actually a quote.
        if (policy.quote) {
          $('body').trigger('error', [params.identifier + ' is a quote and cannot be managed with mxAdmin']);

          return false;
        }

        // Now that we have a policy, we need to do a few
        // checks to make sure the action we are trying to
        // take can be made, based on different things in
        // the policy
        // TODO: Move away from switch, use a map instead
        switch (action) {

        // NOTE: This is a legacy check, I'm not 100% sure what it's for
        case 'issue':
          if (policy.issued) {
            $('body').trigger('error', ['Policy ' + params.identifier + ' already issued']);
            return false;
          }

          break;

        // A policy can only be renewed if it is active and not
        // pending cancellation
        case 'renew':
          if (policy.cancelled || policy.pendingCancel) {
            // Load the 'Cancellation' model to get the list of reason codes.
            mxAdmin.dataModel({
              productName: policy.productName,
              viewName: 'cancellation',
              success: function (dataModel) {
                errorTitle = 'Policy ' + params.identifier + ' is not eligible for renewal';
                errorDesc  = (function () {
            
                  // Wrapping in a try/catch just in case the policy does not contain
                  // the necessary attributes on the PolicyState Elem. The try/catch
                  // prevents an error from being thrown when trying to convert
                  // the date to a string.
                  try {
                    var desc        = '',
                        shortDesc   = false,
                        date        = mxAdmin.helpers.cleanDate(policy.cancellationEffectiveDate),
                        code        = policy.cancellationReasonCode,
                        codeLabel   = code,
                        enumeration = {};
                        
                    // Loop through and find the reason code label.
                    for (var i = 0, length = dataModel[0].enumerations.length; i < length; i++) {
                      enumeration = dataModel[0].enumerations[i];
                      
                      if (enumeration.value === code) {
                        codeLabel = enumeration.label;
                        
                        break;
                      }
                    }
                  } catch (e) {
                    console.log('The PolicyState element of this policy does not contain the needed cancellationEffectiveDate or cancellationReasonCode attributes', e);
            
                    date      = null;
                    code      = null;
                    codeLabel = null;
                    shortDesc = true;
                  }
            
                  if (policy.cancelled) {
                    desc = 'This policy was cancelled'
                              
                    if (!shortDesc) {
                      desc += ' on <strong>' + date + '</strong>';
                      desc += ' due to <strong>' + codeLabel + '</strong>';
                    }
                  } else if (policy.pendingCancel) {
                    desc = 'This policy is pending cancellation';
            
                    if (!shortDesc) {
                      desc += ' effective <strong>' + date + '</strong>';
                      desc += ' due to <strong>' + codeLabel + '</strong>';
                    }
                  }
            
                  return desc;
                }());
            
                $('body').trigger('error', [errorTitle, errorDesc]);
              }
            });
            
            return false;
          }
        }

        CTX.policy = res;
        CTX.policyId = params.identifier;
        CTX.product = policy.productName;
        // $.address.value(params.page_action);
        $address.trigger('nav', [params.page_action]);

      }, view.request_error);
    }
  },

  validators: {
    page_action: function (el) {
      return el.val() !== 'none'
    }
  }
}

view.issue = {
  view: function (CTX) {
    if (!CTX.policy) {
      return CTX;
    }

    var toRet = {};

    toRet.msg        = true;
    toRet.msgType    = 'info';
    toRet.msgText    = 'Company accepts binder and agrees to issue policy package.';

    return $.extend(true, {}, CTX, toRet);
  },

  load: function (params) {
    if (!CTX.policy) {
      // return $address.trigger('nav', [mxAdmin.homeAddress]);
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }

    var policy = model.policy(CTX.policy.InsurancePolicy),
      toSend = null;

    if (params && !mxAdmin.helpers.isEmpty(params)) {
      params.transactionType = 'Issuance';
      params.effectiveDate = policy.lastTerm.EffectiveDate;

      toSend = model.transactionRequest(CTX.policy).issue(params);

      model.pxcentral.policy.set(policy.id, toSend);
    }
  }
}

view.issue_manual = {
  load: function (params) {
    if (!CTX.policy) {
      // return $address.trigger('nav', [mxAdmin.homeAddress]);
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }

        var id          = model.pxcentral.policy.id(CTX.policy),
            idtimestamp = (new Date()).toISOString().replace(/:|\.\d{3}/g,''),
            url         = model.ixlibrary.policy.url(id),
            issueobjkey = model.ixlibrary.slugs.issue.objKey + '-' + idtimestamp,
            decobjkey   = model.ixlibrary.slugs.issue.decKey + '-' + idtimestamp,
            toSend      = null;

        if (params && !mxAdmin.helpers.isEmpty(params)) {
            params.changeType   = 'ISSUE';
            params.formattedMDY = (new Date()).toString('M/d/yy');
            toSend              = model.policyChangeSet(CTX.policy).issue_manual(params);

            model.pxcentral.policy.set(id, toSend);

        } else {

            model.ixlibrary.policy.bindField('id_package', url, issueobjkey, function (resp) {
                $('#id_package')
                    .after('<input type="hidden" name="packageDoc" value="' + issueobjkey + '">')
                    .after('<input type="hidden" name="idtimestamp" value="' + idtimestamp + '">');
            });

            model.ixlibrary.policy.bindField('id_declaration', url, decobjkey, function (resp) {
                $('#id_declaration')
                    .after('<input type="hidden" name="declarationDoc" value="' + decobjkey + '">');
            });
        }
    }
}

view.invoice = {

    load: function (params) {
        if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }

        var id     = model.pxcentral.policy.id(CTX.policy),
      toSend = null,

      timestamp = new Date(),

      // This will be appended to a few document labels
      labelStamp = timestamp.toString('M/d/yy'),

      // This will be appended to the document type to create
      // the id attribute for the PCS
      idStamp = timestamp.toISOString().replace(/:|\.\d{3}/g, '');

        if (params && !mxAdmin.helpers.isEmpty(params)) {
      params.InvoiceDateCurrent = timestamp.toString('M/d/yyyy');
      params.changeType = 'INVOICE';
            params.reasonCode = 'INVOICE';

      // An invoice document needs to be generated, create the params needed
      // NOTE: This isn't the best way to do this.
      params.documentType  = 'Invoice';
      params.documentLabel = 'Invoice ' + labelStamp;
      params.documentHref  = '';
      params.documentId    = params.documentType + '-' + idStamp;

      if (!mxAdmin.helpers.isFloat(params.InvoiceAmountCurrent)) {
        params.InvoiceAmountCurrent = mxAdmin.helpers.formatMoney(params.InvoiceAmountCurrent);
      }

      if (params.installmentCharge && !mxAdmin.helpers.isFloat(params.installmentCharge)) {
        params.installmentCharge = mxAdmin.helpers.formatMoney(params.installmentCharge);
      }

      // Build and retrieve the PCS
      toSend = model.policyChangeSet(CTX.policy).invoice(params);

      model.pxcentral.policy.set(id, toSend);
        }
    },

    validators: {
        'InvoiceAmountCurrent': view_validators.money,
        'installmentCharge': view_validators.money
    }
}

view.make_payment = {

  // ARRAY
  vocabTerms: null,

  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var // OBJECT
      latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

      // ARRAY - Store the data items from the latest policy term
      termDataItems = latestTerm.DataItem,

      // OBJECT - The object we will provide to the template will contain all the
      // needed fields as defined in the vocabTerms. The values will be
      // retrieved from the policy DataItems
        toRet = mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms);

    return $.extend(true, {}, CTX, params, toRet);
  },

    load: function (params) {
        if (!CTX.policy) {
      // return $address.trigger('nav', [mxAdmin.homeAddress]);
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }

        var id     = model.pxcentral.policy.id(CTX.policy),
            url    = model.ixlibrary.policy.url(id),
      toSend = null;

        if (params && !mxAdmin.helpers.isEmpty(params)) {
            params.paymentAmount         = -1 * Math.abs(params.paymentAmount || 0);
            params.positivePaymentAmount = Math.abs(params.paymentAmount || 0);

            toSend = model.policyChangeSet(CTX.policy).make_payment(params);
            model.pxcentral.policy.set(id, toSend);
        }
    }
}

view.reverse_payment = {

  // ARRAY
  vocabTerms: null,

  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var // OBJECT
      latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

      // ARRAY - Store the data items from the latest policy term
      termDataItems = latestTerm.DataItem,

      // OBJECT - The object we will provide to the template will contain all the
      // needed fields as defined in the vocabTerms. The values will be
      // retrieved from the policy DataItems
        toRet = mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms);

    return $.extend(true, {}, CTX, params, toRet);
  },

  load: function (params) {
        if (!CTX.policy) return $address.trigger('nav', [HOME]);

        var id     = model.pxcentral.policy.id(CTX.policy),
            url    = model.ixlibrary.policy.url(id),
      toSend = null;

        if(params && !mxAdmin.helpers.isEmpty(params)) {
            params.paymentAmount = Math.abs(params.paymentAmount || 0);

            toSend = model.policyChangeSet(CTX.policy).reverse_payment(params);
            model.pxcentral.policy.set(id, toSend);
        }
    }
}

// Landing page for all cancellation actions. Upon navigating to this view, a
// policy will be requested and inspected. Based on data in the policy
// certain cancellation actions will be made available or unavailable.
view.cancellation = {

  vocabTerms: null,
  
  // TODO: We've abstracted a lot of the logic below to the policy model
  // Start using it instead of this.
  // NOTE: This shit is a hot mess.
  view: function (CTX) {
    if (!CTX.policy) {
      return CTX;
    }

    var policy               = CTX.policy.InsurancePolicy,
        management           = policy.Management,
        policyState          = management.PolicyState,
        policyStateVal       = null,
        pendingCancel        = management.PendingCancellation || null,
        toRet                = {},
        
        // We need to do some crud to get some crap from some other crud
        reasonCodesAndLabels = mxAdmin.helpers.setEnumerations({}, this.vocabTerms).EnumsReasonCodesAndLabels,
        reasonIndex          = null,
        reasonLabel          = null;
    
    toRet.policyEffectiveDate  = model.pxcentral.policy.getEffectiveDate(policy);
    toRet.policyExpirationDate = model.pxcentral.policy.getExpirationDate(policy);

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

    // If this policy is pending cancellation...
    if (pendingCancel !== null) {
      
      reasonIndex = mxAdmin.helpers.objectInArray(pendingCancel.$reasonCode, reasonCodesAndLabels, 'value'),
      reasonLabel = reasonCodesAndLabels[reasonIndex].label;
      
      toRet.pendingCancel                = true;
      toRet.pendingCancelReasonCode      = pendingCancel.$reasonCode;
      toRet.pendingCancelReasonCodeLabel = reasonLabel;
      toRet.cancellationEffectiveDate    = mxAdmin.helpers.cleanDate(pendingCancel.$cancellationEffectiveDate);
    } else {

      // We need to explicity set any values to false or null each time
      // because of the CTX object. Right now, if a member is added to
      // CTX, it is not cleared each time the view is redrawn.
      // TODO: Start clearning CTX each time a new view is drawn.
      toRet.pendingCancel                = false;
      toRet.pendingCancelReasonCode      = null;
      toRet.pendingCancelReasonCodeLabel = null;
      toRet.cancellationEffectiveDate    = null;
    }

    switch (policyStateVal) {
    case 'ACTIVEPOLICY':

      if (pendingCancel === null) {

        // Active actions: Cancel, Set pending
        toRet.cancelDisabled    = '';
        toRet.pendingDisabled   = '';
        toRet.reinstateDisabled = 'disabled';
        toRet.rescindDisabled   = 'disabled';

        // Explicity setting this due to the CTX issue mentioned above
        toRet.pendingCancelReasonCode   = null;
        toRet.cancellationEffectiveDate = null;
        toRet.msg                       = false;
        toRet.msgType                   = null;
        toRet.msgHeading                = null;
        toRet.msgText                   = null;

      } else {
        // Active actions: Cancel, Rescind pending
        toRet.cancelDisabled    = '';
        toRet.reinstateDisabled = 'disabled';
        toRet.pendingDisabled   = 'disabled';
        toRet.rescindDisabled   = '';

        toRet.msg        = true;
        toRet.msgType    = 'info';
        toRet.msgHeading = 'This is an active policy that is pending cancellation.';

        // TODO: Use some flavor of JS sprintf to avoid the crazy string concatenation
        toRet.msgText    = 'Cancellation is effective <b>' + toRet.cancellationEffectiveDate + '</b> due to <b>' + reasonLabel + '</b>';
      }
      break;

    case 'CANCELLEDPOLICY':
      reasonIndex = mxAdmin.helpers.objectInArray(policyState.$reasonCode, reasonCodesAndLabels, 'value'),
      reasonLabel = reasonCodesAndLabels[reasonIndex].label;
      
      // Active actions: Reinstate
      toRet.cancelDisabled    = 'disabled';
      toRet.pendingDisabled   = 'disabled';
      toRet.rescindDisabled   = 'disabled';
      toRet.reinstateDisabled = '';

      toRet.msg        = true;
      toRet.msgType    = 'info';
      toRet.msgHeading = 'This is a cancelled policy.';

      try {
        toRet.msgText = 'Cancellation took effect <b>' + 
          mxAdmin.helpers.cleanDate(policyState.$effectiveDate) + 
          '</b> due to <b>' + reasonLabel + '</b>';
      } catch (e) {}
    }

    CTX = $.extend(true, CTX, toRet);
    return CTX;
  },

  load: function (params) {
    var
    viewName = params['_confirm_cancellation_view_name'];

    if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }

    CTX.latestTerm = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy);

    // Set a hidden input, page_action, to the name of the action selected
    $('input[type=submit]').live('mouseup', function (e) {
            $('#page_action').val($(this).attr('name'));
        });

    // $.address.value(params.page_action);
    $address.trigger('nav', [params.page_action]);
  },

  // This is a common view method for all cancellation actions.
  actionView: function (options) {
    return function (CTX, params) {
      if (!CTX.policy) {
        return CTX;
      }

      var // OBJECT
        latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

        // ARRAY - Store the data items from the latest policy term
        termDataItems = latestTerm.DataItem,

        // OBJECT - The object we will provide to the template will contain all the
        // needed fields as defined in the vocabTerms. The values will be
        // retrieved from the policy DataItems
          toRet = mxAdmin.helpers.getDataItemValues(termDataItems, options.context[options.viewName].vocabTerms);

      return $.extend(true, {}, CTX, params, toRet);
    }
  },

  // This is a base method for all cancellation actions. Each cancellation
  // action's view.load method will inherit from this.
  // @return Function
  actionLoad: function (options) {
    var
    defaults = {
      pcsType: null,
      title: null,
      desc: null
    },
    settings = $.extend(true, defaults, options);

    return function (params) {
      if (!CTX.policy) return $address.trigger('nav', [HOME]);

      var
      that      = this,
      toSend    = null,
      rawParams = params,
      id        = null,
      // Our function that will execute if the user confirms the preview
      cancel    = $.noop;

      CTX.current_policy = view.endorse.parseIntervals(CTX);
      
      if (params && !mxAdmin.helpers.isEmpty(params)) {
        // Each action has a different type attr for the PCS
        params.pcsType = settings.pcsType;

        // Special condsideration for the optional comment field
        if (params.comment === '') {
          params.comment = '__deleteEmptyProperty';
        }

        if (!params.effectiveDate) {
          params.effectiveDate = '__deleteEmptyProperty';
        }

        toSend = model.transactionRequest(CTX.policy).cancellation(params);
        id     = model.pxcentral.policy.id(CTX.policy);

        if (params.preview) {
          // Finally make the request to send the payload to the server
          model.pxcentral.policy.set(id, toSend, {
            headers: {'X-Commit': false},
            callback: function (data) {
              var previewCTX = $.extend({}, CTX);

              previewCTX.policy = data;

              delete params.preview;
              delete CTX.preview;

              CTX.params = params;
              previewCTX.params = rawParams;

              that.preview(previewCTX, {
                cancel: function() {
                  // $.address.value(HOME);
                  $address.trigger('nav', [HOME]);
                },
                confirm: function() {
                  model.pxcentral.policy.set(id, toSend, {
                    callback: view.request_success(settings)
                  });
                }
              });
            }
          });
        }
      }
    };
  },

  preview: function(config) {
    return function(previewCTX, options) {
      var
      that         = this,
      policy       = model.policy(previewCTX.policy.InsurancePolicy),
      templateName = 'cancellation-' + CTX.product,
      defaults = {
        cancel: $.noop,
        confirm: $.noop
      },
      options = $.extend(true, defaults, options);
    
      //TODO: Handle this elsewhere
      formatMoney = function(value){
      formatted = "$" + parseFloat(value).formatMoney(2, ".", ",");
      return formatted;
      }
      
      var MILLISECONDS_PER_DAY = 1000 * 60 * 60 * 24;
      
      var cancellation;
      for (var i = previewCTX.policy.InsurancePolicy.EventHistory.Event.length - 1; i >= 0; i--){
        var type = previewCTX.policy.InsurancePolicy.EventHistory.Event[i].$type;
        if (type == "Cancel" || type == "PendingCancellation"){
        previewCTX.Action = type == "Cancel" ? "Cancellation" : "Pending Cancellation";
          cancellation = previewCTX.policy.InsurancePolicy.EventHistory.Event[i];
          break;
        }
      }
      //TODO: I should be able to use some existing dataitem process logic to handle this
      for (var i = 0; i < cancellation.DataItem.length; i++){
        var parsed, formatted;
        var item = cancellation.DataItem[i];
        if (item.$name == "AppliedDate"){
          previewCTX.AppliedDate = item.$value;
        }   
        else if (item.$name == "reasonCode"){
          previewCTX.ReasonCode = item.$value;
        }
        else if (item.$name == "reasonCodeLabel"){
          previewCTX.ReasonCodeLabel = item.$value;
        }
        else if (item.$name == "EffectiveDate"){
          previewCTX.EffectiveDate = item.$value;
        }  
        else if (item.$name == "ChangeInPremium"){
          previewCTX.ChangeInPremium = formatMoney(item.$value);
        }
        else if (item.$name == "ChangeInTax"){
          previewCTX.ChangeInTax = formatMoney(item.$value);
        }
        else if (item.$name == "CancelAmount"){
          previewCTX.CancelAmount = formatMoney(item.$value);
        }
        else if (item.$name == "ChangeInFee"){
          previewCTX.ChangeInFee = formatMoney(item.$value);
        }
      }
      var preview_labels = {
        "PendingCancellationRescission": "rescission of pending cancellation",
        "Reinstatement": "reinstatement",
        "PendingCancellation": "pending cancellation",
        "Cancellation": "cancellation"
      };
      if (previewCTX.params.pcsType == "PendingCancellationRescission" || previewCTX.params.pcsType == "Reinstatement") {
        previewCTX.Undo = true;
      }
      previewCTX.PreviewLabel = preview_labels[previewCTX.params.pcsType];
      
      // Add our button label
      previewCTX.submitLabel = config.submitLabel;

      // ICS-1000 : For Pending Cancellations we want to show CancellationEffectiveDate from the preview XML doc.
      // For immediate cancellations we want to show EffectiveDate from the preview XML doc. This is partially to
      // future proof things so that if the server does calculations on the preview XML doc in the future we will
      // show them to the user here instead of their raw input.
      if (previewCTX.params.pcsType === 'PendingCancellation') {
        previewCTX.EffectiveDate = previewCTX.policy.InsurancePolicy.Management.PendingCancellation.$cancellationEffectiveDate;
      } else if (previewCTX.policy.InsurancePolicy.Management.PolicyState.$effectiveDate) {
        previewCTX.EffectiveDate = previewCTX.policy.InsurancePolicy.Management.PolicyState.$effectiveDate;
      }
 
      previewCTX.AdvanceNoticeDays = (Date.parse(previewCTX.EffectiveDate) - Date.parse(previewCTX.AppliedDate)) / MILLISECONDS_PER_DAY;
      
      // In some situations a user could enter a date in the past, which would cause a 
      // negative number to be displayed for AdvanceNoticeDays. We don't want that.
      // This is a bit of a fail safe.
      if (previewCTX.AdvanceNoticeDays < 0) {
        previewCTX.AdvanceNoticeDays = 0;
      }

      previewCTX.RateType = previewCTX.ReasonCode == "15" ? "Short-Rate" : "Pro Rata";
      
      // Finally send the vars to the view and render
      $('#contents').html(ich[templateName](previewCTX));

      // Bind to the buttons
      $('.form_actions a').click(function(el) {
        options.cancel();
      });

      $('form').bind("submit", function(el) {
      //This is a little hacky to call this directly, but the formSubmitHandler is a bit too strict in what it tries to do.
      //TODO: Use more generic form submission handling.
      loadingOn($(this));
        options.confirm();
      });

      view.onReady();
    };
  }
}

view.cancel = {

  // ARRAY
  vocabTerms: null,

  view: view.cancellation.actionView({
    context: view,
    viewName: 'cancel'
  }),

  load: view.cancellation.actionLoad({
    pcsType: 'Cancellation',
    title: 'The policy has been cancelled'
  }),

  validators: {
    'effectiveDate': view_validators.dateRange
  },

  preview: view.cancellation.preview({
    'submitLabel': 'Cancel this policy immediately'
  })
}

view.cancel_pending = {

  // ARRAY
  vocabTerms: null,

  view: view.cancellation.actionView({
    context: view,
    viewName: 'cancel_pending'
  }),

  load: view.cancellation.actionLoad({
    pcsType: 'PendingCancellation',
    title: 'The policy has been set to pending cancel'
  }),

  validators: {
    'effectiveDate': view_validators.dateRange
  },

  preview: view.cancellation.preview({
    'submitLabel': 'Set to pending cancel'
  })
}

view.reinstate = {

  // ARRAY
  vocabTerms: null,

  view: view.cancellation.actionView({
    context: view,
    viewName: 'reinstate'
  }),

  load: view.cancellation.actionLoad({
    pcsType: 'Reinstatement',
    title: 'The policy has been reinstated'
  }),
  
  preview: view.cancellation.preview({
    'submitLabel': 'Reinstate this policy'
  })
}

view.rescind = {

  // ARRAY
  vocabTerms: null,

  view: view.cancellation.actionView({
    context: view,
    viewName: 'rescind'
  }),

  load: view.cancellation.actionLoad({
    pcsType: 'PendingCancellationRescission',
    title: 'The policy pending cancellation has been rescinded'
  }),
  
  preview: view.cancellation.preview({
      'submitLabel': 'Rescind pending cancellation'
  })
}

view.renew = {

  // ARRAY
  vocabTerms: null,

  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var // OBJECT
        latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

        // ARRAY - Store the data items from the latest policy term
        termDataItems = latestTerm.DataItem,

        // OBJECT - The object we will provide to the template will contain all the
        // needed fields as defined in the vocabTerms. The values will be
        // retrieved from the policy DataItems
        toRet = mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms);

    return $.extend(true, {}, CTX, params, toRet);
  },

  load: function (params) {
    if (!CTX.policy) {
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }

    var that             = this,
      toSend           = null,
      policy           = model.policy(CTX.policy.InsurancePolicy),
      changedDataItems = null;

    // If the form has been submitted params should be populated
    if (params && !mxAdmin.helpers.isEmpty(params)) {

      // This will set the type attribute of the <TransactionRequest>
      params.transactionType = 'Renewal';

      // Renewals should not have an <EffectiveDate>
      params.effectiveDate = '__deleteEmptyProperty';

      // No comment is needed or allowed for renew
      params.comment = '__deleteEmptyProperty';

      // We want the params var to also contain any params that
      // may be in the CTX object. If CTX.params is empty, params
      // will just be what is sent to the load() method
      params = $.extend(CTX.params || {}, params);

      // @var ARRAY - We need to determine what DataItems we are going to send
      // with the request, send off the params and terms to find out
      changedDataItems = mxAdmin.helpers.getChangedDataItems(params, this.vocabTerms);

      // If we have an valid changed data items, create the containing
      // elements in the template
      if (changedDataItems.length > 0) {
        model.transactionRequest.templates.renew.RenewalChanges = {
          Set: {
            DataItem: changedDataItems
          }
        }
      }

      // @var ARRAY - We need to keep a reference to the terms of the policy
      // so that we can display them in the preview.
      CTX.currentPolicyTerms = that.getTermsForPreview(policy);

      // Create the object that will be converted into an XML
      // TransactionRequest
      toSend = model.transactionRequest(CTX.policy).renew(params);

      // The first step is to submit a preview
      if (params.preview) {

        // Send the TransactionRequest with the Commit header false
        // This prevents any changes from actually being made
        model.pxcentral.policy.set(policy.id, toSend, {
          headers: {
            'X-Commit': false
          },
          callback: function (data) {
            var previewCTX = $.extend({}, CTX);

            previewCTX.policy = data;

            // We need to delete the preview member of params
            // to make sure the next time the form is submitted
            // we actually send the TransactionRequest
            delete params.preview;
            delete CTX.preview;

            CTX.params = params;
            previewCTX.params = params;

                  that.preview(previewCTX);
              }
        });
      } else {
        model.pxcentral.policy.set(policy.id, toSend, {
          callback: function (data) {
            var newPolicy = model.policy(data.InsurancePolicy),
              opts      = {};

            // TODO: Shouldn't use CTX.policyId here...I don't think
            opts.title = 'Policy ' + CTX.policyId + ' renewed successfully';
            opts.desc = (function () {
              var desc  = 'The policy was renewed for the term starting on <strong>',
                term  = newPolicy.lastTerm,
                start = mxAdmin.helpers.cleanDate(term.EffectiveDate),
                end   = mxAdmin.helpers.cleanDate(term.ExpirationDate);

              // TODO: Blarg! Use a sprintf!!
              desc += start + '</strong> and ending on <strong>' + end + '</strong>';

              return desc;
            }());

            view.request_success(opts)();
          }
        });
      }
    }
  },

  preview: function (previewCTX) {
    var that         = this,
      policy       = model.policy(previewCTX.policy.InsurancePolicy),
      proposed     = null,
      catAdjust    = null,
      nonCatAdjust = null,
      templateName = 'renew-' + CTX.product;

    previewCTX.preview       = true;
    previewCTX.proposedTerm  = that.getTermsForPreview(policy, true);

    // An array of all previous terms. This was created in the load method.
    previewCTX.previousTerms = CTX.currentPolicyTerms;

    // Storing the proposed values for convenience
    proposed = previewCTX.proposedTerm[0];

    // Storing these so we can determine the Unadjusted GrandSubtotals below.
    // NOTE: I'm not 100% that this is necessary anymore. I'm seeing the Unadjusted
    // Subtotals for Cat and Non Cat coming back with the policy
    catAdjust    = proposed.HurricanePremiumDollarAdjustmentFRC || 0;
    nonCatAdjust = proposed.NonHurricanePremiumDollarAdjustmentFRC || 0;

    // The "~~" just makes sure the value is an int. It's a faster, fancier
    // way of running parseInt()
    proposed.GrandSubtotalNonCatUnadjusted = (~~(proposed.GrandSubtotalNonCat) - ~~(nonCatAdjust)).formatMoney(1, '.', '');
    proposed.GrandSubtotalCatUnadjusted = (~~(proposed.GrandSubtotalCat) - ~~(catAdjust)).formatMoney(1, '.', '');

    // If a premium override has been entered, we need to handle the preview
    // a bit differently.
    if (previewCTX.params.GrandSubtotalOverride) {

      // Set this bool to allow for a class name to be applied
      // to the content_body that we'll use to highlight the affected
      // table cells.
      previewCTX.premiumOverride = true;

      // Display a message reiterating that the premium has been overridden.
      previewCTX.msg        = true;
      previewCTX.msgType    = 'warning';
      previewCTX.msgHeading = 'A premium override has been applied';
      previewCTX.msgText    = 'Values affected by the override are highlighted below.';
    }
    
    // Finally send the vars to the view and render
    $('#contents').html(ich[templateName](previewCTX));
    
    view.onReady();
  },

  // We need to create an object of data related to the Proposed Term
  // and the previous Term. We'll use the Terms of the policy and abstract
  // the items we need and return an array of our custom term objects
  // @param OBJECT policy - An mxAdmin policy model
  // @param BOOL newTerm - Is this looking for a new term?
  // @return ARRAY - An Array of term objects
  getTermsForPreview: function (policy, newTerm) {
    var toRet          = [],
      msInDay        = 24 * 60 * 60 * 1000,
      curTerm        = {},
      startDate      = null,
      endDate        = null,
      terms          = null,
      len            = null,
      i              = 0;

    // During preview we'll want only the last term, which should be
    // the new or proposed term.
    if (newTerm) {
      // Adding the last term to an Array so we can use the same
      // loop that we do when we grab the previous terms.
      terms = [policy.lastTerm];
    } else {
      terms = policy.terms;
    }

    len = terms.length;

    for (i; i < len; i += 1) {

      // Parse the needed dates once for re-use
      startDate = Date.parse(mxAdmin.helpers.stripTimeFromDate(terms[i].EffectiveDate));
      endDate   = Date.parse(mxAdmin.helpers.stripTimeFromDate(terms[i].ExpirationDate));

      // Retrieve all needed data items and their values
      curTerm = mxAdmin.helpers.getDataItemValues(terms[i].DataItem, this.vocabTerms);

      // Populate the rest of the current term object
      try {
        curTerm.startDate = startDate.toString('MMM d yy');
        curTerm.endDate   = endDate.toString('MMM d yy');
      } catch (e) {
        console.log('Not able to convert the start and end dates to the proper format.', e);
      }

      curTerm.days = Math.round((endDate - startDate) / msInDay);

      // I'm seeing the FRC values not showing up. So, I'm going to manually check
      // them and if they are null, go ahead and assign 0
      // NOTE: After some testing, if we see that these values are coming back
      // with the policy, we can remove these checks.
      if (curTerm.HurricanePremiumDollarAdjustmentFRC === null) {
        curTerm.HurricanePremiumDollarAdjustmentFRC = 0;
      }

      if (curTerm.NonHurricanePremiumDollarAdjustmentFRC === null) {
        curTerm.NonHurricanePremiumDollarAdjustmentFRC = 0;
      }

      // Add the term to the return array
      toRet.push(curTerm);

      // Clean up
      curTerm = {};
    }

    return toRet;
  }
}

view.endorse = {

  // ARRAY - The terms that we'll use to populate the form
  // TODO: Stop using "vocabTerms" use something that fits
  // better like "dataModel".
  vocabTerms: null,

  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var latestTerm = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

        // Store the data items from the latest policy term
        termDataItems = latestTerm.DataItem,

        // The object we will provide to the template will contain all the
        // needed fields as defined in the vocabTerms. The values will be
        // retrieved from the policy DataItems
        toRet = mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms);

      return $.extend(true, {}, CTX, params, toRet);
  },

  load: function (params) {
    if (!CTX.policy) {
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }

    if (params && !mxAdmin.helpers.isEmpty(params)) {

        var toSend           = null,
            id               = model.pxcentral.policy.id(CTX.policy),
            self             = view.endorse,
            changedDataItems = null;

      // TODO: This will need to change
      CTX.current_policy = view.endorse.parseIntervals(CTX);

      // This will set the type attribute of the <TransactionRequest>
      params.transactionType = 'Endorsement';

      // If no comment is provided, do not create the element
      if (params.comment === '') {
        params.comment = '__deleteEmptyProperty';
      }

      // We want the params var to also contain any params that
      // may be in the CTX object. If CTX.params is empty, params
      // will just be what is sent to the load() method
      if (CTX.params) {
        params = $.extend(true, CTX.params, params);
      }

      // @var ARRAY - We need to determine what DataItems we are going to send
      // with the request, send off the params and terms to find out
      changedDataItems = mxAdmin.helpers.getChangedDataItems(params, this.vocabTerms);

      // If there have been changes made, create the DataItem(s) member and set
      // its value to the array of changed items
      if (changedDataItems.length > 0) {
        model.transactionRequest.templates.endorse.IntervalRequest.DataItem = changedDataItems;
      }

      // Create the object that will be converted into an XML TransactionRequest
      toSend = model.transactionRequest(CTX.policy).endorse(params);

      // If this is a Preview state then we need to set some extra headers
      if (params.preview) {
        var default_headers = {
          'X-Commit': false
        };
        // ICS-1042 / ICS-429
        // 
        // If the user ticks the override input then we need to add
        // ad custom header to the request. We also store a data var
        // on BODY as we need to maintain this override state over
        // multiple requests.
        // 
        if (params.id_rv_override && params.id_rv_override === '1') {
          default_headers['Override-Validation-Block'] = true;
          $('body').data('override-validation', 'yes');
        }

        model.pxcentral.policy.set(id, toSend, {
          headers  : default_headers,
          callback : function (data) {
            var previewCTX    = $.extend({}, CTX);
            previewCTX.policy = data;

            delete params.preview;
            if (params.preview !== 're-preview') {
                delete CTX.preview;
            }
            // Hold on to the params each time so we don't lose
            // anything while previewing.
            CTX.params        = params;
            previewCTX.params = params;
            self.preview(previewCTX);
          }
        });
      } else {

        var options;

        // ICS-1042 / ICS-429
        // 
        // If Override state is set we need to pass the header
        // and also clear the state so we don't override something
        // else.
        if ($('body').data('override-validation') === 'yes') {
          options = { headers : {'Override-Validation-Block' : true}};
          $('body').data('override-validation', 'no');
        }
        model.pxcentral.policy.set(id, toSend, options);
      }
    }
  },

  // I don't know what is going on here. This function accepts
  // a CTX arg, but CTX is also the name of a Global variable!? WTF!
  // TODO: Abstract and refactor this method.
  //       It's needed in multiple areas so it should be moved to a helper.
  parseIntervals: function (CTX) {
    // XXX figure out an option for objectify to turn DataItem arrays into objects and back
    //     these functions are (hopefully) just a workaround until that happens.
    var toRet = {},
        term  = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

        //yeah this looks screwy but Intervals contains a set of Interval children,
        //this set is serialized into an array containing the actual children.
        intervals = term.Intervals && term.Intervals.Interval,
        interval,
        startDate,
        endDate,
        termStart,
        termEnd,
        fees,
        grandSubtotal,
        grandSubtotalUnadjusted,
        termGrandSubtotalAdjustment,
        grandTotal,
        getDataItem = mxAdmin.helpers.getDataItem,
        msInDay     = 24 * 60 * 60 * 1000,

        // Adjustment values
        nonCatAdjustment = 0,
        catAdjustment    = 0;

    // Grab any entered adjustment values
    // Throwing this in try/catch because CTX.params won't always exist here
    try {
      nonCatAdjustment = CTX.params.NonHurricanePremiumDollarAdjustmentFRC || 0;
      catAdjustment    = CTX.params.HurricanePremiumDollarAdjustmentFRC || 0;
    } catch (e) {};

    if (!intervals.length) {
      intervals = [intervals];
    }

    toRet.intervals = [];
    termStart = Date.parse(term.EffectiveDate);
    termEnd   = Date.parse(term.ExpirationDate);

    grandSubtotalNonCatUnadjusted = getDataItem(term.DataItem, 'GrandSubtotalNonCatUnadjusted');
    grandSubtotalCatUnadjusted    = getDataItem(term.DataItem, 'GrandSubtotalCatUnadjusted');
    grandSubtotalNonCat           = getDataItem(term.DataItem, 'GrandSubtotalNonCat');
    grandSubtotalCat              = getDataItem(term.DataItem, 'GrandSubtotalCat');

    grandSubtotalUnadjusted       = getDataItem(term.DataItem, 'GrandSubtotalUnadjusted');
    grandSubtotal                 = getDataItem(term.DataItem, 'GrandSubtotal');
    termGrandSubtotalAdjustment   = getDataItem(term.DataItem, 'TermGrandSubtotalAdjustment');
    fees                          = getDataItem(term.DataItem, 'TotalFees');
    grandTotal                    = getDataItem(term.DataItem, 'TotalPremium');

    toRet.term = {
      startDate    : termStart,
      endDate      : termEnd,
      fmtStartDate : mxAdmin.helpers.cleanDate(term.EffectiveDate, 'MMM d yy'),
      fmtEndDate   : mxAdmin.helpers.cleanDate(term.ExpirationDate, 'MMM d yy'),
      days         : Math.round((termEnd - termStart) / msInDay),

      // These are new items added in 1.0
      grandSubtotalNonCatUnadjusted : Math.round(grandSubtotalNonCatUnadjusted),
      grandSubtotalCatUnadjusted    : Math.round(grandSubtotalCatUnadjusted),

      grandSubtotalNonCat : Math.round(grandSubtotalNonCat),
      grandSubtotalCat    : Math.round(grandSubtotalCat),

      // These items are pre 1.0
      grandSubtotalUnadjusted: Math.round(grandSubtotalUnadjusted),
      termGrandSubtotalAdjustment: Math.round(termGrandSubtotalAdjustment),
      grandSubtotal: Math.round(grandSubtotal),
      fees: Math.round(fees),
      grandTotal: Math.round(grandTotal)
    };

    for (var i = 0, ii = intervals.length; i < ii; i++) {
      interval                = intervals[i];
      startDate               = Date.parse(interval.StartDate);
      endDate                 = Date.parse(interval.EndDate);

      grandSubtotalNonCat     = getDataItem(interval.DataItem, 'GrandSubtotalNonCat');
      grandSubtotalCat        = getDataItem(interval.DataItem, 'GrandSubtotalCat');
      grandSubtotalUnadjusted = getDataItem(interval.DataItem, 'GrandSubtotalUnadjusted');
      grandSubtotal           = getDataItem(interval.DataItem, 'GrandSubtotal');
      fees                    = getDataItem(interval.DataItem, 'TotalFees');
      grandTotal              = getDataItem(interval.DataItem, 'TotalPremium');

      toRet.intervals.push({
        startDate    : startDate,
        endDate      : startDate,
        fmtStartDate : mxAdmin.helpers.cleanDate(interval.StartDate, 'MMM d yy'),
        fmtEndDate   : mxAdmin.helpers.cleanDate(interval.EndDate, 'MMM d yy'),
        days         : Math.round((endDate - startDate) / msInDay),

        // Because the policy does not contain an unadjusted value,
        // we need to calculate that value based on the "adjusted" value
        // which is really just the subtotal and the adjustment value
        // which will be 0 unless the user enters a value.
        // NOTE: These values are only used on the new interval
        grandSubtotalNonCatUnadjusted: Math.round((parseInt(grandSubtotalNonCat, 10) - ~~(nonCatAdjustment))),
        grandSubtotalCatUnadjusted: Math.round((parseInt(grandSubtotalCat, 10) - ~~(catAdjustment))),

        // Adjustment values
        nonCatAdjustment    : nonCatAdjustment,
        catAdjustment       : catAdjustment,        
        grandSubtotalNonCat : Math.round(grandSubtotalNonCat),
        grandSubtotalCat    : Math.round(grandSubtotalCat),

        // These items are pre 1.0
        grandSubtotalUnadjusted : Math.round(grandSubtotalUnadjusted),
        grandSubtotal           : Math.round(grandSubtotal),
        fees                    : Math.round(fees),
        grandTotal              : Math.round(grandTotal)
      });
    }

    toRet.intervals.sort(function (a, b) {
        var v1 = a.startDate,
    v2 = b.startDate;

        return (v1 == v2) ? 0 : ((v1 < v2) ? -1 : 1);
    });

    // Set the newest interval to the new one
        toRet.intervals[toRet.intervals.length - 1].isNew = true;

        if (!toRet.term.grandSubTotal) {
            interval = toRet.intervals[toRet.intervals.length - 1];

            for (i in interval) if (Object.hasOwnProperty(interval, i)) {
        if (!toRet[i]) {
            toRet[i] = interval[i];
        }
            }
        }

        return toRet;
  },

  preview: function (previewCTX) {
    var templateName = 'endorse-' + CTX.product;
    
    previewCTX.preview = view.endorse.parseIntervals(previewCTX);
    previewCTX.preview.current_policy = CTX.current_policy;
    
    $('#contents').html(ich[templateName](previewCTX));
    
    // Enable the preview adjustment inputs
    view.initPreview('#endorse');
    
    view.onReady();
  }  
}

view.change_customer = {

  // @var ARRAY - The terms that we'll use to populate the form
  vocabTerms: null,

  view: function (CTX, params) {
        if (!CTX.policy) {
      return CTX;
    }

    var policy = model.policy(CTX.policy.InsurancePolicy),

      // The object we will provide to the template will contain all the
      // needed fields as defined in the vocabTerms. The values will be
      // retrieved from the policy Customers/Customer[@type='Insured']/DataItems
      toRet = mxAdmin.helpers.getDataItemValues(policy.insuredData, this.vocabTerms);
    
    //In order to support changing the property address from the form, we need Term data
    var latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

    // Store the data items from the latest policy term
    termDataItems = latestTerm.DataItem;

    // The object we will provide to the template will contain all the
    // needed fields as defined in the vocabTerms. The values will be
    // retrieved from the policy DataItems
    
    $.extend(toRet, mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms));
    if (toRet.MailingEqualPropertyAddress == "100"){
      toRet.DisableMailingAddress = true;
    };

    // We need to create an array of objects for each Additional Insured.
    // Right now, there are only three "slots" for addtional insured(s).
    // So we'll hard code the number 3. If this number changes, or it becomes
    // something that could have N numbers, we'll have to rethink this.
    // NOTE: This is going to have to change at some point, it's kinda crappy.
    (function () {

      var additionalInsured = [],
        displayCount      = 0,
        curObj            = {},
        numOfAdditional   = 3,
        itemPrefix        = '',
        i                 = 0,
        k                 = 0,

        // These are the Suffixes of DataItems we want
        dataItems       = [
          'AddressCity', 'AddressLine1', 'AddressLine2', 'AddressState',
          'AddressZip', 'FirstName', 'LastName', 'ReferenceNumber', 'Type'
        ],

        dataItemsLen    = dataItems.length;

      for (i; i < numOfAdditional; i += 1) {
        k = 0;
        displayCount = i + 1;
        itemPrefix = 'AdditionalInsured' + displayCount;

        curObj = {
          // Nothing fancy here, just need the number
          // so we can display things like; "Additional Insured 1"
          number: displayCount,

          // Send the prefix to the view so we don't have to type it
          itemPrefix: itemPrefix
        }

        // Create a member in the cur object for each of our dataItems above
        // To reference any of these in the view: {{ key }}, i.e. {{ AddressLine1 }}
        for (k; k < dataItemsLen; k += 1) {

          curObj[dataItems[k]] = toRet[itemPrefix + dataItems[k]];

          // A little cleanup on the main view object.
          // remove any additional insured props from it
          delete toRet[itemPrefix + dataItems[k]];
        }

        additionalInsured.push(curObj);
      }

      toRet.additionalInsured = additionalInsured;
    }());

      return $.extend(true, {}, CTX, params, toRet);
    },

  load: function (params) {
        if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }
        $("#id_MailingEqualPropertyAddress").on("change", function(){
          if ($(this).val() == "100"){
            $("#id_InsuredMailingAddressLine1").parents("fieldset").first().hide();
          } else {
            $("#id_InsuredMailingAddressLine1").parents("fieldset").first().show();
          }
        });
        $("#id_MailingEqualPropertyAddress, #id_PropertyStreetNumber, #id_PropertyStreetName, #id_PropertyAddressLine2, #id_PropertyCity, #id_PropertyState, #id_PropertyZipCode").on("change", function(){
          if ($("#id_MailingEqualPropertyAddress").val() == "100"){
            $("#id_InsuredMailingAddressLine1").val(
                $("#id_PropertyStreetNumber").val() + " " 
                + $("#id_PropertyStreetName").val());
            $("#id_InsuredMailingAddressLine2").val(
                $("#id_PropertyAddressLine2").val());
            $("#id_InsuredMailingAddressCity").val(
                $("#id_PropertyCity").val());
            $("#id_InsuredMailingAddressState").val(
                $("#id_PropertyState").val());
            $("#id_InsuredMailingAddressZip").val(
                $("#id_PropertyZipCode").val());
            $("#id_InsuredMailingAddressCountry").val("");
          }
          
        });
        if (params && !mxAdmin.helpers.isEmpty(params)) {
      var toSend           = null,
        policy           = model.policy(CTX.policy.InsurancePolicy),
        changedDataItems = null;

      // This will set the type attribute of the <TransactionRequest>
      params.transactionType = 'InsuredChanges';
        
      
      // We need to be able to clear out any values and leave
      // them blank. To do so we need to set a special value so
      // the parser knows to use the empty value and not ignore it.
      // TODO: This is being used in multiple places, abstraction time soon.
      (function () {
        var i   = 0,
          k   = null,
          len = params.$changed.length;

        for (i; i < len; i += 1) {
          k = params.$changed[i];

          if (params[k] === '') {
            params[k] = '__setEmptyValue';
          }
        }
      }());

      // @var ARRAY - We need to determine what DataItems we are going to send
      // with the request, send off the params and terms to find out
      changedDataItems = mxAdmin.helpers.getChangedDataItems(params, this.vocabTerms);

      // If there have been changes made, create the DataItem(s) member and set
      // its value to the array of changed items
      if (changedDataItems.length > 0) {
        model.transactionRequest.templates.change_customer.CustomerChanges.Set.DataItem = changedDataItems;
      }

      // Create the object that will be converted into an XML TransactionRequest
      toSend = model.transactionRequest(CTX.policy).change_customer(params);

      // Send the request
      model.pxcentral.policy.set(policy.id, toSend, {
        callback: function (data) {
          var opts      = {};
          opts.title = 'Customer information changed for ' + CTX.policyId;
          view.request_success(opts)();
        }
      });
        }
    }
}

view.change_additional_interest = {
  
  // ARRAY
  vocabTerms: null,
  
  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }
    
    var policy = model.policy(CTX.policy.InsurancePolicy),
      
        // OBJECT - The object we will provide to the template will contain all the
        // needed fields as defined in the vocabTerms. The values will be
        // retrieved from the policy Customers/Customer[@type='AdditionalInterest']/DataItems
        toRet = mxAdmin.helpers.getDataItemValues(policy.additionalInterestData, this.vocabTerms);
    
    return $.extend(true, {}, CTX, params, toRet);
  },
  
  load: function (params) {
    if (!CTX.policy) {
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }
    
    if (params && !mxAdmin.helpers.isEmpty(params)) {
      var toSend           = null,
          policy           = model.policy(CTX.policy.InsurancePolicy),
          changedDataItems = null;
      
      // This will set the type attribute of the <TransactionRequest>
      params.transactionType = 'AdditionalInterestChanges';
      
      // We need to be able to clear out any values and leave
      // them blank. To do so we need to set a special value so
      // the parser knows to use the empty value and not ignore it.
      // TODO: This is being used in multiple places, abstraction time soon.
      (function () {
        var i   = 0,
            k   = null,
            len = params.$changed.length;
        
        for (i; i < len; i += 1) {
          k = params.$changed[i];
          
          if (params[k] === '') {
            params[k] = '__setEmptyValue';
          }
        }
      }());
      
      // @var ARRAY - We need to determine what DataItems we are going to send
      // with the request, send off the params and terms to find out
      changedDataItems = mxAdmin.helpers.getChangedDataItems(params, this.vocabTerms);
      
      // If there have been changes made, create the DataItem(s) member and set
      // its value to the array of changed items
      if (changedDataItems.length > 0) {    
        model.transactionRequest.templates.change_additional_interest.CustomerChanges.Set.DataItem = changedDataItems;
      }
      
      // Create the object that will be converted into an XML TransactionRequest
      toSend = model.transactionRequest(CTX.policy).change_additional_interest(params);   
      
      // Send the request
      model.pxcentral.policy.set(policy.id, toSend, {
        callback: function (data) {
          var opts = {};
          opts.title = 'Additional Interest information changed for ' + CTX.policyId;
          view.request_success(opts)();
        }
      });
    }
  }
};

view.edit_term = {
    load: function (params) {
        if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
            var toSend  = null,
                id      = model.pxcentral.policy.id(CTX.policy),
                changed = {};

            $.each(params, function (i, x) {
                if (i.substr(0, 4) === 'name' && x !== '') {
                    changed[x] = params['new_' + i.split('_')[1]];
                }
            });

            if (Object.keys(changed).length > 0) {
                toSend = model.policyChangeSet(CTX.policy).edit_term(changed);

                model.pxcentral.policy.set(id, toSend);

            } else {
                alert('no changed values found');
            }

        } else {
            // set up data
            var policy     = model.policy(CTX.policy.InsurancePolicy),
        lastTerm   = policy.lastTerm,
        intervalDI = lastTerm.DataItem,
                bag        = {};

      // TODO: Need to check on using forEach here we might need to add
      // a shim for it to support older browsers.
      try {
        intervalDI.forEach(function (x) {
          if (x.$value) {
            bag[x.$name] = x.$value;
          }
        });
      } catch (e) {
        console.log('view.js:view.edit_term.load() Having trouble iterating through intervalDI', e);
      }

            // set up row templating
            var prototype_row = $('#group_0').clone(true),
                insert_target = $('.form_actions')[0],
                tmp;

            prototype_row.attr('id', prototype_row.attr('id').slice(0,-1))
                .children('input').each(function (i) {
          var el = $(this);
          el.attr('name', el.attr('name').slice(0,-1))
            .attr('id', el.attr('id').slice(0,-1));
        });

            function create_row (n) {
                var tmp = prototype_row.clone(true);

        tmp.attr('id', prototype_row.attr('id') + n)
                  .children('input').each(function (i) {
            var el = $(this);
            el.attr('name', el.attr('name') + n)
              .attr('id', el.attr('id') + n);
            });

                return tmp;
            }

            //initialize page
            for (var i = 1; i < 5; i += 1) {
                create_row(i).insertBefore(insert_target);
            }

            // set up event handlers
      // TODO: I have no idea what's going on here -tgaw
            var autocomplete_options = {source: Object.keys(bag), minLength: 2},
                delegatefn = function (e) {
                  var $this = $(this),
                      val   = $this.val();

                  if (val in bag) {
                      $this.siblings('input[name^=current]').val(bag[val]);

            if (i === +($this.attr('id').slice(-1)) + 1) {
                          create_row(i).insertBefore(insert_target);
                          i++;

              $('input[name^=name]','.content_body').autocomplete(autocomplete_options);
                      }
                  }
              };

            $('.content_body')
                .delegate('input[name^=name]', 'keyup', delegatefn)
                .delegate('input[name^=name]', 'blur', delegatefn);
            $('input[name^=name]','.content_body').autocomplete(autocomplete_options);
        }
    }
};

view.generate_document = {

  // ARRAY
  vocabTerms: null,

  // When first opening the action, create the view object that will
  // populate the view template.
  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var
      // OBJECT - The object we will provide to the template will contain
      // all documents that can be generated based on ixVocab
        toRet = {documentGroups: this.vocabTerms};

    // The selected document's name and value will be applied to a hidden
    // input that we can then access in the load() method
    $('input[type=submit]').live('click', function (e) {
      $('input[name=documentType]').val($(this).attr('name'));
      $('input[name=documentLabel]').val($(this).val());
    });

    return $.extend(true, {}, CTX, params, toRet);
  },

    load: function (params) {

    if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }

    if (params && !mxAdmin.helpers.isEmpty(params)) {

      var timestamp   = new Date(),

        // This will be appended to the document type to create
        // the id attribute for the PCS
        idStamp     = timestamp.toISOString().replace(/:|\.\d{3}/g, ''),

        // This will be appended to a few document labels
        labelStamp  = timestamp.toString('M/d/yy'),

        // These doctypes' label attribute needs the above label stamp
        // The default is to not have it
        specialDocs = ['ReissueDeclarationPackage', 'Invoice'],

        // We'll send this to re-render the view
        viewObj     = {},

        toSend      = null,
        templateName = 'generate_document-' + CTX.product;

      // We need to create a new view object that we will send to the view
      // to re-render the template
      viewObj.generating    = true;
      viewObj.documentLabel = params.documentLabel;
      viewObj.policyId      = CTX.policyId;

      // Re-render the view with the generating message
      // NOTE: This is not very good way to do this
      $('#contents').html(ich[templateName](viewObj));

      // Manually create some parameters that will be passed to the model
      // that will prepare the PCS XML object
      params.user       = CTX.user;
      params.documentId = params.documentType + '-' + idStamp;

      // The Document label attribute is not the same for all documents
      // for a few of them we need to append a formatted date and/or
      // other special treatment
      if ($.inArray(params.documentType, specialDocs) !== -1) {
        params.documentLabel = params.documentLabel + ' ' + labelStamp;
      }

      // Create the object that will be sent with the PCS
      toSend = model.policyChangeSet(CTX.policy).generate_document(params);

      // Make the update request
          model.pxcentral.policy.set(model.pxcentral.policy.id(CTX.policy), toSend);
    }
    }
}

view.premium_disbursement = {
    load: function (params) {
    var id     = model.pxcentral.policy.id(CTX.policy),
            url    = model.ixlibrary.policy.url(id),
      toSend = null;

        if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
            params.amount = Math.abs(params.amount || 0);
            toSend        = model.policyChangeSet(CTX.policy).premium_disbursement(params);

            model.pxcentral.policy.set(id, toSend);
        }
    }
}

view.reverse_disbursement = {
    load: function (params) {
        var id     = model.pxcentral.policy.id(CTX.policy),
            url    = model.ixlibrary.policy.url(id),
      toSend = null;

    if (!CTX.policy) {
      // return $address.trigger('nav', [HOME]);
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
            params.amount = Math.abs(params.amount || 0);
            toSend        = model.policyChangeSet(CTX.policy).reverse_disbursement(params);

            model.pxcentral.policy.set(id, toSend);
        }
    }
}

view.change_payment_plan = {
    load: function (params) {
    if (!CTX.policy) {
      return $address.trigger('nav', [mxAdmin.homeAddress]);
    }

    var policy = model.policy(CTX.policy.InsurancePolicy),
      toSend = null;

        if (params && !mxAdmin.helpers.isEmpty(params)) {
      params.startDate = policy.lastInterval.StartDate;
      params.endDate   = policy.lastInterval.EndDate;


            toSend = model.policyChangeSet(CTX.policy).change_payment_plan(params);

            model.pxcentral.policy.set(policy.id, toSend);
        }
    }
}

view.update_mortgagee = {

  // @var ARRAY - The terms that we'll use to populate the form
  vocabTerms: null,

    view: function (CTX, params, address) {
        if (!CTX.policy) {
      return CTX;
    }

    var policy = model.policy(CTX.policy.InsurancePolicy),

      // The object we will provide to the template will contain all the
      // needed fields as defined in the vocabTerms. The values will be
      // retrieved from the policy Customers/Customer[@type='Mortgagee']/DataItems
      toRet = mxAdmin.helpers.getDataItemValues(policy.mortgageeData, this.vocabTerms);

    return $.extend(true, {}, CTX, params, toRet);
    },

  load: function (params) {
    if (!CTX.policy) {
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
      var toSend           = null,
        policy           = model.policy(CTX.policy.InsurancePolicy),
        changedDataItems = null;

      // This will set the type attribute of the <TransactionRequest>
      params.transactionType = 'MortgageeChanges';

      // We need to be able to clear out any values and leave
      // them blank. To do so we need to set a special value so
      // the parser knows to use the empty value and not ignore it.
      // TODO: This is being used in multiple places, abstraction time soon.
      (function () {
        var i   = 0,
          k   = null,
          len = params.$changed.length;

        for (i; i < len; i += 1) {
          k = params.$changed[i];

          if (params[k] === '') {
            params[k] = '__setEmptyValue';
          }
        }
      }());

      // @var ARRAY - We need to determine what DataItems we are going to send
      // with the request, send off the params and terms to find out
      changedDataItems = mxAdmin.helpers.getChangedDataItems(params, this.vocabTerms);

      // If there have been changes made, create the DataItem(s) member and set
      // its value to the array of changed items
      if (changedDataItems.length > 0) {
        model.transactionRequest.templates.update_mortgagee.CustomerChanges.Set.DataItem = changedDataItems;
      }

      // Create the object that will be converted into an XML TransactionRequest
      toSend = model.transactionRequest(CTX.policy).update_mortgagee(params);

      // Send the request
      model.pxcentral.policy.set(policy.id, toSend, {
        callback: function (data) {
          var opts      = {};
          opts.title = 'Mortgagee updated for ' + CTX.policyId;
          view.request_success(opts)();
        }
      });
        }
    }
}

view.update_risk = {
    load: function (params) {
    var id     = null,
      toSend = null;

        if (!CTX.policy) {
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
      id     = model.pxcentral.policy.id(CTX.policy);
            toSend = model.policyChangeSet(CTX.policy).update_risk(params);

            model.pxcentral.policy.set(id, toSend);
        }
    }
}

view.apply_charges = {

  // ARRAY
  vocabTerms: null,

  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var // OBJECT
      latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

      // ARRAY - Store the data items from the latest policy term
      termDataItems = latestTerm.DataItem,

      // OBJECT - The object we will provide to the template will contain all the
      // needed fields as defined in the vocabTerms. The values will be
      // retrieved from the policy DataItems
        toRet = mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms);

    return $.extend(true, {}, CTX, params, toRet);
  },

    load: function (params) {
    var id     = null,
      toSend = null;

        if (!CTX.policy) {
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
      id = model.pxcentral.policy.id(CTX.policy);

            params.amount = Math.abs(params.amount || 0);
            params.reasonCodeLabel = $('#id_reasonCode option[value=' + params.reasonCode + ']').html();
            params.lineItemType = params.reasonCodeLabel.toUpperCase().replace(/ /g, '_');

            toSend = model.policyChangeSet(CTX.policy).apply_charges(params);

            model.pxcentral.policy.set(id, toSend);
        }
    }
}

view.write_off = {

  // ARRAY
  vocabTerms: null,

  view: function (CTX, params) {
    if (!CTX.policy) {
      return CTX;
    }

    var // OBJECT
      latestTerm    = model.pxcentral.policy.getLastTerm(CTX.policy.InsurancePolicy),

      // ARRAY - Store the data items from the latest policy term
      termDataItems = latestTerm.DataItem,

      // OBJECT - The object we will provide to the template will contain all the
      // needed fields as defined in the vocabTerms. The values will be
      // retrieved from the policy DataItems
        toRet = mxAdmin.helpers.getDataItemValues(termDataItems, this.vocabTerms);

    return $.extend(true, {}, CTX, params, toRet);
  },

    load: function (params) {
        var id     = null,
      toSend = null;

    if (!CTX.policy) {
      return $address.trigger('nav', [HOME]);
    }

        if (params && !mxAdmin.helpers.isEmpty(params)) {
      id = model.pxcentral.policy.id(CTX.policy);

            params.amount = Math.abs(params.amount || 0);
            params.reasonCodeLabel = $('#id_reasonCode option[value=' + params.reasonCode + ']').html();

            toSend = model.policyChangeSet(CTX.policy).write_off(params);

            model.pxcentral.policy.set(id, toSend);
        }
    }
}
