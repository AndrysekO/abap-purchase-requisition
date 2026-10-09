@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase requisition status value help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZOA_I_PRStatusVH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZOA_PR_STATUS' )
{
      @ObjectModel.text.element: ['StatusText']
  key cast( value_low as zoa_pr_status ) as Status,
      @Semantics.text: true
      text                               as StatusText
}
where language = $session.system_language
