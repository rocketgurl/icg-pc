define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/IPM/IPMModule",
  "modules/IPM/IPMView",
  "modules/IPM/IPMActionView",
  "modules/Policy/PolicyModel",
  "modules/IPM/IPMChangeSet",
  "modules/IPM/actions/Endorse",
  "modules/IPM/actions/CancelReinstate",
  "UserModel",
  "amplify",
  "loader",
  "xml2json"], 
  function(
    $, 
    _, 
    WorkspaceController, 
    IPMModule,
    IPMView,
    IPMActionView,
    PolicyModel,
    IPMChangeSet,
    Endorse,
    CancelReinstate,
    UserModel,
    amplify, 
    CanvasLoader
) {

var user = {}

user = new UserModel({
  urlRoot  : 'mocks/',
  username : 'cru4t@cru360.com',
  password : 'abc123'
});

// Load up a Policy and then an IPMModule
var policy = new PolicyModel({
  id      : '71049-active.xml',
  urlRoot : 'mocks/',
  digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
});

var ipm = window.ipm = new IPMModule(policy, $('<div></div>'), user);

var modeljs = {
    "terms": [
        {
            "name": "effectiveDate",
            "label": "Effective Date"
        },
        {
            "name": "comment",
            "label": "Comment"
        },
        {
            "name": "PropertyStreetNumber",
            "label": "Street Number"
        },
        {
            "name": "PropertyStreetName",
            "label": "Street Name"
        },
        {
            "name": "PropertyAddressLine2",
            "label": "Address Line 2"
        },
        {
            "name": "PropertyCity",
            "label": "City"
        },
        {
            "name": "PropertyState",
            "label": "State"
        },
        {
            "name": "PropertyZipCode",
            "label": "Zip Code"
        },
        {
            "name": "PropertyZipCodePlusFour",
            "label": "Zip Plus Four"
        },
        {
            "name": "PropertyHazardLocationLastUpdated",
            "label": "Property Hazard Location Last Updated"
        },
        {
            "name": "DistanceToCoast",
            "label": "Distance To Primary Coastline"
        },
        {
            "name": "DistanceToCoastSecondary",
            "label": "Distance To Secondary Coastline"
        },
        {
            "name": "ReplacementCostBuilding",
            "label": "Replacement Cost Of Dwelling"
        },
        {
            "name": "CoverageA",
            "label": "Coverage A"
        },
        {
            "name": "CoverageB",
            "label": "Coverage B"
        },
        {
            "name": "CoverageC",
            "label": "Coverage C"
        },
        {
            "name": "CoverageD",
            "label": "Coverage D"
        },
        {
            "name": "OtherStructures1Coverage",
            "label": "1st Scheduled Structure - Limit"
        },
        {
            "name": "OtherStructures1BusinessType",
            "label": "1st Scheduled Structure - Business Type"
        },
        {
            "name": "OtherStructures2Coverage",
            "label": "2nd Scheduled Structure - Limit"
        },
        {
            "name": "OtherStructures2BusinessType",
            "label": "2nd Scheduled Structure - Business Type"
        },
        {
            "name": "OtherStructures3Coverage",
            "label": "3rd Scheduled Structure - Limit"
        },
        {
            "name": "OtherStructures3BusinessType",
            "label": "3rd Scheduled Structure - Business Type"
        },
        {
            "name": "SquareFootUnderRoof",
            "label": "Living Area"
        },
        {
            "name": "ConstructionYear",
            "label": "Construction Year - Dwelling"
        },
        {
            "name": "ConstructionYearRoof",
            "label": "Construction Year - Roof"
        },
        {
            "name": "TrustName",
            "label": "Trust Name"
        },
        {
            "name": "TrusteeName",
            "label": "Trustee Name"
        },
        {
            "name": "GrantorName",
            "label": "Grantor Name"
        },
        {
            "name": "BeneficiaryName",
            "label": "Beneficiary Name"
        },
        {
            "name": "IncidentalBusinessOccupancyType",
            "label": "Business Type"
        },
        {
            "name": "IncidentalBusinessOccupancyDescription",
            "label": "Business Description"
        },
        {
            "name": "AutoPolicyCarrier",
            "label": "Auto Policy Carrier"
        },
        {
            "name": "AutoPolicyNumber",
            "label": "Auto Policy Number"
        },
        {
            "name": "Insured1BirthDate",
            "label": "Insured Date Of Birth"
        },
        {
            "name": "ScheduledPersonalProperty1Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty1Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty2Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty2Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty3Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty3Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty4Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty4Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty5Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty5Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty6Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty6Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty7Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty7Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty8Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty8Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty9Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty9Description",
            "label": "Description"
        },
        {
            "name": "ScheduledPersonalProperty10Limit",
            "label": "Limit"
        },
        {
            "name": "ScheduledPersonalProperty10Description",
            "label": "Description"
        },
        {
            "name": "LossAmount1",
            "label": "Amount"
        },
        {
            "name": "LossDate1",
            "label": "Date"
        },
        {
            "name": "LossDescription1",
            "label": "Description"
        },
        {
            "name": "LossAmount2",
            "label": "Amount"
        },
        {
            "name": "LossDate2",
            "label": "Date"
        },
        {
            "name": "LossDescription2",
            "label": "Description"
        },
        {
            "name": "LossAmount3",
            "label": "Amount"
        },
        {
            "name": "LossDate3",
            "label": "Date"
        },
        {
            "name": "LossDescription3",
            "label": "Description"
        },
        {
            "name": "LossAmount4",
            "label": "Amount"
        },
        {
            "name": "LossDate4",
            "label": "Date"
        },
        {
            "name": "LossDescription4",
            "label": "Description"
        },
        {
            "name": "LossAmount5",
            "label": "Amount"
        },
        {
            "name": "LossDate5",
            "label": "Date"
        },
        {
            "name": "LossDescription5",
            "label": "Description"
        },
        {
            "name": "AdditionalInsured1AddressState",
            "label": "Additional Insured 1 Address State",
            "enumerations": [
                {
                    "label": "AK",
                    "value": "AK"
                },
                {
                    "label": "AL",
                    "value": "AL"
                },
                {
                    "label": "AR",
                    "value": "AR"
                },
                {
                    "label": "AZ",
                    "value": "AZ"
                },
                {
                    "label": "CA",
                    "value": "CA"
                },
                {
                    "label": "CO",
                    "value": "CO"
                },
                {
                    "label": "CT",
                    "value": "CT"
                },
                {
                    "label": "DC",
                    "value": "DC"
                },
                {
                    "label": "DE",
                    "value": "DE"
                },
                {
                    "label": "FL",
                    "value": "FL"
                },
                {
                    "label": "GA",
                    "value": "GA"
                },
                {
                    "label": "HI",
                    "value": "HI"
                },
                {
                    "label": "IA",
                    "value": "IA"
                },
                {
                    "label": "ID",
                    "value": "ID"
                },
                {
                    "label": "IL",
                    "value": "IL"
                },
                {
                    "label": "IN",
                    "value": "IN"
                },
                {
                    "label": "KS",
                    "value": "KS"
                },
                {
                    "label": "KY",
                    "value": "KY"
                },
                {
                    "label": "LA",
                    "value": "LA"
                },
                {
                    "label": "MA",
                    "value": "MA"
                },
                {
                    "label": "MD",
                    "value": "MD"
                },
                {
                    "label": "ME",
                    "value": "ME"
                },
                {
                    "label": "MI",
                    "value": "MI"
                },
                {
                    "label": "MN",
                    "value": "MN"
                },
                {
                    "label": "MO",
                    "value": "MO"
                },
                {
                    "label": "MS",
                    "value": "MS"
                },
                {
                    "label": "MT",
                    "value": "MT"
                },
                {
                    "label": "NC",
                    "value": "NC"
                },
                {
                    "label": "ND",
                    "value": "ND"
                },
                {
                    "label": "NE",
                    "value": "NE"
                },
                {
                    "label": "NH",
                    "value": "NH"
                },
                {
                    "label": "NJ",
                    "value": "NJ"
                },
                {
                    "label": "NM",
                    "value": "NM"
                },
                {
                    "label": "NV",
                    "value": "NV"
                },
                {
                    "label": "NY",
                    "value": "NY"
                },
                {
                    "label": "OH",
                    "value": "OH"
                },
                {
                    "label": "OK",
                    "value": "OK"
                },
                {
                    "label": "OR",
                    "value": "OR"
                },
                {
                    "label": "PA",
                    "value": "PA"
                },
                {
                    "label": "RI",
                    "value": "RI"
                },
                {
                    "label": "SC",
                    "value": "SC"
                },
                {
                    "label": "SD",
                    "value": "SD"
                },
                {
                    "label": "TN",
                    "value": "TN"
                },
                {
                    "label": "TX",
                    "value": "TX"
                },
                {
                    "label": "UT",
                    "value": "UT"
                },
                {
                    "label": "VA",
                    "value": "VA"
                },
                {
                    "label": "VT",
                    "value": "VT"
                },
                {
                    "label": "WA",
                    "value": "WA"
                },
                {
                    "label": "WI",
                    "value": "WI"
                },
                {
                    "label": "WV",
                    "value": "WV"
                },
                {
                    "label": "WY",
                    "value": "WY"
                }
            ]
        },
        {
            "name": "AdditionalInsured2AddressState",
            "label": "Additional Insured 2 Address State",
            "enumerations": [
                {
                    "label": "AK",
                    "value": "AK"
                },
                {
                    "label": "AL",
                    "value": "AL"
                },
                {
                    "label": "AR",
                    "value": "AR"
                },
                {
                    "label": "AZ",
                    "value": "AZ"
                },
                {
                    "label": "CA",
                    "value": "CA"
                },
                {
                    "label": "CO",
                    "value": "CO"
                },
                {
                    "label": "CT",
                    "value": "CT"
                },
                {
                    "label": "DC",
                    "value": "DC"
                },
                {
                    "label": "DE",
                    "value": "DE"
                },
                {
                    "label": "FL",
                    "value": "FL"
                },
                {
                    "label": "GA",
                    "value": "GA"
                },
                {
                    "label": "HI",
                    "value": "HI"
                },
                {
                    "label": "IA",
                    "value": "IA"
                },
                {
                    "label": "ID",
                    "value": "ID"
                },
                {
                    "label": "IL",
                    "value": "IL"
                },
                {
                    "label": "IN",
                    "value": "IN"
                },
                {
                    "label": "KS",
                    "value": "KS"
                },
                {
                    "label": "KY",
                    "value": "KY"
                },
                {
                    "label": "LA",
                    "value": "LA"
                },
                {
                    "label": "MA",
                    "value": "MA"
                },
                {
                    "label": "MD",
                    "value": "MD"
                },
                {
                    "label": "ME",
                    "value": "ME"
                },
                {
                    "label": "MI",
                    "value": "MI"
                },
                {
                    "label": "MN",
                    "value": "MN"
                },
                {
                    "label": "MO",
                    "value": "MO"
                },
                {
                    "label": "MS",
                    "value": "MS"
                },
                {
                    "label": "MT",
                    "value": "MT"
                },
                {
                    "label": "NC",
                    "value": "NC"
                },
                {
                    "label": "ND",
                    "value": "ND"
                },
                {
                    "label": "NE",
                    "value": "NE"
                },
                {
                    "label": "NH",
                    "value": "NH"
                },
                {
                    "label": "NJ",
                    "value": "NJ"
                },
                {
                    "label": "NM",
                    "value": "NM"
                },
                {
                    "label": "NV",
                    "value": "NV"
                },
                {
                    "label": "NY",
                    "value": "NY"
                },
                {
                    "label": "OH",
                    "value": "OH"
                },
                {
                    "label": "OK",
                    "value": "OK"
                },
                {
                    "label": "OR",
                    "value": "OR"
                },
                {
                    "label": "PA",
                    "value": "PA"
                },
                {
                    "label": "RI",
                    "value": "RI"
                },
                {
                    "label": "SC",
                    "value": "SC"
                },
                {
                    "label": "SD",
                    "value": "SD"
                },
                {
                    "label": "TN",
                    "value": "TN"
                },
                {
                    "label": "TX",
                    "value": "TX"
                },
                {
                    "label": "UT",
                    "value": "UT"
                },
                {
                    "label": "VA",
                    "value": "VA"
                },
                {
                    "label": "VT",
                    "value": "VT"
                },
                {
                    "label": "WA",
                    "value": "WA"
                },
                {
                    "label": "WI",
                    "value": "WI"
                },
                {
                    "label": "WV",
                    "value": "WV"
                },
                {
                    "label": "WY",
                    "value": "WY"
                }
            ]
        },
        {
            "name": "AdditionalInsured3AddressState",
            "label": "Additional Insured 3 Address State",
            "enumerations": [
                {
                    "label": "AK",
                    "value": "AK"
                },
                {
                    "label": "AL",
                    "value": "AL"
                },
                {
                    "label": "AR",
                    "value": "AR"
                },
                {
                    "label": "AZ",
                    "value": "AZ"
                },
                {
                    "label": "CA",
                    "value": "CA"
                },
                {
                    "label": "CO",
                    "value": "CO"
                },
                {
                    "label": "CT",
                    "value": "CT"
                },
                {
                    "label": "DC",
                    "value": "DC"
                },
                {
                    "label": "DE",
                    "value": "DE"
                },
                {
                    "label": "FL",
                    "value": "FL"
                },
                {
                    "label": "GA",
                    "value": "GA"
                },
                {
                    "label": "HI",
                    "value": "HI"
                },
                {
                    "label": "IA",
                    "value": "IA"
                },
                {
                    "label": "ID",
                    "value": "ID"
                },
                {
                    "label": "IL",
                    "value": "IL"
                },
                {
                    "label": "IN",
                    "value": "IN"
                },
                {
                    "label": "KS",
                    "value": "KS"
                },
                {
                    "label": "KY",
                    "value": "KY"
                },
                {
                    "label": "LA",
                    "value": "LA"
                },
                {
                    "label": "MA",
                    "value": "MA"
                },
                {
                    "label": "MD",
                    "value": "MD"
                },
                {
                    "label": "ME",
                    "value": "ME"
                },
                {
                    "label": "MI",
                    "value": "MI"
                },
                {
                    "label": "MN",
                    "value": "MN"
                },
                {
                    "label": "MO",
                    "value": "MO"
                },
                {
                    "label": "MS",
                    "value": "MS"
                },
                {
                    "label": "MT",
                    "value": "MT"
                },
                {
                    "label": "NC",
                    "value": "NC"
                },
                {
                    "label": "ND",
                    "value": "ND"
                },
                {
                    "label": "NE",
                    "value": "NE"
                },
                {
                    "label": "NH",
                    "value": "NH"
                },
                {
                    "label": "NJ",
                    "value": "NJ"
                },
                {
                    "label": "NM",
                    "value": "NM"
                },
                {
                    "label": "NV",
                    "value": "NV"
                },
                {
                    "label": "NY",
                    "value": "NY"
                },
                {
                    "label": "OH",
                    "value": "OH"
                },
                {
                    "label": "OK",
                    "value": "OK"
                },
                {
                    "label": "OR",
                    "value": "OR"
                },
                {
                    "label": "PA",
                    "value": "PA"
                },
                {
                    "label": "RI",
                    "value": "RI"
                },
                {
                    "label": "SC",
                    "value": "SC"
                },
                {
                    "label": "SD",
                    "value": "SD"
                },
                {
                    "label": "TN",
                    "value": "TN"
                },
                {
                    "label": "TX",
                    "value": "TX"
                },
                {
                    "label": "UT",
                    "value": "UT"
                },
                {
                    "label": "VA",
                    "value": "VA"
                },
                {
                    "label": "VT",
                    "value": "VT"
                },
                {
                    "label": "WA",
                    "value": "WA"
                },
                {
                    "label": "WI",
                    "value": "WI"
                },
                {
                    "label": "WV",
                    "value": "WV"
                },
                {
                    "label": "WY",
                    "value": "WY"
                }
            ]
        },
        {
            "name": "AdditionalInterest1Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Other",
                    "value": "999"
                }
            ]
        },
        {
            "name": "AdditionalInterest2Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Other",
                    "value": "999"
                }
            ]
        },
        {
            "name": "AdditionalInterest3Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Other",
                    "value": "999"
                }
            ]
        },
        {
            "name": "AdjacentPropertyCondition",
            "label": "Is the adjacent property in poor condition?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "AllOtherPerilsDeductible",
            "label": "All Other Perils Deductible $",
            "enumerations": [
                {
                    "label": "$250",
                    "value": "2.5"
                },
                {
                    "label": "$500",
                    "value": "5"
                },
                {
                    "label": "$1,000",
                    "value": "10"
                },
                {
                    "label": "$2,000",
                    "value": "20"
                },
                {
                    "label": "$2,500",
                    "value": "25"
                },
                {
                    "label": "$3,000",
                    "value": "30"
                },
                {
                    "label": "$4,000",
                    "value": "40"
                },
                {
                    "label": "$5,000",
                    "value": "50"
                }
            ]
        },
        {
            "name": "AllWeatherAccess",
            "label": "Accessible In All Weather?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "AnimalLiability",
            "label": "Limited Dog Liability",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "BarrierIsland",
            "label": "Barrier Island",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "Basement",
            "label": "Basement Type",
            "enumerations": [
                {
                    "label": "Daylight walkout",
                    "value": "400"
                },
                {
                    "label": "Blow the grade",
                    "value": "500"
                }
            ]
        },
        {
            "name": "BasementPercentComplete",
            "label": "Basement Percentage Finished",
            "enumerations": [
                {
                    "label": "0%",
                    "value": "0"
                },
                {
                    "label": "10%",
                    "value": "1000"
                },
                {
                    "label": "20%",
                    "value": "2000"
                },
                {
                    "label": "30%",
                    "value": "3000"
                },
                {
                    "label": "40%",
                    "value": "4000"
                },
                {
                    "label": "50%",
                    "value": "5000"
                },
                {
                    "label": "60%",
                    "value": "6000"
                },
                {
                    "label": "70%",
                    "value": "7000"
                },
                {
                    "label": "80%",
                    "value": "8000"
                },
                {
                    "label": "90%",
                    "value": "9000"
                },
                {
                    "label": "100%",
                    "value": "10000"
                }
            ]
        },
        {
            "name": "BCEquivalent",
            "label": "Building Code Equivalency",
            "enumerations": [
                {
                    "label": "Unknown",
                    "value": "0"
                },
                {
                    "label": "None",
                    "value": "200"
                },
                {
                    "label": "Roof Wall Connection Only",
                    "value": "501"
                },
                {
                    "label": "RoofCovering Only",
                    "value": "502"
                },
                {
                    "label": "Roof Deck Attachment Only",
                    "value": "503"
                },
                {
                    "label": "Roof Wall, Roof Cover",
                    "value": "504"
                },
                {
                    "label": "Roof Wall, Roof Deck",
                    "value": "505"
                },
                {
                    "label": "Roof Cover, Roof Deck",
                    "value": "506"
                },
                {
                    "label": "Roof Wall/Cover/Deck",
                    "value": "507"
                }
            ]
        },
        {
            "name": "BuildingNotOriginallyDwelling",
            "label": "Was the dwelling originally built for other than a private residence?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "BurglarAlarm",
            "label": "Burglar Alarm",
            "enumerations": [
                {
                    "label": "None",
                    "value": "1"
                },
                {
                    "label": "Local",
                    "value": "2"
                },
                {
                    "label": "Central",
                    "value": "4"
                }
            ]
        },
        {
            "name": "BusinessPropertyLimit",
            "label": "Increased Limits on Business Property",
            "enumerations": [
                {
                    "label": "$2,500 - Included",
                    "value": "2500"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                },
                {
                    "label": "$7,500",
                    "value": "7500"
                },
                {
                    "label": "$10,000",
                    "value": "10000"
                }
            ]
        },
        {
            "name": "CentralAir",
            "label": "Central Air Conditioning?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "CondemnedArea",
            "label": "Is the property in a condemned area or area scheduled to be condemned?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "ConstructionType",
            "label": "Construction Type",
            "enumerations": [
                {
                    "label": "Frame",
                    "value": "100"
                },
                {
                    "label": "Masonry veneer",
                    "value": "101"
                },
                {
                    "label": "Masonry",
                    "value": "200"
                }
            ]
        },
        {
            "name": "CoverageE",
            "label": "Coverage E",
            "enumerations": [
                {
                    "label": "$100,000",
                    "value": "100000"
                },
                {
                    "label": "$200,000",
                    "value": "200000"
                },
                {
                    "label": "$300,000",
                    "value": "300000"
                },
                {
                    "label": "$500,000",
                    "value": "500000"
                }
            ]
        },
        {
            "name": "CoverageF",
            "label": "Coverage F",
            "enumerations": [
                {
                    "label": "$1,000",
                    "value": "1000"
                },
                {
                    "label": "$2,000",
                    "value": "2000"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                }
            ]
        },
        {
            "name": "CurrencySpecialLimits",
            "label": "Money, Bank Notes, Coins",
            "enumerations": [
                {
                    "label": "$200 - Included",
                    "value": "200"
                },
                {
                    "label": "$300",
                    "value": "300"
                },
                {
                    "label": "$400",
                    "value": "400"
                },
                {
                    "label": "$500",
                    "value": "500"
                },
                {
                    "label": "$600",
                    "value": "600"
                },
                {
                    "label": "$700",
                    "value": "700"
                },
                {
                    "label": "$800",
                    "value": "800"
                },
                {
                    "label": "$900",
                    "value": "900"
                },
                {
                    "label": "$1,000",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "DistanceFireHydrant",
            "label": "Distance (In Feet) To Nearest Fire Hydrant",
            "enumerations": [
                {
                    "label": "Up to 1000",
                    "value": "1000"
                },
                {
                    "label": "Over 1000",
                    "value": "2000"
                }
            ]
        },
        {
            "name": "DistanceFireStation",
            "label": "Miles to Primary Responding Fire Station",
            "enumerations": [
                {
                    "label": "Up to 5",
                    "value": "5"
                },
                {
                    "label": "Over 5",
                    "value": "10"
                }
            ]
        },
        {
            "name": "DivingBoardSlide",
            "label": "Is there a Diving Board or Slide?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "Dogs",
            "label": "Do you own an ineligible dog breed?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "EarthquakeCoverage",
            "label": "Earthquake",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "EarthquakeDeductible",
            "label": "Earthquake Deductible %",
            "enumerations": [
                {
                    "label": "2%",
                    "value": "200"
                },
                {
                    "label": "5%",
                    "value": "500"
                },
                {
                    "label": "10%",
                    "value": "1000"
                },
                {
                    "label": "15%",
                    "value": "1500"
                },
                {
                    "label": "20%",
                    "value": "2000"
                },
                {
                    "label": "25%",
                    "value": "2500"
                }
            ]
        },
        {
            "name": "EarthquakeLossAssessmentCoverage",
            "label": "Earthquake Loss Assessment",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "EarthquakeMasonryVeneerExclusion",
            "label": "Exclude Masonry Veneer Coverage?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "EIFS",
            "label": "Is there any EIFS or DRYVIT construction?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "ElectricalAmperage",
            "label": "What is the amperage for your electrical system?",
            "enumerations": [
                {
                    "label": "60",
                    "value": "60"
                },
                {
                    "label": "75",
                    "value": "75"
                },
                {
                    "label": "80",
                    "value": "80"
                },
                {
                    "label": "100",
                    "value": "100"
                },
                {
                    "label": "120",
                    "value": "120"
                },
                {
                    "label": "125",
                    "value": "125"
                },
                {
                    "label": "150",
                    "value": "150"
                },
                {
                    "label": "175",
                    "value": "175"
                },
                {
                    "label": "200 and over",
                    "value": "201"
                }
            ]
        },
        {
            "name": "ElectronicsSpecialLimits",
            "label": "Electronic Apparatus",
            "enumerations": [
                {
                    "label": "$1,500 - Included",
                    "value": "1500"
                },
                {
                    "label": "$2,500",
                    "value": "2500"
                },
                {
                    "label": "$3,000",
                    "value": "3000"
                },
                {
                    "label": "$3,500",
                    "value": "3500"
                },
                {
                    "label": "$4,000",
                    "value": "4000"
                },
                {
                    "label": "$4,500",
                    "value": "4500"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                },
                {
                    "label": "$5,500",
                    "value": "$5,500"
                },
                {
                    "label": "$6,000",
                    "value": "$6,000"
                }
            ]
        },
        {
            "name": "ElectronicsSpecialLimitsLocation",
            "label": "Electronic Apparatus Location",
            "enumerations": [
                {
                    "label": "In a motor vehicle",
                    "value": "100"
                },
                {
                    "label": "Not in a motor vehicle",
                    "value": "200"
                }
            ]
        },
        {
            "name": "ExoticAnimal",
            "label": "Are there any exotic animals?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "Farming",
            "label": "Is there commercial farming/ranching on the premises?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "FireAlarm",
            "label": "Fire Alarm",
            "enumerations": [
                {
                    "label": "None",
                    "value": "1"
                },
                {
                    "label": "Local",
                    "value": "2"
                },
                {
                    "label": "Central",
                    "value": "4"
                }
            ]
        },
        {
            "name": "FirearmsSpecialLimits",
            "label": "Firearms For Loss Of Theft",
            "enumerations": [
                {
                    "label": "$2,500-Included",
                    "value": "2500"
                },
                {
                    "label": "$3,000",
                    "value": "3000"
                },
                {
                    "label": "$3,500",
                    "value": "3500"
                },
                {
                    "label": "$4,000",
                    "value": "4000"
                },
                {
                    "label": "$4,500",
                    "value": "4500"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                },
                {
                    "label": "$5,500",
                    "value": "5500"
                },
                {
                    "label": "$6,000",
                    "value": "6000"
                },
                {
                    "label": "$6,500",
                    "value": "6500"
                }
            ]
        },
        {
            "name": "FloodZone",
            "label": "Flood Zone",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "Foreclosure",
            "label": "Is the property in foreclosure?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "FoundationBasementPercentage",
            "label": "% Basement Percentage",
            "enumerations": [
                {
                    "label": "10%",
                    "value": "1000"
                },
                {
                    "label": "20%",
                    "value": "2000"
                },
                {
                    "label": "30%",
                    "value": "3000"
                },
                {
                    "label": "40%",
                    "value": "4000"
                },
                {
                    "label": "50%",
                    "value": "5000"
                },
                {
                    "label": "60%",
                    "value": "6000"
                },
                {
                    "label": "70%",
                    "value": "7000"
                },
                {
                    "label": "80%",
                    "value": "8000"
                },
                {
                    "label": "90%",
                    "value": "9000"
                }
            ]
        },
        {
            "name": "FoundationType",
            "label": "Foundation Type",
            "enumerations": [
                {
                    "label": "Slab",
                    "value": "100"
                },
                {
                    "label": "Slab / Basement",
                    "value": "150"
                },
                {
                    "label": "Basement",
                    "value": "300"
                },
                {
                    "label": "Open - pilings/stilts/piers",
                    "value": "400"
                },
                {
                    "label": "Open - craw space",
                    "value": "200"
                },
                {
                    "label": "Enclosed - crawl space",
                    "value": "205"
                }
            ]
        },
        {
            "name": "FullBathQuality",
            "label": "Full Bathroom Grade",
            "enumerations": [
                {
                    "label": "Basic",
                    "value": "0"
                },
                {
                    "label": "Builder's grade",
                    "value": "100"
                },
                {
                    "label": "Semi-custom",
                    "value": "200"
                },
                {
                    "label": "Custom",
                    "value": "300"
                },
                {
                    "label": "Designer",
                    "value": "400"
                }
            ]
        },
        {
            "name": "FunctionalReplacementCost",
            "label": "Functional Replacement Cost For Dwelling",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "GarageType",
            "label": "Type Of Garage Or Carport",
            "enumerations": [
                {
                    "label": "No Garage or Carport",
                    "value": "1"
                },
                {
                    "label": "Built-in - 1 Car",
                    "value": "20510"
                },
                {
                    "label": "Built-in - 2 Car",
                    "value": "20520"
                },
                {
                    "label": "Built-in - 3 Car",
                    "value": "20530"
                },
                {
                    "label": "Attached - 1 Car",
                    "value": "20110"
                },
                {
                    "label": "Attached - 2 Car",
                    "value": "20120"
                },
                {
                    "label": "Attached - 3 Car",
                    "value": "20130"
                },
                {
                    "label": "Detached - 1 Car",
                    "value": "20710"
                },
                {
                    "label": "Detached - 2 Car",
                    "value": "20720"
                },
                {
                    "label": "Detached - 3 Car",
                    "value": "20730"
                },
                {
                    "label": "Basement - 1 Car",
                    "value": "20310"
                },
                {
                    "label": "Basement - 2 Car",
                    "value": "20320"
                },
                {
                    "label": "Basement - 3 Car",
                    "value": "20330"
                },
                {
                    "label": "Carport - 1 Car",
                    "value": "20110"
                },
                {
                    "label": "Carport - 2 Car",
                    "value": "20120"
                },
                {
                    "label": "Carport - 3 Car",
                    "value": "20130"
                }
            ]
        },
        {
            "name": "GatedCommunity",
            "label": "Is risk in a gated community?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "GatedCommunityPhoneNumber",
            "label": "Contact # if Gated",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "GatedCommunityRentalAgent",
            "label": "Is property managed by a rental agent?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "GoldSpecialLimits",
            "label": "Gold, Silver, Pewter For Loss Of Theft",
            "enumerations": [
                {
                    "label": "$2,500 - Included",
                    "value": "2500"
                },
                {
                    "label": "$3,500",
                    "value": "3500"
                },
                {
                    "label": "$4,500",
                    "value": "4500"
                },
                {
                    "label": "$5,500",
                    "value": "5500"
                },
                {
                    "label": "$6,500",
                    "value": "6500"
                },
                {
                    "label": "$7,500",
                    "value": "7500"
                },
                {
                    "label": "$8,500",
                    "value": "8500"
                },
                {
                    "label": "$9,500",
                    "value": "9500"
                },
                {
                    "label": "$10,000",
                    "value": "10000"
                }
            ]
        },
        {
            "name": "HalfBathQuality",
            "label": "Half Bathroom Grade",
            "enumerations": [
                {
                    "label": "Basic",
                    "value": "0"
                },
                {
                    "label": "Builder's grade",
                    "value": "100"
                },
                {
                    "label": "Semi-custom",
                    "value": "200"
                },
                {
                    "label": "Custom",
                    "value": "300"
                },
                {
                    "label": "Designer",
                    "value": "400"
                }
            ]
        },
        {
            "name": "HandrailWalkwayLiability",
            "label": "Handrail Walkway Liability",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "HeatingThermoControlled",
            "label": "Is the heating system centrally and thermostatically controlled?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "HomeFeatures1",
            "label": "1st Additional Home Feature",
            "enumerations": [
                {
                    "label": "None",
                    "value": "0"
                },
                {
                    "label": "Open porch, small",
                    "value": "110"
                },
                {
                    "label": "Open porch, medium",
                    "value": "120"
                },
                {
                    "label": "Open porch, large",
                    "value": "130"
                },
                {
                    "label": "Screened porch, small",
                    "value": "210"
                },
                {
                    "label": "Screened porch, medium",
                    "value": "220"
                },
                {
                    "label": "Screened porch, large",
                    "value": "230"
                },
                {
                    "label": "Deck, small",
                    "value": "710"
                },
                {
                    "label": "Deck, medium",
                    "value": "720"
                },
                {
                    "label": "Deck, large",
                    "value": "730"
                },
                {
                    "label": "Open breezeway",
                    "value": "300"
                },
                {
                    "label": "Screened breezeway",
                    "value": "400"
                }
            ]
        },
        {
            "name": "HomeFeatures2",
            "label": "2nd Additional Home Feature",
            "enumerations": [
                {
                    "label": "None",
                    "value": "0"
                },
                {
                    "label": "Open porch, small",
                    "value": "110"
                },
                {
                    "label": "Open porch, medium",
                    "value": "120"
                },
                {
                    "label": "Open porch, large",
                    "value": "130"
                },
                {
                    "label": "Screened porch, small",
                    "value": "210"
                },
                {
                    "label": "Screened porch, medium",
                    "value": "220"
                },
                {
                    "label": "Screened porch, large",
                    "value": "230"
                },
                {
                    "label": "Deck, small",
                    "value": "710"
                },
                {
                    "label": "Deck, medium",
                    "value": "720"
                },
                {
                    "label": "Deck, large",
                    "value": "730"
                },
                {
                    "label": "Open breezeway",
                    "value": "300"
                },
                {
                    "label": "Screened breezeway",
                    "value": "400"
                }
            ]
        },
        {
            "name": "HomeFeatures3",
            "label": "3rd Additional Home Feature",
            "enumerations": [
                {
                    "label": "None",
                    "value": "0"
                },
                {
                    "label": "Open porch, small",
                    "value": "110"
                },
                {
                    "label": "Open porch, medium",
                    "value": "120"
                },
                {
                    "label": "Open porch, large",
                    "value": "130"
                },
                {
                    "label": "Screened porch, small",
                    "value": "210"
                },
                {
                    "label": "Screened porch, medium",
                    "value": "220"
                },
                {
                    "label": "Screened porch, large",
                    "value": "230"
                },
                {
                    "label": "Deck, small",
                    "value": "710"
                },
                {
                    "label": "Deck, medium",
                    "value": "720"
                },
                {
                    "label": "Deck, large",
                    "value": "730"
                },
                {
                    "label": "Open breezeway",
                    "value": "300"
                },
                {
                    "label": "Screened breezeway",
                    "value": "400"
                }
            ]
        },
        {
            "name": "HomeStyle",
            "label": "Home Style",
            "enumerations": [
                {
                    "label": "BiLevel/split",
                    "value": "100"
                },
                {
                    "label": "Trilevel",
                    "value": "101"
                },
                {
                    "label": "Bungalow",
                    "value": "200"
                },
                {
                    "label": "Cape Cod",
                    "value": "300"
                },
                {
                    "label": "Colonial",
                    "value": "400"
                },
                {
                    "label": "Ranch",
                    "value": "500"
                },
                {
                    "label": "Raised ranch",
                    "value": "501"
                },
                {
                    "label": "Victorian",
                    "value": "700"
                },
                {
                    "label": "Townhouse - End Unit",
                    "value": "601"
                },
                {
                    "label": "Townhouse - Interior Unit",
                    "value": "602"
                }
            ]
        },
        {
            "name": "HurricaneDeductible",
            "label": "Named Storm Deductible",
            "enumerations": [
                {
                    "label": "N/A",
                    "value": "0"
                },
                {
                    "label": "1%",
                    "value": "100"
                },
                {
                    "label": "2%",
                    "value": "200"
                },
                {
                    "label": "3%",
                    "value": "300"
                },
                {
                    "label": "4%",
                    "value": "400"
                },
                {
                    "label": "5%",
                    "value": "500"
                }
            ]
        },
        {
            "name": "IdentityFraudCoverage",
            "label": "Identity Theft Expense",
            "enumerations": [
                {
                    "label": "$0 - Excluded",
                    "value": "0"
                },
                {
                    "label": "$25,000",
                    "value": "25000"
                }
            ]
        },
        {
            "name": "ImmovablePoolLadder",
            "label": "Is There An Immovable Ladder Present?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "IncidentalBusinessOccupancy",
            "label": "Permitted Incidental Occupancies – Residence Premises ",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "IncreasedOrdinanceLimit",
            "label": "Ordinance Or Law",
            "enumerations": [
                {
                    "label": "10% - Included",
                    "value": "1000"
                },
                {
                    "label": "25%",
                    "value": "2500"
                }
            ]
        },
        {
            "name": "InsuranceFraud",
            "label": "Any household member ever convicted of a serious crime?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "InsuredMailingAddressState",
            "label": "Insured Mailing Address State",
            "enumerations": [
                {
                    "label": "AK",
                    "value": "AK"
                },
                {
                    "label": "AL",
                    "value": "AL"
                },
                {
                    "label": "AR",
                    "value": "AR"
                },
                {
                    "label": "AZ",
                    "value": "AZ"
                },
                {
                    "label": "CA",
                    "value": "CA"
                },
                {
                    "label": "CO",
                    "value": "CO"
                },
                {
                    "label": "CT",
                    "value": "CT"
                },
                {
                    "label": "DC",
                    "value": "DC"
                },
                {
                    "label": "DE",
                    "value": "DE"
                },
                {
                    "label": "FL",
                    "value": "FL"
                },
                {
                    "label": "GA",
                    "value": "GA"
                },
                {
                    "label": "HI",
                    "value": "HI"
                },
                {
                    "label": "IA",
                    "value": "IA"
                },
                {
                    "label": "ID",
                    "value": "ID"
                },
                {
                    "label": "IL",
                    "value": "IL"
                },
                {
                    "label": "IN",
                    "value": "IN"
                },
                {
                    "label": "KS",
                    "value": "KS"
                },
                {
                    "label": "KY",
                    "value": "KY"
                },
                {
                    "label": "LA",
                    "value": "LA"
                },
                {
                    "label": "MA",
                    "value": "MA"
                },
                {
                    "label": "MD",
                    "value": "MD"
                },
                {
                    "label": "ME",
                    "value": "ME"
                },
                {
                    "label": "MI",
                    "value": "MI"
                },
                {
                    "label": "MN",
                    "value": "MN"
                },
                {
                    "label": "MO",
                    "value": "MO"
                },
                {
                    "label": "MS",
                    "value": "MS"
                },
                {
                    "label": "MT",
                    "value": "MT"
                },
                {
                    "label": "NC",
                    "value": "NC"
                },
                {
                    "label": "ND",
                    "value": "ND"
                },
                {
                    "label": "NE",
                    "value": "NE"
                },
                {
                    "label": "NH",
                    "value": "NH"
                },
                {
                    "label": "NJ",
                    "value": "NJ"
                },
                {
                    "label": "NM",
                    "value": "NM"
                },
                {
                    "label": "NV",
                    "value": "NV"
                },
                {
                    "label": "NY",
                    "value": "NY"
                },
                {
                    "label": "OH",
                    "value": "OH"
                },
                {
                    "label": "OK",
                    "value": "OK"
                },
                {
                    "label": "OR",
                    "value": "OR"
                },
                {
                    "label": "PA",
                    "value": "PA"
                },
                {
                    "label": "RI",
                    "value": "RI"
                },
                {
                    "label": "SC",
                    "value": "SC"
                },
                {
                    "label": "SD",
                    "value": "SD"
                },
                {
                    "label": "TN",
                    "value": "TN"
                },
                {
                    "label": "TX",
                    "value": "TX"
                },
                {
                    "label": "UT",
                    "value": "UT"
                },
                {
                    "label": "VA",
                    "value": "VA"
                },
                {
                    "label": "VT",
                    "value": "VT"
                },
                {
                    "label": "WA",
                    "value": "WA"
                },
                {
                    "label": "WI",
                    "value": "WI"
                },
                {
                    "label": "WV",
                    "value": "WV"
                },
                {
                    "label": "WY",
                    "value": "WY"
                }
            ]
        },
        {
            "name": "JewelrySpecialLimits",
            "label": "Jewelry, Watches, And Furs For Loss Of Theft",
            "enumerations": [
                {
                    "label": "$1,500 - Included",
                    "value": "1500"
                },
                {
                    "label": "$2,500",
                    "value": "2500"
                },
                {
                    "label": "$3,000",
                    "value": "3000"
                },
                {
                    "label": "$3,500",
                    "value": "3500"
                },
                {
                    "label": "$4,000",
                    "value": "4000"
                },
                {
                    "label": "$4,500",
                    "value": "4500"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                },
                {
                    "label": "$5,500",
                    "value": "5500"
                },
                {
                    "label": "$6,000",
                    "value": "6000"
                },
                {
                    "label": "$6,500",
                    "value": "6500"
                }
            ]
        },
        {
            "name": "KeroseneHeater",
            "label": "Is there a kerosene or electric space heater?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "KeroseneHeaterAge",
            "label": "Age of the heater",
            "enumerations": [
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                },
                {
                    "label": "5",
                    "value": "5"
                },
                {
                    "label": "6",
                    "value": "6"
                },
                {
                    "label": "7",
                    "value": "7"
                },
                {
                    "label": "8",
                    "value": "8"
                },
                {
                    "label": "9",
                    "value": "9"
                },
                {
                    "label": "10",
                    "value": "10"
                },
                {
                    "label": "11",
                    "value": "11"
                },
                {
                    "label": "12",
                    "value": "12"
                },
                {
                    "label": "13",
                    "value": "13"
                },
                {
                    "label": "14",
                    "value": "14"
                },
                {
                    "label": "15 or more",
                    "value": "15"
                }
            ]
        },
        {
            "name": "KeroseneHeaterSupplementalHeatOnly",
            "label": "Supplemental heat source only?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "KitchenQuality",
            "label": "Kitchen Grade",
            "enumerations": [
                {
                    "label": "Basic",
                    "value": "0"
                },
                {
                    "label": "Builder's grade",
                    "value": "100"
                },
                {
                    "label": "Semi-custom",
                    "value": "200"
                },
                {
                    "label": "Custom",
                    "value": "300"
                },
                {
                    "label": "Designer",
                    "value": "400"
                }
            ]
        },
        {
            "name": "LogCabin",
            "label": "Is the dwelling a log, earth, do it yourself or underground construction?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "LossAssessmentCoverage",
            "label": "Loss Assessment",
            "enumerations": [
                {
                    "label": "$1,000 - Excluded",
                    "value": "1000"
                },
                {
                    "label": "$2,000",
                    "value": "2000"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                },
                {
                    "label": "$10,000",
                    "value": "10000"
                }
            ]
        },
        {
            "name": "LossCatIndicator1",
            "label": "Cat Indicator",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "LossCatIndicator2",
            "label": "Cat Indicator",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "LossCatIndicator3",
            "label": "Cat Indicator",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "LossCatIndicator4",
            "label": "Cat Indicator",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "LossCatIndicator5",
            "label": "Cat Indicator",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "LossType1",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Dog bite",
                    "value": "601"
                },
                {
                    "label": "Earthquake",
                    "value": "800"
                },
                {
                    "label": "Fire / smoke",
                    "value": "100"
                },
                {
                    "label": "Flooding",
                    "value": "201"
                },
                {
                    "label": "Inland marine",
                    "value": "410"
                },
                {
                    "label": "Liability or medical payment",
                    "value": "600"
                },
                {
                    "label": "Lightning",
                    "value": "300"
                },
                {
                    "label": "Plumbing - Leaky or bursting pipes fixtures",
                    "value": "210"
                },
                {
                    "label": "Sump pump or water backup",
                    "value": "220"
                },
                {
                    "label": "Theft / mysterious disappearence - off premises",
                    "value": "402"
                },
                {
                    "label": "Theft / mysterious disappearence - on premises",
                    "value": "401"
                },
                {
                    "label": "Theft / mysterious disappearence",
                    "value": "400"
                },
                {
                    "label": "Watercraft",
                    "value": "900"
                },
                {
                    "label": "Water damage (no plumbing)",
                    "value": "200"
                },
                {
                    "label": "Windstorm or hail",
                    "value": "500"
                },
                {
                    "label": "Other",
                    "value": "700"
                }
            ]
        },
        {
            "name": "LossType2",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Dog bite",
                    "value": "601"
                },
                {
                    "label": "Earthquake",
                    "value": "800"
                },
                {
                    "label": "Fire / smoke",
                    "value": "100"
                },
                {
                    "label": "Flooding",
                    "value": "201"
                },
                {
                    "label": "Inland marine",
                    "value": "410"
                },
                {
                    "label": "Liability or medical payment",
                    "value": "600"
                },
                {
                    "label": "Lightning",
                    "value": "300"
                },
                {
                    "label": "Plumbing - Leaky or bursting pipes fixtures",
                    "value": "210"
                },
                {
                    "label": "Sump pump or water backup",
                    "value": "220"
                },
                {
                    "label": "Theft / mysterious disappearance - off premises",
                    "value": "402"
                },
                {
                    "label": "Theft / mysterious disappearence - on premises",
                    "value": "401"
                },
                {
                    "label": "Theft / mysterious disappearence",
                    "value": "400"
                },
                {
                    "label": "Watercraft",
                    "value": "900"
                },
                {
                    "label": "Water damage (no plumbing)",
                    "value": "200"
                },
                {
                    "label": "Windstorm or hail",
                    "value": "500"
                },
                {
                    "label": "Other",
                    "value": "700"
                }
            ]
        },
        {
            "name": "LossType3",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Dog bite",
                    "value": "601"
                },
                {
                    "label": "Earthquake",
                    "value": "800"
                },
                {
                    "label": "Fire / smoke",
                    "value": "100"
                },
                {
                    "label": "Flooding",
                    "value": "201"
                },
                {
                    "label": "Inland marine",
                    "value": "410"
                },
                {
                    "label": "Liability or medical payment",
                    "value": "600"
                },
                {
                    "label": "Lightning",
                    "value": "300"
                },
                {
                    "label": "Plumbing - Leaky or bursting pipes fixtures",
                    "value": "210"
                },
                {
                    "label": "Sump pump or water backup",
                    "value": "220"
                },
                {
                    "label": "Theft / mysterious disappearance - off premises",
                    "value": "402"
                },
                {
                    "label": "Theft / mysterious disappearence - on premises",
                    "value": "401"
                },
                {
                    "label": "Theft / mysterious disappearence",
                    "value": "400"
                },
                {
                    "label": "Watercraft",
                    "value": "900"
                },
                {
                    "label": "Water damage (no plumbing)",
                    "value": "200"
                },
                {
                    "label": "Windstorm or hail",
                    "value": "500"
                },
                {
                    "label": "Other",
                    "value": "700"
                }
            ]
        },
        {
            "name": "LossType4",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Dog bite",
                    "value": "601"
                },
                {
                    "label": "Earthquake",
                    "value": "800"
                },
                {
                    "label": "Fire / smoke",
                    "value": "100"
                },
                {
                    "label": "Flooding",
                    "value": "201"
                },
                {
                    "label": "Inland marine",
                    "value": "410"
                },
                {
                    "label": "Liability or medical payment",
                    "value": "600"
                },
                {
                    "label": "Lightning",
                    "value": "300"
                },
                {
                    "label": "Plumbing - Leaky or bursting pipes fixtures",
                    "value": "210"
                },
                {
                    "label": "Sump pump or water backup",
                    "value": "220"
                },
                {
                    "label": "Theft / mysterious disappearance - off premises",
                    "value": "402"
                },
                {
                    "label": "Theft / mysterious disappearence - on premises",
                    "value": "401"
                },
                {
                    "label": "Theft / mysterious disappearence",
                    "value": "400"
                },
                {
                    "label": "Watercraft",
                    "value": "900"
                },
                {
                    "label": "Water damage (no plumbing)",
                    "value": "200"
                },
                {
                    "label": "Windstorm or hail",
                    "value": "500"
                },
                {
                    "label": "Other",
                    "value": "700"
                }
            ]
        },
        {
            "name": "LossType5",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Dog bite",
                    "value": "601"
                },
                {
                    "label": "Earthquake",
                    "value": "800"
                },
                {
                    "label": "Fire / smoke",
                    "value": "100"
                },
                {
                    "label": "Flooding",
                    "value": "201"
                },
                {
                    "label": "Inland marine",
                    "value": "410"
                },
                {
                    "label": "Liability or medical payment",
                    "value": "600"
                },
                {
                    "label": "Lightning",
                    "value": "300"
                },
                {
                    "label": "Plumbing - Leaky or bursting pipes fixtures",
                    "value": "210"
                },
                {
                    "label": "Sump pump or water backup",
                    "value": "220"
                },
                {
                    "label": "Theft / mysterious disappearance - off premises",
                    "value": "402"
                },
                {
                    "label": "Theft / mysterious disappearence - on premises",
                    "value": "401"
                },
                {
                    "label": "Theft / mysterious disappearence",
                    "value": "400"
                },
                {
                    "label": "Watercraft",
                    "value": "900"
                },
                {
                    "label": "Water damage (no plumbing)",
                    "value": "200"
                },
                {
                    "label": "Windstorm or hail",
                    "value": "500"
                },
                {
                    "label": "Other",
                    "value": "700"
                }
            ]
        },
        {
            "name": "MailingEqualPropertyAddress",
            "label": "Is mailing address same as property address? ",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "MasonryVeneerPercentage",
            "label": "Masonry Veneer %",
            "enumerations": [
                {
                    "label": "0 - 9%",
                    "value": "0"
                },
                {
                    "label": "10 - 33%",
                    "value": "1000"
                },
                {
                    "label": "34 - 66%",
                    "value": "3400"
                },
                {
                    "label": "67% or Greater",
                    "value": "6700"
                }
            ]
        },
        {
            "name": "MonthlyPropertyCheck",
            "label": "Is property checked by owner and/or rental management company at least monthly?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "MonthsRented",
            "label": "Number Of Months Rented?",
            "enumerations": [
                {
                    "label": "Not a Rental",
                    "value": "0"
                },
                {
                    "label": "2 weeks up to 5 months",
                    "value": "0.5"
                },
                {
                    "label": "6 months or more",
                    "value": "6"
                }
            ]
        },
        {
            "name": "MonthsUnoccupied",
            "label": "Number Of Months Unoccupied?",
            "enumerations": [
                {
                    "label": "Less than a 3 months",
                    "value": "0"
                },
                {
                    "label": "3 months or more",
                    "value": "3"
                }
            ]
        },
        {
            "name": "MultiLayeredRoofing",
            "label": "More than two layers of shingles or roof materials?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "MultipleOtherStructures",
            "label": "Are there 3 or more other structures on the property?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "MultiPolicy",
            "label": "Mult-Policy Discount",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "NumberFamilies",
            "label": "Number of families",
            "enumerations": [
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                }
            ]
        },
        {
            "name": "NumberOfClaims",
            "label": "Number Of Claims In Last 6 Years",
            "enumerations": [
                {
                    "label": "None",
                    "value": "0"
                },
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                },
                {
                    "label": "5",
                    "value": "5"
                }
            ]
        },
        {
            "name": "NumberOfFireplaces",
            "label": "Number Of Fireplaces",
            "enumerations": [
                {
                    "label": "0",
                    "value": "0"
                },
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                }
            ]
        },
        {
            "name": "NumberOfFullBaths",
            "label": "Number Of Full Bathrooms",
            "enumerations": [
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                },
                {
                    "label": "5",
                    "value": "5"
                }
            ]
        },
        {
            "name": "NumberOfHalfBaths",
            "label": "Number Of Half Bathrooms",
            "enumerations": [
                {
                    "label": "0",
                    "value": "0"
                },
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                },
                {
                    "label": "5",
                    "value": "5"
                }
            ]
        },
        {
            "name": "NumberOfKitchens",
            "label": "Number Of Kitchens",
            "enumerations": [
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                }
            ]
        },
        {
            "name": "NumberOfStories",
            "label": "Number Of Stories",
            "enumerations": [
                {
                    "label": "1",
                    "value": "100"
                },
                {
                    "label": "1 1/2",
                    "value": "150"
                },
                {
                    "label": "2",
                    "value": "200"
                },
                {
                    "label": "2.5",
                    "value": "250"
                },
                {
                    "label": "3",
                    "value": "300"
                },
                {
                    "label": "4",
                    "value": "400"
                },
                {
                    "label": "5",
                    "value": "500"
                },
                {
                    "label": "6",
                    "value": "600"
                },
                {
                    "label": "7",
                    "value": "700"
                },
                {
                    "label": "8 to 14",
                    "value": "800"
                },
                {
                    "label": "15 or more",
                    "value": "1500"
                }
            ]
        },
        {
            "name": "OpeningProtectionType",
            "label": "Opening Protection",
            "enumerations": [
                {
                    "label": "Unknown",
                    "value": "0"
                },
                {
                    "label": "No shutters",
                    "value": "1"
                },
                {
                    "label": "Engineered shutters",
                    "value": "211"
                },
                {
                    "label": "Hurricane resistant laminated glass",
                    "value": "702"
                }
            ]
        },
        {
            "name": "OpPendingApplication",
            "label": "Application due?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "OptionCoverageB",
            "label": "Coverage B (% Of Coverage A)",
            "enumerations": [
                {
                    "label": "0%",
                    "value": "0"
                },
                {
                    "label": "1%",
                    "value": "100"
                },
                {
                    "label": "2%",
                    "value": "200"
                },
                {
                    "label": "3%",
                    "value": "300"
                },
                {
                    "label": "4%",
                    "value": "400"
                },
                {
                    "label": "5%",
                    "value": "500"
                },
                {
                    "label": "6%",
                    "value": "600"
                },
                {
                    "label": "7%",
                    "value": "700"
                },
                {
                    "label": "8%",
                    "value": "800"
                },
                {
                    "label": "9%",
                    "value": "900"
                },
                {
                    "label": "10%",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "OptionCoverageC",
            "label": "Coverage C (% Of Coverage A)",
            "enumerations": [
                {
                    "label": "25%",
                    "value": "2500"
                },
                {
                    "label": "30%",
                    "value": "3000"
                },
                {
                    "label": "35%",
                    "value": "3500"
                },
                {
                    "label": "40%",
                    "value": "4000"
                },
                {
                    "label": "45%",
                    "value": "4500"
                },
                {
                    "label": "50%",
                    "value": "5000"
                },
                {
                    "label": "55%",
                    "value": "5500"
                },
                {
                    "label": "60%",
                    "value": "6000"
                },
                {
                    "label": "65%",
                    "value": "6500"
                },
                {
                    "label": "70%",
                    "value": "7000"
                },
                {
                    "label": "75%",
                    "value": "7500"
                },
                {
                    "label": "80%",
                    "value": "8000"
                },
                {
                    "label": "85%",
                    "value": "8500"
                },
                {
                    "label": "90%",
                    "value": "9000"
                },
                {
                    "label": "95%",
                    "value": "9500"
                },
                {
                    "label": "100%",
                    "value": "10000"
                }
            ]
        },
        {
            "name": "OptionCoverageD",
            "label": "Coverage D (% of Coverage A)",
            "enumerations": [
                {
                    "label": "30%",
                    "value": "3000"
                }
            ]
        },
        {
            "name": "OtherStructures1Occupancy",
            "label": "1st Scheduled Structure - Occupancy",
            "enumerations": [
                {
                    "label": "Personal Use",
                    "value": "200"
                },
                {
                    "label": "Rented to Others - 1 Family",
                    "value": "301"
                },
                {
                    "label": "Rented to Others - 2 Families",
                    "value": "302"
                },
                {
                    "label": "Business Occupany",
                    "value": "400"
                }
            ]
        },
        {
            "name": "OtherStructures1Type",
            "label": "1st Scheduled Structure - Type",
            "enumerations": [
                {
                    "label": "Work Shop / Studio",
                    "value": "100"
                },
                {
                    "label": "Barn / Shed / Kennel",
                    "value": "200"
                },
                {
                    "label": "Guest House",
                    "value": "300"
                },
                {
                    "label": "Home Office",
                    "value": "400"
                },
                {
                    "label": "Garage",
                    "value": "500"
                },
                {
                    "label": "Garage with Apartment",
                    "value": "600"
                },
                {
                    "label": "Wall / Fence / Fountain",
                    "value": "700"
                },
                {
                    "label": "Pool / pool enclosure",
                    "value": "800"
                },
                {
                    "label": "Pool House / Cabana",
                    "value": "900"
                },
                {
                    "label": "Dock / davits",
                    "value": "1000"
                },
                {
                    "label": "Other",
                    "value": "1100"
                }
            ]
        },
        {
            "name": "OtherStructures2Occupancy",
            "label": "2nd Scheduled Structure - Occupancy",
            "enumerations": [
                {
                    "label": "Personal Use",
                    "value": "200"
                },
                {
                    "label": "Rented to Others - 1 Family",
                    "value": "301"
                },
                {
                    "label": "Rented to Others - 2 Families",
                    "value": "302"
                },
                {
                    "label": "Business Occupany",
                    "value": "400"
                }
            ]
        },
        {
            "name": "OtherStructures2Type",
            "label": "2nd Scheduled Structure - Type",
            "enumerations": [
                {
                    "label": "Work Shop / Studio",
                    "value": "200"
                },
                {
                    "label": "Barn / Shed / Kennel",
                    "value": "200"
                },
                {
                    "label": "Guest House",
                    "value": "300"
                },
                {
                    "label": "Home Office",
                    "value": "400"
                },
                {
                    "label": "Garage",
                    "value": "500"
                },
                {
                    "label": "Garage with Apartment",
                    "value": "600"
                },
                {
                    "label": "Wall / Fence / Fountain",
                    "value": "700"
                },
                {
                    "label": "Pool / pool enclosure",
                    "value": "800"
                },
                {
                    "label": "Pool House / Cabana",
                    "value": "900"
                },
                {
                    "label": "Dock / davits",
                    "value": "2000"
                },
                {
                    "label": "Other",
                    "value": "2200"
                }
            ]
        },
        {
            "name": "OtherStructures3Occupancy",
            "label": "3rd Scheduled Structure - Occupancy",
            "enumerations": [
                {
                    "label": "Personal Use",
                    "value": "200"
                },
                {
                    "label": "Rented to Others - 1 Family",
                    "value": "301"
                },
                {
                    "label": "Rented to Others - 2 Families",
                    "value": "302"
                },
                {
                    "label": "Business Occupany",
                    "value": "400"
                }
            ]
        },
        {
            "name": "OtherStructures3Type",
            "label": "3rd Scheduled Structure - Type",
            "enumerations": [
                {
                    "label": "Work Shop / Studio",
                    "value": "300"
                },
                {
                    "label": "Barn / Shed / Kennel",
                    "value": "200"
                },
                {
                    "label": "Guest House",
                    "value": "300"
                },
                {
                    "label": "Home Office",
                    "value": "400"
                },
                {
                    "label": "Garage",
                    "value": "500"
                },
                {
                    "label": "Garage with Apartment",
                    "value": "600"
                },
                {
                    "label": "Wall / Fence / Fountain",
                    "value": "700"
                },
                {
                    "label": "Pool / pool enclosure",
                    "value": "800"
                },
                {
                    "label": "Pool House / Cabana",
                    "value": "900"
                },
                {
                    "label": "Dock / davits",
                    "value": "3000"
                },
                {
                    "label": "Other",
                    "value": "3300"
                }
            ]
        },
        {
            "name": "OutdatedElectricalMaterials",
            "label": "Any knob and tube, aluminum wiring or any fuses?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PersonalInjuryCoverage",
            "label": "Personal Injury",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "Pets",
            "label": "Do you have any animals or pets?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PoolFence",
            "label": "Is The Property Around Pool Fenced Or Screened?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PoolType",
            "label": "Swimming Pool On Property?",
            "enumerations": [
                {
                    "label": "No pool",
                    "value": "1"
                },
                {
                    "label": "In ground",
                    "value": "100"
                },
                {
                    "label": "Above ground",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PreviousDamage",
            "label": "Is there pre-existing damage to the dwelling?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PreviousDamageRoof",
            "label": "Is there pre-existing damage to the roof, shingles or accumulated debris?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PrimeTimeDiscount",
            "label": "Prime time credit",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PropertyForSale",
            "label": "Is the property vacant, unoccupied, for sale, or under construction?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PropertyHazardLocation",
            "label": "Property Hazard Location",
            "enumerations": [
                {
                    "label": "Extreme",
                    "value": "Extreme"
                },
                {
                    "label": "High",
                    "value": "High"
                },
                {
                    "label": "Moderate",
                    "value": "Moderate"
                },
                {
                    "label": "Low",
                    "value": "Low"
                }
            ]
        },
        {
            "name": "PropertyOccupancy",
            "label": "Property Occupancy",
            "enumerations": [
                {
                    "label": "Owner",
                    "value": "100"
                },
                {
                    "label": "Tenant",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PropertyOver5Acres",
            "label": "Is the property on more than 5 acres?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "PropertyUsage",
            "label": "Property Usage",
            "enumerations": [
                {
                    "label": "Primary",
                    "value": "100"
                },
                {
                    "label": "Secondary",
                    "value": "200"
                },
                {
                    "label": "Seasonal",
                    "value": "300"
                }
            ]
        },
        {
            "name": "ProtectionClass",
            "label": "Protection Class",
            "enumerations": [
                {
                    "label": "1",
                    "value": "1"
                },
                {
                    "label": "2",
                    "value": "2"
                },
                {
                    "label": "3",
                    "value": "3"
                },
                {
                    "label": "4",
                    "value": "4"
                },
                {
                    "label": "5",
                    "value": "5"
                },
                {
                    "label": "6",
                    "value": "6"
                },
                {
                    "label": "7",
                    "value": "7"
                },
                {
                    "label": "8",
                    "value": "8"
                },
                {
                    "label": "8B",
                    "value": "8.1"
                },
                {
                    "label": "9",
                    "value": "9"
                },
                {
                    "label": "10",
                    "value": "10"
                }
            ]
        },
        {
            "name": "ResidenceHeldInTrust",
            "label": "Residence Held in Trust",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "ResortIsland",
            "label": "Resort Island",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "RoofCoveringType",
            "label": "Roof Covering Material",
            "enumerations": [
                {
                    "label": "Unknown",
                    "value": "0"
                },
                {
                    "label": "Asphalt/Composite Shingles",
                    "value": "500"
                },
                {
                    "label": "Rated Shingles",
                    "value": "502"
                },
                {
                    "label": "Concrete/Clay Tiles",
                    "value": "600"
                },
                {
                    "label": "Built Up Roof",
                    "value": "400"
                },
                {
                    "label": "Reinforced Concrete",
                    "value": "100"
                },
                {
                    "label": "Rubber/Bituminous",
                    "value": "800"
                },
                {
                    "label": "Single Ply Membrane",
                    "value": "300"
                },
                {
                    "label": "Wood Shingles",
                    "value": "700"
                },
                {
                    "label": "Wood Shake",
                    "value": "701"
                },
                {
                    "label": "Metal - Other Than Steel",
                    "value": "250"
                },
                {
                    "label": "Metal - Steel",
                    "value": "200"
                }
            ]
        },
        {
            "name": "RoofGeometryType",
            "label": "Roof Geometry Type",
            "enumerations": [
                {
                    "label": "Unknown",
                    "value": "0"
                },
                {
                    "label": "Flat",
                    "value": "100"
                },
                {
                    "label": "Gable",
                    "value": "200"
                },
                {
                    "label": "Hip",
                    "value": "300"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty10LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty10Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty1LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty1Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty2LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty2Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty3LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty3Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty4LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty4Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty5LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty5Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty6LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty6Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty7LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty7Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty8LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty8Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty9LossSettlement",
            "label": "Loss Settlement",
            "enumerations": [
                {
                    "label": "Standard",
                    "value": "100"
                }
            ]
        },
        {
            "name": "ScheduledPersonalProperty9Type",
            "label": "Type",
            "enumerations": [
                {
                    "label": "Cameras",
                    "value": "100"
                },
                {
                    "label": "Coins",
                    "value": "200"
                },
                {
                    "label": "Fine arts",
                    "value": "300"
                },
                {
                    "label": "Furs",
                    "value": "500"
                },
                {
                    "label": "Golf equipment",
                    "value": "600"
                },
                {
                    "label": "Jewelry",
                    "value": "700"
                },
                {
                    "label": "Musical instruments",
                    "value": "800"
                },
                {
                    "label": "Silverware",
                    "value": "900"
                },
                {
                    "label": "Stamps",
                    "value": "1000"
                }
            ]
        },
        {
            "name": "SecuritiesSpecialLimits",
            "label": "Securities, Accounts, Deeds",
            "enumerations": [
                {
                    "label": "$1,500 - Included",
                    "value": "1500"
                },
                {
                    "label": "$1,600",
                    "value": "1600"
                },
                {
                    "label": "$1,700",
                    "value": "1700"
                },
                {
                    "label": "$1,800",
                    "value": "1800"
                },
                {
                    "label": "$1,900",
                    "value": "1900"
                },
                {
                    "label": "$2,000",
                    "value": "2000"
                },
                {
                    "label": "$2,100",
                    "value": "2100"
                },
                {
                    "label": "$2,200",
                    "value": "2200"
                },
                {
                    "label": "$2,300",
                    "value": "2300"
                },
                {
                    "label": "$2,400",
                    "value": "2400"
                },
                {
                    "label": "$2,500",
                    "value": "2500"
                },
                {
                    "label": "$2,600",
                    "value": "2600"
                },
                {
                    "label": "$2,700",
                    "value": "2700"
                },
                {
                    "label": "$2,800",
                    "value": "2800"
                },
                {
                    "label": "$2,900",
                    "value": "2900"
                },
                {
                    "label": "$3,000",
                    "value": "3000"
                }
            ]
        },
        {
            "name": "SkateboardRamp",
            "label": "Skateboard ramp or bicycle jump on the property?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "StructureType",
            "label": "Structure Type",
            "enumerations": [
                {
                    "label": "Single family dwelling",
                    "value": "100"
                },
                {
                    "label": "Two family dwelling",
                    "value": "101"
                },
                {
                    "label": "Three family dwelling",
                    "value": "102"
                },
                {
                    "label": "Four family dwelling",
                    "value": "103"
                },
                {
                    "label": "Row or Townhouse",
                    "value": "105"
                }
            ]
        },
        {
            "name": "ThreeOrMoreHomes",
            "label": "In a group of 3 or more homes?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "TownHouseStructureType",
            "label": "# Of Units In Fire Division",
            "enumerations": [
                {
                    "label": "1 to 2",
                    "value": "100"
                },
                {
                    "label": "3 to 4",
                    "value": "300"
                },
                {
                    "label": "5 through 8",
                    "value": "500"
                },
                {
                    "label": "9 or over",
                    "value": "900"
                }
            ]
        },
        {
            "name": "Trampoline",
            "label": "Trampoline on the property?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "TrusteeOccupancy",
            "label": "Trustee Occupancy",
            "enumerations": [
                {
                    "label": "Trustee Only",
                    "value": "100"
                },
                {
                    "label": "Trustee and Beneficiary or Grantor",
                    "value": "200"
                },
                {
                    "label": "Trustee, Beneficiary and Grantor",
                    "value": "250"
                },
                {
                    "label": "Beneficiary or Grantor Only",
                    "value": "300"
                },
                {
                    "label": "Beneficiary and Grantor Only",
                    "value": "350"
                }
            ]
        },
        {
            "name": "UndergroundTanks",
            "label": "Any underground fuel tanks on the property?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "UndergroundTanksStatus",
            "label": "Status of tanks?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "UnlockedPoolGate",
            "label": "Is pool attached to decking without a locking gate?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "ViciousAnimal",
            "label": "Any animal ever bitten or displayed vicious tendencies?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "VisibleFromRoad",
            "label": "Visible From Main, Public Road?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "WaterBackupCoverage",
            "label": "Water Backup",
            "enumerations": [
                {
                    "label": "$0 - Excluded",
                    "value": "0"
                },
                {
                    "label": "$5,000",
                    "value": "5000"
                }
            ]
        },
        {
            "name": "WaterbackupDeductible",
            "label": "Water backup deductible",
            "enumerations": [
                {
                    "label": "$500",
                    "value": "5"
                }
            ]
        },
        {
            "name": "WoodStove",
            "label": "Is There A Wood, Wood Pellet Or Coal Stove?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "WSApproved",
            "label": "Professionally installed and Inspected?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "WSSeparateFlue",
            "label": "Separate flue from other heat sources?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "WSSupplementalHeatOnly",
            "label": "Supplemental heat source only?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "WSVentedChimney",
            "label": "Vented to tile-lined or insulated chimney?",
            "enumerations": [
                {
                    "label": "Yes",
                    "value": "100"
                },
                {
                    "label": "No",
                    "value": "200"
                }
            ]
        },
        {
            "name": "Cancel",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "1",
                    "label": "Insured Request"
                }
            ]
        },
        {
            "name": "ReinstateReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "27",
                    "label": "Payment Received After Effective Date Of Cancellation"
                }
            ]
        },
        {
            "name": "ChangeAdditionalInterestReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "51",
                    "label": "Add Or Change Additional Interest"
                },
                {
                    "value": "77",
                    "label": "Add Or Change Third Party Designee"
                }
            ]
        },
        {
            "name": "ChangeCustomerReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "52",
                    "label": "Add Or Change Additional Insured"
                },
                {
                    "value": "54",
                    "label": "Change Mailing Address Only"
                },
                {
                    "value": "153",
                    "label": "Change Contact Information"
                },
                {
                    "value": "154",
                    "label": "Change Customer Name"
                },
                {
                    "value": "99",
                    "label": "Change Property Address"
                }
            ]
        },
        {
            "name": "UpdateMortgageeReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "53",
                    "label": "Add Or Change Mortgagee Or Lien Holder"
                }
            ]
        },
        {
            "name": "EndorseReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "57",
                    "label": "Add Or Change Additional Amounts Of Insurance "
                },
                {
                    "value": "58",
                    "label": "Remove Or Add Functional Replacement Cost"
                },
                {
                    "value": "60",
                    "label": "Change Coverage A"
                },
                {
                    "value": "61",
                    "label": "Change Coverage C"
                },
                {
                    "value": "62",
                    "label": "Change Coverage D"
                },
                {
                    "value": "63",
                    "label": "Change Personal Liability "
                },
                {
                    "value": "64",
                    "label": "Change Medical Payments"
                },
                {
                    "value": "65",
                    "label": "Add Water Back Up"
                },
                {
                    "value": "66",
                    "label": "Add Identity Fraud"
                },
                {
                    "value": "67",
                    "label": "Increase Basic Ordinance & Law "
                },
                {
                    "value": "68",
                    "label": "Add Other Structures"
                },
                {
                    "value": "69",
                    "label": "Add Permitted Incidental Occupancy"
                },
                {
                    "value": "70",
                    "label": "Add Watercraft Liability"
                },
                {
                    "value": "72",
                    "label": "Add Personal Injury"
                },
                {
                    "value": "73",
                    "label": "Change All Peril Deductible"
                },
                {
                    "value": "74",
                    "label": "Schedule Personal Property"
                },
                {
                    "value": "75",
                    "label": "Change Hurricane Deductible"
                },
                {
                    "value": "78",
                    "label": "Change Loss Settlement For Contents"
                },
                {
                    "value": "80",
                    "label": "Increase Loss Assessment"
                },
                {
                    "value": "82",
                    "label": "Add Earthquake Coverage"
                },
                {
                    "value": "84",
                    "label": "Increase Coverage Based On Physical Inspection"
                },
                {
                    "value": "85",
                    "label": "Change Rating Characteristics Based On Physical Inspection"
                },
                {
                    "value": "86",
                    "label": "Increase Credit Card, EFT Coverage"
                },
                {
                    "value": "87",
                    "label": "Change Personal Property Special Limits"
                },
                {
                    "value": "93",
                    "label": "Change Deductible Based On Physical Inspection"
                },
                {
                    "value": "94",
                    "label": "Change in Coverage B"
                },
                {
                    "value": "96",
                    "label": "Mechanical breakdown"
                },
                {
                    "value": "97",
                    "label": "Update interior risk characteristics"
                },
                {
                    "value": "98",
                    "label": "Add pool to policy"
                },
                {
                    "value": "98",
                    "label": "Update property location address"
                },
                {
                    "value": "121",
                    "label": "Protective device credit"
                },
                {
                    "value": "122",
                    "label": "Wind-loss mitigation credit"
                },
                {
                    "value": "123",
                    "label": "Multi-policy discount"
                },
                {
                    "value": "124",
                    "label": "Prime-time discount"
                },
                {
                    "value": "125",
                    "label": "Conditional liability surcharge"
                }
            ]
        },
        {
            "name": "ChangePaymentPlanReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "155",
                    "label": "Change Payment Plan"
                }
            ]
        },
        {
            "name": "PendingCancelReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "201",
                    "label": "Payment Received"
                }
            ]
        },
        {
            "name": "ApplyChargeReason",
            "label": "Reason Code",
            "enumerations": [
                {
                    "value": "900",
                    "label": "Installment Charge"
                },
                {
                    "value": "901",
                    "label": "Late Payment Charge"
                },
                {
                    "value": "902",
                    "label": "NSF Charge"
                },
                {
                    "value": "903",
                    "label": "Service Charge"
                }
            ]
        }
    ]
};

