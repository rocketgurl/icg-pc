### 3.1.0 - Apr 07, 2015

- Enable Google Analytics tracking of various views
- Reduce padding/margins in layout to better accommodate small screens
- Catch and log AJAX errors to Muscula
- The following IPM forms were modified:
    - Add ProtectionClassRating field and enums to ofcc-ho3/6-sc for rate filing changes
    - Update fnic-ho3-la IPM endorse forms to add Lapse in Coverage field
    - Update wic-ho3-tx to add earthquake coverage and related fields to the endorse IPM forms
    - Add Lapse in Coverage surcharge option to all eligible SageSure IPM endorse forms

### 3.0.6 - Mar 17, 2015

- Download attachments when using IE
- Display application documents and attachments in FNIC Quick View
- Retain column headings while scrolling through long lists
- Updates to various IPM forms
- Update HomeStyle enums in IPM forms
- Modify workspace to open attachments
- Add Cancel Status in the Vitals Bar so that users are aware of the potential loss of a policy
- Change the timeout error for search results so it's more descriptive

### 3.0.5 - Feb 23, 2015

- fixes the wrong effective date used on Pending Cancel Rescission
- fixes the inconsistent color on Cancel Request in Search
- removes Change Workspace for users with only one workspace
- adds Originating System in Quick View for Quotes and Policies where it was missing
- IPM forms populate Policy Limits Enum for Water Backup upon loading

### 3.0.4 - Feb 10, 2015

- Correct a problem in IE 11 where dropdown menus were not displaying completely in Manage Referral Assignees
- Correct a content display problem with Renewal Underwriting
- Complete updates to SC and ofcc-ho3-va IPM forms
- Properly line the content in Loss History
- Added a Cancel Search button to clear requests that take longer than expected

### 3.0.3 - Jan 27, 2015

**Non-Renewals workflow**

- Non-renewed policy has the option to Reinstate
- Non-renewed policy does not have the option to Set Pending Non-Renew
- Non-Renewal Workflow matches the documented outline

**New Business and Underwriting Referral Queues**

- Ability to Refresh each list
- Manage Referral Assignees is in Underwriting navigation

**QuickView - Property and Coverage**

- New QuickView page with Property and Coverage information

**Search Results to include Carrier ID**

- A new column should be added to the search results that includes CarrierID

**Underwriting Referrals to include Carrier ID**

- A new column should be added to the queue for CarrierID

### 3.0.2 - Jan 13, 2015

