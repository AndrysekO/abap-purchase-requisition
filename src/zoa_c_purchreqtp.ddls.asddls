@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'Purchase requisition (projection)'
@ObjectModel.sapObjectNodeType.name: 'ZOAPR_HEAD'
@AccessControl.authorizationCheck: #MANDATORY
@Search.searchable: true
define root view entity ZOA_C_PurchReqTP
  provider contract transactional_query
  as projection on ZOA_R_PurchReqTP
  association [1..1] to ZOA_R_PurchReqTP as _BaseEntity on $projection.PrUUID = _BaseEntity.PrUUID
{
  key PrUUID,

      @Search.defaultSearchElement: true
      PrID,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Title,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['SupplierName']
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZOA_I_SupplierVH',
                                                      element: 'SupplierId' },
                                            useForValidation: true } ]
      SupplierID,
      _Supplier.SupplierName as SupplierName,

      DeliveryDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalAmount,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CurrencyStdVH',
                                                      element: 'Currency' },
                                            useForValidation: true } ]
      CurrencyCode,

      @ObjectModel.text.element: ['StatusText']
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZOA_I_PRStatusVH',
                                                      element: 'Status' } } ]
      Status,
      _Status.StatusText     as StatusText,

      RejectReason,

      @Semantics.user.createdBy: true
      CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,

      // Associations
      _BaseEntity,
      _Items : redirected to composition child ZOA_C_PurchReqItemTP
}