describe('IPM Module', function (){

  describe('Create an IPM Module', function (){

    var ajax_count = 0;
    beforeEach(function(){
      if (ajax_count < 1) {
        var callback = jasmine.createSpy();
        policy.fetch({
            success : callback
          });        
        waitsFor(function() {
          return callback.callCount > 0;
        }, "Timeout BOOM!", 2000)
      }
      ajax_count++;
    })

    // IPM Module is an object
    it ('is an object', function () {
      expect(ipm).toEqual(jasmine.any(Object));
    });

    // IPM Module has a config
    it ('has a CONFIG hash', function () {
      expect(ipm.CONFIG).not.toBe(null);
      expect(ipm.CONFIG).toEqual(jasmine.any(Object));
      console.log(ipm);
    });

    // IPM Module has a policy
    it ('has a Policy', function () {
      expect(ipm.POLICY).not.toBe(null);
      expect(ipm.POLICY).toEqual(jasmine.any(Object));
      expect(ipm.POLICY instanceof Backbone.Model).toBe(true);
    });

  });

  describe('Create an IPMView', function (){

    // var ipmview = new IPMView({
    //     'MODULE' : ipm,
    //     'DEBUG'  : true
    //   });
    console.log(['VIEW',ipm])
    var action = new IPMActionView({
      MODULE : ipm,
      PARENT_VIEW : ipm.VIEW
    })

    it ('IPMView is an object and Backbone.View', function () {
      expect(ipm.VIEW).toEqual(jasmine.any(Object));
      expect(ipm.VIEW instanceof Backbone.View).toBe(true);
    });

    it ('IPMView can route actions', function () {
      // expect(ipm.VIEW).toEqual(jasmine.any(Object));
      // expect(ipm.VIEW instanceof Backbone.View).toBe(true);
    });

    it ('IPMActionView is an object and Backbone.View', function () {
      expect(action).toEqual(jasmine.any(Object));
      expect(action instanceof Backbone.View).toBe(true);
    });

  })

  describe('IPMChangeSet : Policy Change Set', function(){

    var user = {}

    user = new UserModel({
      urlRoot  : 'mocks/',
      username : 'cru4t@cru360.com',
      password : 'abc123'
    });

    var VALUES = {
      changedValues : ['appliedDate','paymentAmount','paymentMethod'],
      formValues : {
        appliedDate           : "2011-01-15",
        paymentAmount         : -124,
        paymentBatch          : "",
        paymentMethod         : "300",
        paymentReference      : "",
        positivePaymentAmount : 124,
        postmarkDate          : ""
      }
    };

    var ChangeSet = new IPMChangeSet(ipm.POLICY, 'MakePayment', user);

    it ('IPMChangeSet is an object and a change set', function () {
      expect(ChangeSet).toEqual(jasmine.any(Object));
      expect(ChangeSet instanceof IPMChangeSet).toBe(true);
    });

    it ('IPMChangeSet has a policy', function () {
      expect(ChangeSet.POLICY).toEqual(jasmine.any(Object));
      expect(ChangeSet.POLICY instanceof Backbone.Model).toBe(true);
    });

    it ('IPMChangeSet has a user', function () {
      var callback = jasmine.createSpy();
      user.fetch({
        success : callback
      })            
      waitsFor(function() {
        if (callback.mostRecentCall.args !== undefined) {
          callback.mostRecentCall.args[0].parse_identity();
        }
        return callback.callCount > 0
      }, "Timeout BOOM!", 2000);
      runs(function(){
        expect(ChangeSet.USER).toEqual(jasmine.any(Object));
        expect(ChangeSet.USER instanceof Backbone.Model).toBe(true);
      });
    });

    it ('IPMChangeSet has an action', function () {
      expect(ChangeSet.ACTION).toEqual(jasmine.any(String));
      expect(ChangeSet.ACTION).toBe('MakePayment');
    });

    it ('IPMChangeSet can make a Policy Context object', function () {
      var context = {
        id            : "d1716d6e86334c4db583278d5889deb4",
        user          : "cru4t@cru360.com",
        version       : "4",
        timestamp     : moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ'),
        datestamp     : moment(new Date()).format("YYYY-MM-DD"),
        effectiveDate : moment("2012-11-05").format('YYYY-MM-DDTHH:mm:ss.sssZ'),
        appliedDate   : moment("2011-01-15").format('YYYY-MM-DDTHH:mm:ss.sssZ'),
        comment       : "posted by Policy Central IPM Module"
      }
      VALUES.formValues.effectiveDate = "2012-11-05";
      expect(ChangeSet.getPolicyContext(policy, user, VALUES)).toEqual(jasmine.any(Object));
      expect(ChangeSet.getPolicyContext(policy, user, VALUES)).toEqual(context);
    });

    it ('IPMChangeSet can make a Policy Change Set XML Document', function () {

      var xml = '<PolicyChangeSet schemaVersion="3.1"><Initiation><Initiator type="user">cru4t@cru360.com</Initiator></Initiation><Target><Identifiers><Identifier name="InsightPolicyId" value="d1716d6e86334c4db583278d5889deb4" /></Identifiers><SourceVersion>4</SourceVersion></Target><EffectiveDate>2012-11-05T00:00:00.000-05:00</EffectiveDate><AppliedDate>2011-01-15T00:00:00.000-05:00</AppliedDate><Comment>posted by Policy Central IPM Module</Comment><Ledger><LineItem value="-124" type="PAYMENT" ><Memo></Memo><DataItem name="Reference" value="" /><DataItem name="PaymentMethod" value="300" /></LineItem></Ledger><EventHistory><Event type="Payment"><DataItem name="PaymentAmount" value="124" /><DataItem name="PaymentMethod" value="300" /><DataItem name="PaymentReference" value="" /><DataItem name="PaymentBatch" value="" /><DataItem name="PostmarkDate" value="" /><DataItem name="AppliedDate" value="2011-01-15T00:00:00.000-05:00" /></Event></EventHistory></PolicyChangeSet>';

      // Timestamps will never match so remove them
      var changeSet = ChangeSet.getPolicyChangeSet(VALUES).replace(/timestamp="([\w\d-:.]*)"/g, '');

      expect(changeSet).toEqual(jasmine.any(String));
      expect(changeSet).beEquivalentTo(xml);

    });

    it ('IPMChangeSet can getPayloadType from ChangeSet XML', function () {
      var xml = ChangeSet.getPolicyChangeSet(VALUES)
      expect(ChangeSet.getPayloadType($.parseXML(xml))).toEqual('policychangeset');
    });

    it ('IPMChangeSet can getSchemaVersion from ChangeSet XML', function () {
      var xml = ChangeSet.getPolicyChangeSet(VALUES)
      expect(ChangeSet.getSchemaVersion($.parseXML(xml))).toEqual('3.1');
    });

  });

  // TRANSACTION REQUESTS

  describe('IPMChangeSet : Transaction Request', function(){

    var user = {}

    user = new UserModel({
      urlRoot  : 'mocks/',
      username : 'cru4t@cru360.com',
      password : 'abc123'
    });

    endorse = new Endorse({
      MODULE : ipm,
      PARENT_VIEW : ipm.VIEW
    });

    var VALUES = {
      changedValues : [
        'effectiveDate',
        'reasonCode',
        'comment',
        'ReplacementCostBuilding',
        'PropertyMarketValue',
        'OptionCoverageD',
        'CoverageD',
        'FoundationBasementPercentage'
      ],
      formValues : {
        AbsenteeLandlord: "200",
        AllOtherPerilsDeductible: "10",
        AllWeatherAccess: "100",
        AutoPolicyCarrier: "",
        AutoPolicyNumber: "",
        Basement: "500",
        BasementPercentComplete: "0",
        BeneficiaryName: "false",
        BurglarAlarm: "1",
        CentralAir: "200",
        ConstructionType: "200",
        ConstructionYear: "1939",
        ConstructionYearRoof: "1980",
        CoverageA: "500000",
        CoverageB: "50000",
        CoverageC: "25000",
        CoverageD: "135000",
        CoverageL: "100000",
        CoverageM: "1000",
        DistanceFireHydrant: "1000",
        DistanceFireStation: "5",
        DistanceToCoast: "0.73",
        DistanceToCoastSecondary: "0.73",
        EarthquakeCoverage: "200",
        EarthquakeDeductible: "",
        EarthquakeLossAssessmentCoverage: "",
        FireAlarm: "1",
        FoundationBasementPercentage: "100",
        FoundationType: "300",
        FullBathQuality: "100",
        FunctionalReplacementCost: "100",
        GarageType: "20520",
        GrantorName: "false",
        HalfBathQuality: "100",
        HandrailWalkwayLiability: "200",
        HomeFeatures1: "0",
        HomeFeatures2: "0",
        HomeFeatures3: "0",
        HomeStyle: "400",
        HurricaneDeductible: "302",
        IdentityFraudCoverage: "0",
        ImmovablePoolLadder: "",
        IncidentalBusinessOccupancy: "200",
        IncidentalBusinessOccupancyDescription: "",
        IncidentalBusinessOccupancyType: "",
        IncreasedOrdinanceLimit: "1000",
        Insured1BirthDate: "0NaN-NaN-NaN",
        KeroseneHeater: "200",
        KeroseneHeaterAge: "",
        KeroseneHeaterSupplementalHeatOnly: "",
        KitchenQuality: "100",
        LossAmount1: "",
        LossAmount2: "",
        LossAmount3: "",
        LossAmount4: "",
        LossAmount5: "",
        LossAssessmentCoverage: "0",
        LossDate1: "",
        LossDate2: "",
        LossDate3: "",
        LossDate4: "",
        LossDate5: "",
        LossDescription1: "",
        LossDescription2: "",
        LossDescription3: "",
        LossDescription4: "",
        LossDescription5: "",
        MechanicalBreakdownCoverage: "200",
        MoldLimit: "20000",
        MonthsUnoccupied: "0",
        MultiLayeredRoofing: "200",
        MultiPolicy: "200",
        NumberOfFireplaces: "0",
        NumberOfFullBaths: "1",
        NumberOfHalfBaths: "0",
        NumberOfKitchens: "2",
        NumberOfStories: "200",
        OpeningProtectionType: "1",
        OptionCoverageB: "1000",
        OptionCoverageC: "500",
        OptionCoverageD: "2500",
        PersonalInjuryCoverage: "200",
        PoolFence: "",
        PoolType: "1",
        PrimeTimeDiscount: "200",
        PropertyAddressLine2: "",
        PropertyCity: "BRONX",
        PropertyHazardLocation: "Low",
        PropertyHazardLocationLastUpdated: "04/29/2012",
        PropertyManagerAddressCity: "BRONX",
        PropertyManagerAddressLine1: "900 SWINTON AVE",
        PropertyManagerAddressLine2: "",
        PropertyManagerAddressState: "NY",
        PropertyManagerAddressZip: "10465",
        PropertyManagerDistanceToRisk: "0",
        PropertyManagerType: "100",
        PropertyMarketValue: "530000",
        PropertyOccupancy: "200",
        PropertyState: "NY",
        PropertyStreetName: "SWINTON AVE",
        PropertyStreetNumber: "900",
        PropertyUsage: "100",
        PropertyZipCode: "10465",
        PropertyZipCodePlusFour: "1919",
        ProtectionClass: "4",
        ReplacementCostBuilding: "582629",
        ResidenceHeldInTrust: "200",
        RoofCoveringType: "500",
        RoofGeometryType: "200",
        ShortTermRental: "200",
        SingleOccupancy: "200",
        SpecialLossSettlement: "200",
        SquareFootUnderRoof: "1700",
        StructureType: "101",
        StudentOccupancy: "200",
        TheftCoverage: "100",
        ThreeOrMoreHomes: "100",
        TownHouseStructureType: "100",
        TrustName: "",
        TrusteeName: "false",
        TrusteeOccupancy: "",
        VacancyCoverage: "200",
        VisibleFromRoad: "100",
        WSApproved: "",
        WSSeparateFlue: "",
        WSSupplementalHeatOnly: "",
        WSVentedChimney: "",
        WaterBackupCoverage: "0",
        WoodStove: "200",
        comment: "asdasda",
        datestamp: "2012-11-09",
        effectiveDate: "2012-11-19",
        reasonCode: "60"
      }
    };

    var ChangeSet = new IPMChangeSet(ipm.POLICY, 'Endorse', user);

    var ajax_value = 0;
    var viewData; // viewData stores processed ModelJS data

    it ('IPMChangeSet is an object and a change set', function () {

      waitsFor(function() {
        return ipm.VIEW;
      }, "IPM Module should have a VIEW", 1000);

      runs(function(){
        console.log(ipm.VIEW)
        expect(ChangeSet).toEqual(jasmine.any(Object));
        expect(ChangeSet instanceof IPMChangeSet).toBe(true);
      });
    });

    it ('IPMChangeSet has a policy', function () {

      waitsFor(function() {
        return ipm.VIEW.route('Endorse');
      }, "IPMView should be able to route and fetch files", 3000);

      runs(function(){
        console.log(['IPMView',ipm.VIEW]);
        expect(ChangeSet.POLICY).toEqual(jasmine.any(Object));
        expect(ChangeSet.POLICY instanceof Backbone.Model).toBe(true);
      });
    });

    it ('IPMChangeSet has a user', function () {
      var callback = jasmine.createSpy();
      user.fetch({
        success : callback
      })            
      waitsFor(function() {
        if (callback.mostRecentCall.args !== undefined) {
          callback.mostRecentCall.args[0].parse_identity();
        }
        return callback.callCount > 0
      }, "Timeout BOOM!", 1000);
      runs(function(){
        expect(ChangeSet.USER).toEqual(jasmine.any(Object));
        expect(ChangeSet.USER instanceof Backbone.Model).toBe(true);
      });
    });

    it ('IPMChangeSet has an action', function () {
      expect(ChangeSet.ACTION).toEqual(jasmine.any(String));
      expect(ChangeSet.ACTION).toBe('Endorse');
    });

    it ('IPMChangeSet can make a Policy Context object for a TransactionRequest', function () {
      var action;

      waitsFor(function() {
        action = ipm.VIEW.route('Endorse');
        return action;
      }, "IPMView should be able to route and fetch files", 1000);

      runs(function(){
        var context = {
          id            : "d1716d6e86334c4db583278d5889deb4",
          user          : "cru4t@cru360.com",
          version       : "4",
          timestamp     : moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ'),
          datestamp     : moment(new Date()).format("YYYY-MM-DD"),
          effectiveDate : "2012-11-19",
          comment       : "asdasda",
          intervalRequest: [{
              key: 'effectiveDate',
              value: '2012-11-19'
            }, {
              key: 'comment',
              value: 'asdasda'
            }, {
              key: 'ReplacementCostBuilding',
              value: '582629'
            }, {
              key: 'CoverageD',
              value: '135000'
            }, {
              key: 'FoundationBasementPercentage',
              value: '100'
            }, {
              key: 'OptionCoverageD',
              value: '2500'
            }]
        }

        // ViewData OBJ to store processed ModelJS data
        viewData = policy.getTermDataItemValues(modeljs)
        viewData = policy.getEnumerations(viewData, modeljs)
        viewData = _.extend(
          viewData,
          policy.getPolicyOverview(),
          { 
            policyOverview : true,
            policyId : policy.get_pxServerIndex()
          }
        )

        // Need to ensure same timestamps to pass test
        var TR = ChangeSet.getTransactionContext(policy, user, VALUES, viewData);
        TR.timestamp = context.timestamp = moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ');

        expect(TR).toEqual(jasmine.any(Object));
        expect(TR).toEqual(context);
      });

    });

    it ('IPMChangeSet can make a TransactionRequest XML Document', function () {

      var xml = '<TransactionRequest schemaVersion="1.4" type=""><Initiation><Initiator type="user">cru4t@cru360.com</Initiator></Initiation><Target><Identifiers><Identifier name="InsightPolicyId" value="d1716d6e86334c4db583278d5889deb4"/></Identifiers><SourceVersion>4</SourceVersion></Target><EffectiveDate>2012-11-19</EffectiveDate><ReasonCode>60</ReasonCode><Comment>asdasda</Comment><IntervalRequest><StartDate>2012-11-19</StartDate><DataItem name="effectiveDate" value="2012-11-19" /><DataItem name="comment" value="asdasda" /><DataItem name="ReplacementCostBuilding" value="582629" /><DataItem name="CoverageD" value="135000" /><DataItem name="FoundationBasementPercentage" value="100" /><DataItem name="OptionCoverageD" value="2500" /></IntervalRequest></TransactionRequest>';

      // Timestamps will never match so remove them
      var TR = ChangeSet.getTransactionRequest(VALUES, viewData).replace(/timestamp="([\w\d-:.]*)"/g, '');

      expect(TR).toEqual(jasmine.any(String));
      expect(TR).beEquivalentTo(xml);

    });

    it ('IPMChangeSet can getPayloadType from TransactionRequest XML', function () {
      var xml = ChangeSet.getTransactionRequest(VALUES, viewData);
      expect(ChangeSet.getPayloadType($.parseXML(xml))).toEqual('transactionrequest');
    });

    it ('IPMChangeSet can getSchemaVersion from TransactionRequest XML', function () {
      var xml = ChangeSet.getTransactionRequest(VALUES, viewData);
      expect(ChangeSet.getSchemaVersion($.parseXML(xml))).toEqual('1.4');
    });

  });

  describe('IPMChangeSet : Transaction Request : CancelReinstate', function() {

    var ajax_count = 0
    var actionView = null;

    beforeEach(function(){
      if (ajax_count < 1) {
        var view     = ipm.VIEW;
        var callback = jasmine.createSpy();
        var _this    = this;
        actionView = view.route('CancelReinstate',{
          success : function(ActionView, action_name) {
            ActionView.CURRENT_SUBVIEW = 'cancel-pending';
            ActionView.fetchTemplates(policy, 'cancel-pending', callback);
          },
          error : function(err, action) {
            console.log(['VIEW ROUTE ERROR', err]);
          }
        });

        waitsFor(function() {
          return callback.callCount > 0;
        }, "Timeout BOOM!", 1000)
      }
      ajax_count++;
    })


    // IPM Module is an object
    it ('is an object', function () {
      expect(actionView).toEqual(jasmine.any(Object));
    });

  });

});




});