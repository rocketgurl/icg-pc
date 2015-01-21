define [
  'BaseView'
  'text!modules/PolicyQuickView/templates/tpl_underwriting_tab.html'
], (BaseView, tpl_underwriting_tab) ->

  class UnderwritingTabView extends BaseView

    enumsHurricaneDeductible :
      0   : 'N/A'
      100 : '1%'
      200 : '2%'
      300 : '3%'
      400 : '4%'
      500 : '5%'

    enumsWindHailDeductible :
      0   : 'None'
      100 : '1%'
      200 : '2%'
      300 : '3%'
      400 : '4%'
      500 : '5%'
      25  : '$2,500'
      50  : '$5,000'
      101 : '$10,000'

    enumsAllOtherPerilsDeductible :
      5   : '$500'
      10  : '$1,000'
      15  : '$1,500'
      20  : '$2,000'
      25  : '$2,500'
      30  : '$3,000'
      40  : '$4,000'
      50  : '$5,000'
      101 : '$10,000'

    enumsRoofCoveringType :
      0   : 'Unknown'
      100 : 'Reinforced Concrete'
      200 : 'Metal - Steel'
      250 : 'Metal - Other Than Steel'
      300 : 'Single Ply Membrane'
      400 : 'Built Up Roof'
      500 : 'Asphalt/Composite Shingles'
      502 : 'Architectural Shingles'
      600 : 'Concrete/Clay Tiles'
      700 : 'Wood Shingles'
      710 : 'Wook Shake'
      800 : 'Rubber/Bituminous'

    enumsRoofGeometryType :
      0   : 'Unknown'
      100 : 'Flat'
      200 : 'Gable'
      300 : 'Hip'

    enumsPropertyUsage :
      100 : 'Primary'
      200 : 'Secondary'
      300 : 'Seasonal'

    enumsStructureType :
      100 : 'Single family dwelling'
      101 : 'Two family dwelling'
      102 : 'Three family dwelling'
      103 : 'Four family dwelling'
      105 : 'Single Family (attached)/Row or Townhouse'

    initialize : (options) ->
      @POLICY = options.policy
      @POLICY.on 'change:refresh change:version', @render, this
      @render()

    getUnderwritingData : ->
      data = @POLICY.getUnderwritingData()
      @mapDataItemValues data

    mapDataItemValues : (data) ->
      data.CoverageA                = @Helpers.formatLocaleNum data.CoverageA
      data.HurricaneDeductible      = @Helpers.prettyMap data.HurricaneDeductible, @enumsHurricaneDeductible
      data.WindHailDeductible       = @Helpers.prettyMap data.WindHailDeductible, @enumsWindHailDeductible
      data.AllOtherPerilsDeductible = @Helpers.prettyMap data.AllOtherPerilsDeductible, @enumsAllOtherPerilsDeductible
      data.FloorArea                = @Helpers.formatLocaleNum data.FloorArea
      data.RoofCoveringType         = @Helpers.prettyMap data.RoofCoveringType, @enumsRoofCoveringType
      data.RoofGeometryType         = @Helpers.prettyMap data.RoofGeometryType, @enumsRoofGeometryType
      data.PropertyUsage            = @Helpers.prettyMap data.PropertyUsage, @enumsPropertyUsage
      data.StructureType            = @Helpers.prettyMap data.StructureType, @enumsStructureType
      data

    render : ->
      data     = @getUnderwritingData() or {}
      data.cid = @cid
      @$el.html @Mustache.render tpl_underwriting_tab, data
      return this
