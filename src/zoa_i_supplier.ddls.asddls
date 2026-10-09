@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplier'
define view entity ZOA_I_Supplier
  as select from zoa_supplier
{
  key supplier_id as SupplierId,
      @Semantics.text: true
      name        as SupplierName,
      city        as City,
      country     as Country,
      blocked     as IsBlocked
}
