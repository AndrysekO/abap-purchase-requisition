@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZOAPR_HEAD'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZOA_C_PurchReqTP
  provider contract TRANSACTIONAL_QUERY
  as projection on ZOA_R_PurchReqTP
  association [1..1] to ZOA_R_PurchReqTP as _BaseEntity on $projection.PRUUID = _BaseEntity.PRUUID
{
  key PrUUID,
  PrID,
  Title,
  SupplierID,
  DeliveryDate,
  @Semantics: {
    Amount.Currencycode: 'CurrencyCode'
  }
  TotalAmount,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'Currency', 
      Entity.Name: 'I_CurrencyStdVH', 
      Useforvalidation: true
    } ]
  }
  CurrencyCode,
  Status,
  RejectReason,
  @Semantics: {
    User.Createdby: true
  }
  CreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  CreatedAt,
  @Semantics: {
    User.Localinstancelastchangedby: true
  }
  LocalLastChangedBy,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
