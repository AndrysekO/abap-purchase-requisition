CLASS lhc_purchreqitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setItemDefaults FOR DETERMINE ON MODIFY
      keys FOR PurchReqItem~setItemDefaults.

ENDCLASS.

CLASS lhc_purchreqitem IMPLEMENTATION.

    METHOD setItemDefaults.
    " 1. The new items, and the requisition each one belongs to
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        FIELDS ( ItemNo PrUUID ) WITH CORRESPONDING #( keys )
        RESULT DATA(new_items)
      ENTITY PurchReqItem BY \_PurchReq
        FIELDS ( CurrencyCode ) WITH CORRESPONDING #( keys )
        RESULT DATA(requisitions).

    " Two new items can belong to the same requisition: keep each one once
    SORT requisitions BY PrUUID.
    DELETE ADJACENT DUPLICATES FROM requisitions COMPARING PrUUID.

    " 2. All items of those requisitions, to find the highest number in use
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq BY \_Items
        FIELDS ( ItemNo PrUUID ) WITH CORRESPONDING #( requisitions )
        RESULT DATA(all_items).

    DATA updates TYPE TABLE FOR UPDATE zoa_r_purchreqtp\\PurchReqItem.

    LOOP AT requisitions INTO DATA(requisition).
      " Highest item number already used in this requisition
      DATA(max_no) = 0.
      LOOP AT all_items INTO DATA(existing) WHERE PrUUID = requisition-PrUUID.
        IF existing-ItemNo > max_no.
          max_no = existing-ItemNo.
        ENDIF.
      ENDLOOP.

      " Number the new items in steps of 10 and copy the currency
      LOOP AT new_items INTO DATA(new_item)
           WHERE PrUUID = requisition-PrUUID AND ItemNo IS INITIAL.
        max_no = max_no + 10.
        APPEND VALUE #( %tky         = new_item-%tky
                        ItemNo       = max_no
                        CurrencyCode = requisition-CurrencyCode ) TO updates.
      ENDLOOP.
    ENDLOOP.

    CHECK updates IS NOT INITIAL.

    MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        UPDATE FIELDS ( ItemNo CurrencyCode ) WITH updates
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

ENDCLASS.

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