- [ICS-3046](https://icg360.atlassian.net/browse/ICS-3046)
    - corrected label on the policy nav not swiveling into place on IE10
    - fixed gradient transparency on the slideshow on IE10
    - tests on IE11 look good, too


- [ICS-2951](https://icg360.atlassian.net/browse/ICS-2951)
    - Help page with Support info, FAQ, and feedback
    - content driven by user role


- [ICS-2953](https://icg360.atlassian.net/browse/ICS-2953)
    - Notices content driven by user role


- [ICS-3086](https://icg360.atlassian.net/browse/ICS-3086)
    - Added EarthquakeMasonryVeneerExclusion on ofcc-ho3-nj and wic-ho3-nj endorse IPM forms

### 3.0.1 - Dec 22, 2014

- 'Manage Referral Assignees' is no longer on the Referrals page and is only in navigation
- 'Manage Referral Assignees' links to the 'Manage Referral Assignees' list in a pop-up modal
- 'New Business Referrals' in navigation should be 'New Business Underwriting'
- 'Renewal Underwriting' in navigation is per program (SageSure uses, FNIC should not see)

### 3.0.0 - Dec 9, 2014

This is the new generation UI for Policy Central where a new, overall Policy Central navigation, and a new vertical navigation for open policies are the highlights. Other features include:

- Overall Policy Central navigation includes Home, Search, Servicing, Underwriting, Agencies, Reports
  - Links are program specific
- New Home page
  - the Home page has a slide show
  - the Home page has a way to get to Herald announcements
  - the Home page has a way to show Agent Portal announcements
    - also program specific
- New Policy Navigation left navigation is collapsible, similar to Open Policy Navigation
  - the navigation is sticky - it is always available to the user, even if the page scrolls
- New Open Policy navigation to the left of the policy
  - that list is collapsable
  - there is a filter to search the open policies
  - recently viewed policies fill the space below any open policies

### 2.7.2 - Nov 18, 2014

- [ICS-2913](https://icg360.atlassian.net/browse/ICS-2913) - Updates wic-ho3-tx IPM endorse forms
- [ICS-2929](https://icg360.atlassian.net/browse/ICS-2929) - a new Welcome page
- [ICS-2932](https://icg360.atlassian.net/browse/ICS-2932) - a new top level of navigation
– Servicing includes a link to Batch Wolf & Underwriting includes New Business Referrals and Renewal Underwriting
– includes a link to [ixReports](https://ixreport.ics360.com/rfk/root/) and [Agency Administration](https://agencyadmin.icg360.com/)
- [ICS-2933](https://icg360.atlassian.net/browse/ICS-2933) - a new floating footer
- [ICS-2938](https://icg360.atlassian.net/browse/ICS-2938) - Adds Google Analytics to Policy Central
- [ICS-2945](https://icg360.atlassian.net/browse/ICS-2945) - a new pop-up module to accommodate content such as Help, Support, and Feedback
- [ICS-2965](https://icg360.atlassian.net/browse/ICS-2965) - Add OptionCoverageD for ofcc-ho3-ak so CoverageD calculations work
- [ICS-2966](https://icg360.atlassian.net/browse/ICS-2966) - Updates fnic-ho3-al IPM endorse forms

### 2.7.1 - Nov 4, 2014

- [ICS-2908](https://icg360.atlassian.net/browse/ICS-2908) Update ixConfig to enable Policy Central for FedNat
- [ICS-2915](https://icg360.atlassian.net/browse/ICS-2915) Update import renewal products

### 2.7.0 - Oct 21, 2014

- [ICS-1643](https://icg360.atlassian.net/browse/ICS-1643) Update referral tab to achieve parity with Insight Central
- [ICS-2870](https://icg360.atlassian.net/browse/ICS-2870) Quick View Last Payment Received format and date
- [ICS-2891](https://icg360.atlassian.net/browse/ICS-2891) Investigate InsuredByCorporation field in DP3 IPM forms
- [ICS-2901](https://icg360.atlassian.net/browse/ICS-2901) Update ofcc-(dp1/dp2/dp3)-la IPM Endorse forms
- [ICS-2902](https://icg360.atlassian.net/browse/ICS-2902) Update ofcc-ho3-ny IPM Endorse forms
- [ICS-2903](https://icg360.atlassian.net/browse/ICS-2903) Update fnic-ho3-la IPM renewal forms
- [ICS-2906](https://icg360.atlassian.net/browse/ICS-2906) Update ofcc-ho3-ak IPM Endorse forms
- [ICS-2907](https://icg360.atlassian.net/browse/ICS-2907) Update iic-ho3-sc endorse forms
- [ICS-2910](https://icg360.atlassian.net/browse/ICS-2910) Update fnic-ho3-al IPM endorse forms

### 2.6.5 - Oct 7, 2014

- [ICS-2033](https://icg360.atlassian.net/browse/ICS-2033) Payee fields need to be updated when insured's mailing address gets updated
- [ICS-2034](https://icg360.atlassian.net/browse/ICS-2034) Update the payor fields on a policy when changing payment plan, customer info, or mortgagee
- [ICS-2890](https://icg360.atlassian.net/browse/ICS-2890) Update Cladding enums
- [ICS-2861](https://icg360.atlassian.net/browse/ICS-2861) Update fnic-ho3-al IPM endorse forms

### 2.6.4 - Sep 23, 2014

- [ICS-2833](https://icg360.atlassian.net/browse/ICS-2833) Update Policy Central to allow a full qualified ixLibrary URI
- [ICS-2716](https://icg360.atlassian.net/browse/ICS-2716) Create visual linkage in Policy Central for Dovetail transferred policies
- [ICS-2824](https://icg360.atlassian.net/browse/ICS-2824) Create fnic-ho3-al IPM Endorse forms
- [ICS-2837](https://icg360.atlassian.net/browse/ICS-2837) Update ofcc-ho3-ak IPM Endorse forms

### 2.6.3 - Sep 9, 2014

- [ICS-2754](https://icg360.atlassian.net/browse/ICS-2754) Update Agency Data Information when changing Broker of Record
- [ICS-2796](https://icg360.atlassian.net/browse/ICS-2796) Update ofcc-ho3-ak IPM Endorse forms
- [ICS-2798](https://icg360.atlassian.net/browse/ICS-2798) Update fnic-ho3-la IPM endorse forms

### 2.6.2 - Aug 26, 2014

- [ICS-2730](https://icg360.atlassian.net/browse/ICS-2730) QuickView documents show current datetime instead of document datetime
- [ICS-2736](https://icg360.atlassian.net/browse/ICS-2736) Quick View Notes displaying HTML codes instead of symbols
- [ICS-2770](https://icg360.atlassian.net/browse/ICS-2770) Include Muscula in Policy Central for Stage & Prod
- [ICS-2734](https://icg360.atlassian.net/browse/ICS-2734) Add new reason code to be used when a non-payment PCN is being rescinded for a UW PCN
- [ICS-2766](https://icg360.atlassian.net/browse/ICS-2766) Update acic-ho3-sc IPM Endorse forms
- [ICS-2767](https://icg360.atlassian.net/browse/ICS-2767) Update ofcc-ho3-ak IPM Endorse forms

### 2.6.1.3 - Aug 5, 2014

- [ICS-2601](https://icg360.atlassian.net/browse/ICS-2601) Fixes Pending Cancel showing up inappropriately 
- [ICS-2724](https://icg360.atlassian.net/browse/ICS-2724) Adds a header status for Pending Non-Renewal on a policy view so that it is visible on all views, not just Quick View
- [ICS-2725](https://icg360.atlassian.net/browse/ICS-2725) Fixes policies that were showing an erroneous "0" in Quick View Payment
- [ICS-2728](https://icg360.atlassian.net/browse/ICS-2728) Adds sanitizing functionality to Notes in Quick View - helps with URL cut and paste
- [ICS-2735](https://icg360.atlassian.net/browse/ICS-2735) Fixes Change Disposition popup problem that was keeping users from selecting from the drop down

### 2.6.0 - Jul 29, 2014

- [ICS-2374](https://icg360.atlassian.net/browse/ICS-2374) Introducing Policy Central HTML Quick View
- [ICS-2693](https://icg360.atlassian.net/browse/ICS-2693) Update wic-ho3-nj and ofcc-ho3-nj IPM endorse/renewal forms for WindstormDeductibleOption choices
- [ICS-2700](https://icg360.atlassian.net/browse/ICS-2700) Update ofcc-ho3-ca IPM forms for SecuritiesSpecialLimits enum
- [ICS-2709](https://icg360.atlassian.net/browse/ICS-2709) Change DataType for InsuredMailingAddressZip in Change Customer Forms
- [ICS-2713](https://icg360.atlassian.net/browse/ICS-2713) Update wic-al Renewal IPM forms for WindstormDeductibleOption

### 2.5.6 - Jul 15, 2014

- [ICS-2667](https://icg360.atlassian.net/browse/ICS-2667) Update ofcc-ak-ho3 Endorse forms for Other Structures
- [ICS-2683](https://icg360.atlassian.net/browse/ICS-2683) Add Lapse in Coverage Surcharge to ofcc-dp3-ny
- [ICS-2684](https://icg360.atlassian.net/browse/ICS-2684) Update fnic-ho3-la renewal forms
- [ICS-2685](https://icg360.atlassian.net/browse/ICS-2685) Update iic-ho3-sc renewal forms
- [ICS-2686](https://icg360.atlassian.net/browse/ICS-2686) Update ofcc-ho3-ca renewal forms
- [ICS-2687](https://icg360.atlassian.net/browse/ICS-2687) Reason Code additions to wic-dp3-al
- [ICS-2688](https://icg360.atlassian.net/browse/ICS-2688) Remove MultiPolicy from wic-hwo-al IPM endorse forms
- [ICS-2689](https://icg360.atlassian.net/browse/ICS-2689) Add reason code to iic-ho3-sc

### 2.5.5 - Jun 10, 2014

- [ICS-2572](https://icg360.atlassian.net/browse/ICS-2572) Ability to change payment plan prior to new term effective date
- [ICS-2600](https://icg360.atlassian.net/browse/ICS-2600) Add Reason code to Change Customer forms
- [ICS-2610](https://icg360.atlassian.net/browse/ICS-2610) AdditionalInterest1AddressState is not in TransactionReqest when deleting additional interests
- [ICS-2621](https://icg360.atlassian.net/browse/ICS-2621) Add Reason Code to ofcc-ho3-ak
- [ICS-2623](https://icg360.atlassian.net/browse/ICS-2623) Update ofcc-ny-ho3 Endorse enums

### 2.5.4 - May 28, 2014

- [ICS-2572](https://icg360.atlassian.net/browse/ICS-2572) Ability to change payment plan prior to new term effective date
- [ICS-2582](https://icg360.atlassian.net/browse/ICS-2582) Additional interest IPM form not pulling the right variables for Additional Interests
- [ICS-2583](https://icg360.atlassian.net/browse/ICS-2583) Policy Central - Improve footer behavior & version display
- [ICS-2596](https://icg360.atlassian.net/browse/ICS-2596) Update iic-ho3-sc endorse forms
- [ICS-2599](https://icg360.atlassian.net/browse/ICS-2599) Update fnic-ho3-la endorse forms
- [ICS-2603](https://icg360.atlassian.net/browse/ICS-2603) Add EQ Coverage to NJ IPM Forms
- [ICS-2605](https://icg360.atlassian.net/browse/ICS-2605) Mortgagee1AddressState is not in TransactionReqest when deleting mortgagee
- [ICS-2607](https://icg360.atlassian.net/browse/ICS-2607) Update wic-al IPM Endorse forms
- [ICS-2608](https://icg360.atlassian.net/browse/ICS-2608) Add Lapse in Coverage Surcharge to ofcc-ho3-ny

### 2.5.3 - May 14, 2014

- [ICS-2521](https://icg360.atlassian.net/browse/ICS-2521) Update Favicon to show "working" state
- [ICS-2533](https://icg360.atlassian.net/browse/ICS-2533) Non-Renewal Actions Need a Functioning Comments Box
- [ICS-2537](https://icg360.atlassian.net/browse/ICS-2537) Fix Policy Transaction Request for Issuance - Effective Date
- [ICS-2573](https://icg360.atlassian.net/browse/ICS-2573) Add conditional logic to ofcc-ho6-sc endorse forms
- [ICS-2575](https://icg360.atlassian.net/browse/ICS-2575) Issue with EffectiveDate greater than EffectiveDatePolicyTerm

### 2.5.2 - Apr 30, 2014

- [ICS-2520](https://icg360.atlassian.net/browse/ICS-2520) Error discovered on Cancel/Reinstate Action From in Policy Central
- [ICS-2541](https://icg360.atlassian.net/browse/ICS-2541) As a user of Policy Central, I would like to be able to refresh my policy tab so that I can ensure I have the most recent version of the policy
- [ICS-2542](https://icg360.atlassian.net/browse/ICS-2542) Add conditional logic to ofcc-ho3-ca endorse forms
- [ICS-2549](https://icg360.atlassian.net/browse/ICS-2549) Update fsic endorse forms
- [ICS-2552](https://icg360.atlassian.net/browse/ICS-2552) Update ofcc-la-ho3-lap endorse forms
- [ICS-2553](https://icg360.atlassian.net/browse/ICS-2553) Unable to process cancellation to prior term
- [ICS-2557](https://icg360.atlassian.net/browse/ICS-2557) Add conditional logic to ofcc-ho3-ak forms

### 2.5.1 - Apr 16, 2014

- [ICS-2410](https://icg360.atlassian.net/browse/ICS-2410) "Unlock Policy" should be available for quotes only
- [ICS-2523](https://icg360.atlassian.net/browse/ICS-2523) Cancellations Should Not Allow Effective Dates prior to policy inception date
- [ICS-2530](https://icg360.atlassian.net/browse/ICS-2530) Add "Replacement Policy Placed with other SageSure Carrier" reasoncode to all CRU-4 Programs
- [ICS-2531](https://icg360.atlassian.net/browse/ICS-2531) Add additional OptionCoverageB enums to FSIC-DP3-LA Endorse Forms
- [ICS-2535](https://icg360.atlassian.net/browse/ICS-2535) Add enum/Reason Code to FNIC-HO3-LA endorse forms
- [ICS-2538](https://icg360.atlassian.net/browse/ICS-2538) Update wic-nj-ho3 renew forms

### 2.5.0 - Apr 03, 2014

- [ICS-2423](https://icg360.atlassian.net/browse/ICS-2423) Update fsic-la-ho3 forms
- [ICS-2447](https://icg360.atlassian.net/browse/ICS-2447) Update fsic-la-dp3 customer change forms
- [ICS-2448](https://icg360.atlassian.net/browse/ICS-2448) Update IPM forms for DistanceToFireDepartment
- [ICS-2449](https://icg360.atlassian.net/browse/ICS-2449) Update ofcc-ny-ho3 IPM forms
- [ICS-2464](https://icg360.atlassian.net/browse/ICS-2464) Add Protection Class fields to ofcc-va-ho3
- [ICS-2471](https://icg360.atlassian.net/browse/ICS-2471) Update fnic-la-ho3 IPM endorse forms
- [ICS-2475](https://icg360.atlassian.net/browse/ICS-2475) Handle IPM program naming collision for LA preferred product
- [ICS-2478](https://icg360.atlassian.net/browse/ICS-2478) Update wic-al IPM forms
- [ICS-2479](https://icg360.atlassian.net/browse/ICS-2479) Create endorse forms for OFCC LA to IPM platform
- [ICS-2486](https://icg360.atlassian.net/browse/ICS-2486) Improve Zendesk ticket search

### 2.4.5

- [ICS-2408](https://icg360.atlassian.net/browse/ICS-2408) Change Birthdate formats for IPM Customer Changes to mm/dd/yyyy
- [ICS-2419](https://icg360.atlassian.net/browse/ICS-2419) Added Loss History at binding to be available for all policies
- [ICS-2429](https://icg360.atlassian.net/browse/ICS-2429) FSIC Renew Forms for HO3/DP3
- [ICS-2431](https://icg360.atlassian.net/browse/ICS-2431) Fix problems preventing Additional Insured forms from updating
- [ICS-2443](https://icg360.atlassian.net/browse/ICS-2443) Update WIC HO3 AL IPM Endorse forms
- [ICS-2445](https://icg360.atlassian.net/browse/ICS-2445) Update WIC HWO AL IPM Endorse forms

### 2.4.4

- [ICSREQ-819](https://icg360.atlassian.net/browse/ICSREQ-819) Fixing errors related to renewal underwriting tab not loading for certain policies

### 2.4.3

- [ICS-2324](https://icg360.atlassian.net/browse/ICS-2324) Fixing automated note adding on cancellation forms
- [ICS-2330](https://icg360.atlassian.net/browse/ICS-2330) Fixing endorse form required
- [ICS-2372](https://icg360.atlassian.net/browse/ICS-2372) Update IIC-HO3-SC endorse forms
- [ICS-2397](https://icg360.atlassian.net/browse/ICS-2397) Create ofcc-ny-ho3 IPM endorse forms
- [ICS-2399](https://icg360.atlassian.net/browse/ICS-2399) SquareFootUnderRoofFLA for wic-al-ho3/hwo


...


### 2.3.1

- RCE updates

### 2.3.0

- Comment box for PCN is not carrying data over in IPM [ICS-2362](https://arc90dev.atlassian.net/browse/ICS-2362)
- California Coverage amounts not updating [ICS-2353](https://arc90dev.atlassian.net/browse/ICS-2353)
- As a Processor, I would like to be able to unlock a policy through IPM [ICS-2342](https://arc90dev.atlassian.net/browse/ICS-2342)
- As a policy servicer, I want Policy Central to support payment plan changes by submitting a TransactionRequest of type AccountingChanges. [ICS-2092](https://arc90dev.atlassian.net/browse/ICS-2092)
- Update FSIC-DP3-LA Endorse Forms	 Critical [ICS-2352](https://arc90dev.atlassian.net/browse/ICS-2352)
- Add field to OFCC/WIC-HO3-NJ Endorse Forms [ICS-2354](https://arc90dev.atlassian.net/browse/ICS-2354)

### 2.2.8

- Created IIC-HO3-SC Endorse forms
  [ICS-2337](https://arc90dev.atlassian.net/browse/ICS-2337)
- Enable post-bind for Occidental CA product
  [ICS-2261](https://arc90dev.atlassian.net/browse/ICS-2261)
- Updated deductibles for WIC AL Endorse forms
  [ICS-2269](https://arc90dev.atlassian.net/browse/ICS-2269)
- Add addtional enums to FNIC-HO3-LA endorse form
  [ICS-2270](https://arc90dev.atlassian.net/browse/ICS-2270)

### 2.2.7

- Updated FSIC-HO3-LA Endorse form [ICS-2272](https://arc90dev.atlassian.net/browse/ICS-2272)
- Updated WIC-HO3/HWO-AL, HIC-HO3-LA, WIC-HO3-LA, WIC-HO3-NJ,
  OFCC-HO3-NJ, OFCC-DP3-NY Endorse forms [ICS-2271](https://arc90dev.atlassian.net/browse/ICS-2271)

### 2.2.6

- Fixes for Change Customer [ICS-2144](https://arc90dev.atlassian.net/browse/ICS-2144)

### 2.2.5

- Provided access to additional IPM functions:
 - Change Customer [ICS-2144](https://arc90dev.atlassian.net/browse/ICS-2144)
 - Update Mortgagee [ICS-2145](https://arc90dev.atlassian.net/browse/ICS-2145)
 - Change Additional Interest [ICS-2146](https://arc90dev.atlassian.net/browse/ICS-2146)
 - Write off Charges [ICS-2147](https://arc90dev.atlassian.net/browse/ICS-2147)


### 2.2.3

-	IPM Endorse now uses correct term [ICS-1972](https://arc90dev.atlassian.net/browse/ICS-1972)
-	Carrier users cannot access specific interfaces [ICS-2019](https://arc90dev.atlassian.net/browse/ICS-2019)
-	Broker of Record change now requires an AgentId [ICS-2042](https://arc90dev.atlassian.net/browse/ICS-2042)
-	Corrected link to XML representations [ICS-1869](https://arc90dev.atlassian.net/browse/ICS-1869)
-	Now using a Transaction Request for invoicing [ICS-2036](https://arc90dev.atlassian.net/browse/ICS-2036)
-	PolicySummary SWF module is now loaded from S3 [ICS-2013](https://arc90dev.atlassian.net/browse/ICS-2013)

### 2.2.2

- 	Carrier users no longer have access to IPM, Zendesk or Renewal Underwriting [ICS-2019](https://arc90dev.atlassian.net/browse/ICS-2019)
-	IPM Invoice Action now uses a Transaction Request and no longer requires any form fields.

### 2.2.1

Bug fixes:

-	Fixed incorrect links in Policy Representation
-	Fixed issue in IPM Endorse where incorrect Term was used to populate form

### 2.2.0

- Broker of Record Change now available for all policies

### 2.1.5

- Now with Broker of Record action for Dovetail policies

### 2.1.3

- Now with Broker of Record IPM Action

### 2.1.2

Bug fixes:

-	Fixed issue with IPM Apply Charges not completing [ICS-1894](https://arc90dev.atlassian.net/browse/ICS-1894)
-	IPM Cancellations now working [ICS-1897](https://arc90dev.atlassian.net/browse/ICS-1897)

### 2.1.1

Updates:

-	Added Policy Representations view to Policy Module [ICS-1870](https://arc90dev.atlassian.net/browse/ICS-1870)
-	Updated Herald to 1.0

### 2.1.0.2

Updates:

-	Added [Herald](https://github.com/icg360/Herald)
-	Brought IPM Endorse up to parity with mxAdmin Endorse
-	IPM Datefields now have calendar icon
-	IPM currency inputs now have icon

Bug fixes:

-	Corrected ID collisions in IPM forms which prevented correct use of datepicker
