@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase requisition item (projection)'
@Metadata.allowExtensions: true
define view entity ZOA_C_PurchReqItemTP
  as projection on ZOA_R_PurchReqItemTP
{
  key ItemUuid,
      PrUuid,
      ItemNo,
      Description,
      Quantity,
      Unit,
      UnitPrice,
      ItemAmount,
      CurrencyCode,
      LocalLastChangedAt,
      _PurchReq : redirected to parent ZOA_C_PurchReqTP
}
