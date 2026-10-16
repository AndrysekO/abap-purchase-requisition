CLASS lhc_zoa_r_purchreqtp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF status,
        new       TYPE zoa_pr_status VALUE 'N',
        submitted TYPE zoa_pr_status VALUE 'S',
        approved  TYPE zoa_pr_status VALUE 'A',
        rejected  TYPE zoa_pr_status VALUE 'R',
      END OF status.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR PurchReq
        RESULT result,
      setDefaults FOR DETERMINE ON MODIFY
       keys FOR PurchReq~setDefaults.
ENDCLASS.

CLASS lhc_zoa_r_purchreqtp IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD setDefaults.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( Status CurrencyCode DeliveryDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requisitions).

    " Skip requisitions where everything is already filled
    DELETE requisitions WHERE Status       IS NOT INITIAL
                          AND CurrencyCode IS NOT INITIAL
                          AND DeliveryDate IS NOT INITIAL.
    CHECK requisitions IS NOT INITIAL.

    DATA default_date TYPE d.
    default_date = cl_abap_context_info=>get_system_date( ) + 14.

    MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        UPDATE FIELDS ( Status CurrencyCode DeliveryDate )
        WITH VALUE #( FOR req IN requisitions
          ( %tky         = req-%tky
            Status       = COND #( WHEN req-Status IS INITIAL
                                   THEN status-new ELSE req-Status )
            CurrencyCode = COND #( WHEN req-CurrencyCode IS INITIAL
                                   THEN 'CZK' ELSE req-CurrencyCode )
            DeliveryDate = COND #( WHEN req-DeliveryDate IS INITIAL
                                   THEN default_date ELSE req-DeliveryDate ) ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

ENDCLASS.
