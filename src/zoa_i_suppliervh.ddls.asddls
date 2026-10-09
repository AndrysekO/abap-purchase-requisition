@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplier value help'
@Search.searchable: true
define view entity ZOA_I_SupplierVH
  as select from ZOA_I_Supplier
{
      @ObjectModel.text.element: ['SupplierName']
      @Search.defaultSearchElement: true
  key SupplierId,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      SupplierName,
      City,
      Country
}
where IsBlocked <> 'X'
