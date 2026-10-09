@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZOAPR_HEAD'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZOA_C_PurchReqTP
  provider contract transactional_query
  as projection on ZOA_R_PurchReqTP
  association [1..1] to ZOA_R_PurchReqTP as _BaseEntity on $projection.PrUUID = _BaseEntity.PrUUID
{
  key PrUUID,
  PrID,
  Title,
  SupplierID,
  DeliveryDate,
  @Semantics: {
    amount.currencyCode: 'CurrencyCode'
  }
  TotalAmount,
  @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Currency', 
      entity.name: 'I_CurrencyStdVH', 
      useForValidation: true
    } ]
  }
  CurrencyCode,
  Status,
  RejectReason,
  @Semantics: {
    user.createdBy: true
  }
  CreatedBy,
  @Semantics: {
    systemDateTime.createdAt: true
  }
  CreatedAt,
  @Semantics: {
    user.localInstanceLastChangedBy: true
  }
  LocalLastChangedBy,
  @Semantics: {
    systemDateTime.localInstanceLastChangedAt: true
  }
  LocalLastChangedAt,
  @Semantics: {
    systemDateTime.lastChangedAt: true
  }
  LastChangedAt,
  _BaseEntity,
  _Items : redirected to composition child ZOA_C_PurchReqItemTP
}
