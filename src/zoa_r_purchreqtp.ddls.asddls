@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZOAPR_HEAD'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZOA_R_PurchReqTP
  as select from zoa_pr_head as PurchReq
  composition [0..*] of ZOA_R_PurchReqItemTP as _Items
{
  key pr_uuid as PrUUID,
  pr_id as PrID,
  title as Title,
  supplier_id as SupplierID,
  delivery_date as DeliveryDate,
  @Semantics.amount.currencyCode: 'CurrencyCode'
  total_amount as TotalAmount,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency_code as CurrencyCode,
  status as Status,
  reject_reason as RejectReason,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  _Items
}
