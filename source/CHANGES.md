Updates
-------

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
