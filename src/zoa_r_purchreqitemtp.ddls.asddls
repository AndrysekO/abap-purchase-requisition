@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase requisition item'
define view entity ZOA_R_PurchReqItemTP
  as select from zoa_pr_item
  association to parent ZOA_R_PurchReqTP as _PurchReq
    on $projection.PrUuid = _PurchReq.PrUUID
{
  key item_uuid             as ItemUuid,
      pr_uuid               as PrUuid,
      item_no               as ItemNo,
      description           as Description,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity              as Quantity,
      unit                  as Unit,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      unit_price            as UnitPrice,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      item_amount           as ItemAmount,
      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _PurchReq
}
