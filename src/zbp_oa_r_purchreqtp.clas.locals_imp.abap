CLASS lhc_purchreqitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setItemDefaults FOR DETERMINE ON MODIFY
       keys FOR PurchReqItem~setItemDefaults.
    METHODS calcAmounts FOR DETERMINE ON MODIFY
       keys FOR PurchReqItem~calcAmounts.
    METHODS validateItemValues FOR VALIDATE ON SAVE
       keys FOR PurchReqItem~validateItemValues.

ENDCLASS.

CLASS lhc_purchreqitem IMPLEMENTATION.

  METHOD setItemDefaults.
    " 1. The new items, and the requisition each one belongs to
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        FIELDS ( ItemNo PrUUID Unit ) WITH CORRESPONDING #( keys )
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

      " Number the new items in steps of 10, copy the currency,
      " and default the unit to pieces if none was given
      LOOP AT new_items INTO DATA(new_item)
           WHERE PrUUID = requisition-PrUUID AND ItemNo IS INITIAL.
        max_no = max_no + 10.
        APPEND VALUE #( %tky         = new_item-%tky
                        ItemNo       = max_no
                        CurrencyCode = requisition-CurrencyCode
                        Unit         = COND #( WHEN new_item-Unit IS INITIAL
                                               THEN 'ST'    " internal code for piece
                                               ELSE new_item-Unit ) ) TO updates.
      ENDLOOP.
    ENDLOOP.

    CHECK updates IS NOT INITIAL.

    MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        UPDATE FIELDS ( ItemNo CurrencyCode Unit ) WITH updates
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD calcAmounts.
    " 1. Item amount = quantity × unit price
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        FIELDS ( Quantity UnitPrice ) WITH CORRESPONDING #( keys )
        RESULT DATA(items)
      ENTITY PurchReqItem BY \_PurchReq
        FIELDS ( PrUUID ) WITH CORRESPONDING #( keys )
        RESULT DATA(requisitions).

    MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        UPDATE FIELDS ( ItemAmount )
        WITH VALUE #( FOR item IN items
                      ( %tky       = item-%tky
                        ItemAmount = item-Quantity * item-UnitPrice ) )
      REPORTED DATA(update_reported).

    " Several changed items can belong to the same requisition
    SORT requisitions BY PrUUID.
    DELETE ADJACENT DUPLICATES FROM requisitions COMPARING PrUUID.

    " 2. Total = sum of all item amounts, including the ones just updated
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq BY \_Items
        FIELDS ( ItemAmount PrUUID ) WITH CORRESPONDING #( requisitions )
        RESULT DATA(all_items).

    MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        UPDATE FIELDS ( TotalAmount )
        WITH VALUE #( FOR req IN requisitions
          ( %tky        = req-%tky
            TotalAmount = REDUCE decfloat34( INIT sum = CONV decfloat34( 0 )
                                             FOR it IN all_items
                                             WHERE ( PrUUID = req-PrUUID )
                                             NEXT sum = sum + it-ItemAmount ) ) ).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD validateItemValues.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReqItem
        FIELDS ( Quantity Unit UnitPrice PrUUID ) WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " Allowed decimal places per unit, from SAP's unit configuration (one select for all)
    IF items IS NOT INITIAL.
      SELECT FROM I_UnitOfMeasure
        FIELDS UnitOfMeasure, UnitOfMeasureNumberOfDecimals
        FOR ALL ENTRIES IN @items
        WHERE UnitOfMeasure = @items-Unit
        INTO TABLE @DATA(units).
    ENDIF.

    LOOP AT items INTO DATA(item).
      " Clear this validation's old messages for the item
      APPEND VALUE #( %tky        = item-%tky
                      %state_area = 'VALIDATE_ITEM' ) TO reported-purchreqitem.

      " Rule 1: quantity must be greater than zero
      IF item-Quantity <= 0.
        APPEND VALUE #( %tky = item-%tky ) TO failed-purchreqitem.
        APPEND VALUE #( %tky              = item-%tky
                        %state_area       = 'VALIDATE_ITEM'
                        %path             = VALUE #( purchreq-%is_draft = item-%is_draft
                                                     purchreq-PrUUID    = item-PrUUID )
                        %msg              = new_message_with_text(
                                              severity = if_abap_behv_message=>severity-error
                                              text     = 'Quantity must be greater than zero' )
                        %element-Quantity = if_abap_behv=>mk-on ) TO reported-purchreqitem.
      ENDIF.

      " Rule 2: the unit must exist, and the quantity may not have
      " more decimal places than the unit allows (pieces: 0, kilograms: 3)
      DATA(unit_message) = VALUE string( ).
      READ TABLE units WITH KEY UnitOfMeasure = item-Unit INTO DATA(unit).
      IF item-Unit IS INITIAL.
        unit_message = 'Enter a unit'.
      ELSEIF sy-subrc <> 0.
        unit_message = |Unit { item-Unit } does not exist|.
      ELSEIF round( val = CONV decfloat34( item-Quantity )
                    dec = unit-UnitOfMeasureNumberOfDecimals ) <> item-Quantity.
        unit_message = |This unit allows at most { unit-UnitOfMeasureNumberOfDecimals } decimal places|.
      ENDIF.

      IF unit_message IS NOT INITIAL.
        APPEND VALUE #( %tky = item-%tky ) TO failed-purchreqitem.
        APPEND VALUE #( %tky              = item-%tky
                        %state_area       = 'VALIDATE_ITEM'
                        %path             = VALUE #( purchreq-%is_draft = item-%is_draft
                                                     purchreq-PrUUID    = item-PrUUID )
                        %msg              = new_message_with_text(
                                              severity = if_abap_behv_message=>severity-error
                                              text     = unit_message )
                        %element-Quantity = if_abap_behv=>mk-on ) TO reported-purchreqitem.
      ENDIF.

      " Rule 3: unit price must be greater than zero
      IF item-UnitPrice <= 0.
        APPEND VALUE #( %tky = item-%tky ) TO failed-purchreqitem.
        APPEND VALUE #( %tky               = item-%tky
                        %state_area        = 'VALIDATE_ITEM'
                        %path              = VALUE #( purchreq-%is_draft = item-%is_draft
                                                      purchreq-PrUUID    = item-PrUUID )
                        %msg               = new_message_with_text(
                                               severity = if_abap_behv_message=>severity-error
                                               text     = 'Unit price must be greater than zero' )
                        %element-UnitPrice = if_abap_behv=>mk-on ) TO reported-purchreqitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*"* Header handler: logic for the purchase requisition itself
CLASS lhc_zoa_r_purchreqtp DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF status,
        new       TYPE zoa_pr_status VALUE 'N',
        submitted TYPE zoa_pr_status VALUE 'S',
        approved  TYPE zoa_pr_status VALUE 'A',
        rejected  TYPE zoa_pr_status VALUE 'R',
      END OF status.

    " Requisitions below this total (in CZK) are approved automatically on submit
    CONSTANTS approval_limit TYPE zoa_pr_head-total_amount VALUE '10000.00'.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR PurchReq
      RESULT result.

    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PurchReq~setDefaults.

    METHODS setPrNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR PurchReq~setPrNumber.

    METHODS validateSupplier FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchReq~validateSupplier.

    METHODS validateDeliveryDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR PurchReq~validateDeliveryDate.

    METHODS submit FOR MODIFY
      IMPORTING keys FOR ACTION PurchReq~submit RESULT result.

    METHODS approve FOR MODIFY
      IMPORTING keys FOR ACTION PurchReq~approve RESULT result.

    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION PurchReq~reject RESULT result.

ENDCLASS.

CLASS lhc_zoa_r_purchreqtp IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Everyone may do everything for now (portfolio simplification)
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

  METHOD setPrNumber.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( PrID ) WITH CORRESPONDING #( keys )
      RESULT DATA(requisitions).

    " Only requisitions that don't have a number yet
    DELETE requisitions WHERE PrID IS NOT INITIAL.
    CHECK requisitions IS NOT INITIAL.

    " Highest number in use so far.
    " Phase 1: max + 1. Phase 2 replaces this with a number range,
    " which stays correct when several users save at the same moment.
    SELECT SINGLE FROM zoa_pr_head
      FIELDS MAX( pr_id )
      INTO @DATA(max_id).

    " Several requisitions saved together get consecutive numbers
    MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        UPDATE FIELDS ( PrID )
        WITH VALUE #( FOR req IN requisitions INDEX INTO i
                      ( %tky = req-%tky
                        PrID = max_id + i ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD validateSupplier.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( SupplierID ) WITH CORRESPONDING #( keys )
      RESULT DATA(requisitions).

    " Collect each supplier ID once, then read them all with ONE select
    DATA supplier_ids TYPE SORTED TABLE OF zoa_supplier-supplier_id WITH UNIQUE KEY table_line.
    LOOP AT requisitions INTO DATA(req) WHERE SupplierID IS NOT INITIAL.
      INSERT req-SupplierID INTO TABLE supplier_ids.
    ENDLOOP.

    IF supplier_ids IS NOT INITIAL.
      SELECT FROM zoa_i_supplier
        FIELDS SupplierId, IsBlocked
        FOR ALL ENTRIES IN @supplier_ids
        WHERE SupplierId = @supplier_ids-table_line
        INTO TABLE @DATA(suppliers).
    ENDIF.

    LOOP AT requisitions INTO DATA(requisition).
      " Clear this validation's old messages for the requisition
      APPEND VALUE #( %tky        = requisition-%tky
                      %state_area = 'VALIDATE_SUPPLIER' ) TO reported-purchreq.

      DATA(message) = VALUE string( ).
      IF requisition-SupplierID IS INITIAL.
        message = 'Enter a supplier'.
      ELSE.
        READ TABLE suppliers WITH KEY SupplierId = requisition-SupplierID INTO DATA(supplier).
        IF sy-subrc <> 0.
          message = |Supplier { requisition-SupplierID } does not exist|.
        ELSEIF supplier-IsBlocked = abap_true.
          message = |Supplier { requisition-SupplierID } is blocked|.
        ENDIF.
      ENDIF.

      IF message IS NOT INITIAL.
        APPEND VALUE #( %tky = requisition-%tky ) TO failed-purchreq.
        APPEND VALUE #( %tky                = requisition-%tky
                        %state_area         = 'VALIDATE_SUPPLIER'
                        %msg                = new_message_with_text(
                                                severity = if_abap_behv_message=>severity-error
                                                text     = message )
                        %element-SupplierID = if_abap_behv=>mk-on ) TO reported-purchreq.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDeliveryDate.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( DeliveryDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(requisitions).

    DATA(today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT requisitions INTO DATA(requisition).
      " Clear this validation's old messages for the requisition
      APPEND VALUE #( %tky        = requisition-%tky
                      %state_area = 'VALIDATE_DATE' ) TO reported-purchreq.

      IF requisition-DeliveryDate IS INITIAL OR requisition-DeliveryDate <= today.
        APPEND VALUE #( %tky = requisition-%tky ) TO failed-purchreq.
        APPEND VALUE #( %tky                  = requisition-%tky
                        %state_area           = 'VALIDATE_DATE'
                        %msg                  = new_message_with_text(
                                                  severity = if_abap_behv_message=>severity-error
                                                  text     = 'Delivery date must be in the future' )
                        %element-DeliveryDate = if_abap_behv=>mk-on ) TO reported-purchreq.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD submit.
    " The requisitions to submit, and their items (to check that there is at least one)
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( Status TotalAmount ) WITH CORRESPONDING #( keys )
        RESULT DATA(requisitions)
      ENTITY PurchReq BY \_Items
        FIELDS ( PrUUID ) WITH CORRESPONDING #( keys )
        RESULT DATA(items).

    DATA updates TYPE TABLE FOR UPDATE zoa_r_purchreqtp\\PurchReq.

    LOOP AT requisitions INTO DATA(requisition).
      DATA(message) = VALUE string( ).
      IF requisition-Status <> status-new.
        message = 'Only new requisitions can be submitted'.
      ELSEIF NOT line_exists( items[ PrUUID = requisition-PrUUID ] ).
        message = 'Add at least one item before submitting'.
      ENDIF.

      IF message IS NOT INITIAL.
        APPEND VALUE #( %tky = requisition-%tky ) TO failed-purchreq.
        APPEND VALUE #( %tky = requisition-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = message ) ) TO reported-purchreq.
      ELSE.
        " Small requisitions are approved automatically, larger ones wait for a manager
        APPEND VALUE #( %tky   = requisition-%tky
                        Status = COND #( WHEN requisition-TotalAmount < approval_limit
                                         THEN status-approved
                                         ELSE status-submitted ) ) TO updates.
      ENDIF.
    ENDLOOP.

    IF updates IS NOT INITIAL.
      MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
        ENTITY PurchReq
          UPDATE FIELDS ( Status ) WITH updates.
    ENDIF.

    " Return the updated requisitions, so the UI shows the new status
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated).

    result = VALUE #( FOR req IN updated ( %tky = req-%tky %param = req ) ).
  ENDMETHOD.

  METHOD approve.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(requisitions).

    DATA updates TYPE TABLE FOR UPDATE zoa_r_purchreqtp\\PurchReq.

    LOOP AT requisitions INTO DATA(requisition).
      IF requisition-Status = status-submitted.
        APPEND VALUE #( %tky = requisition-%tky Status = status-approved ) TO updates.
      ELSE.
        APPEND VALUE #( %tky = requisition-%tky ) TO failed-purchreq.
        APPEND VALUE #( %tky = requisition-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Only submitted requisitions can be approved' ) )
               TO reported-purchreq.
      ENDIF.
    ENDLOOP.

    IF updates IS NOT INITIAL.
      MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
        ENTITY PurchReq
          UPDATE FIELDS ( Status ) WITH updates.
    ENDIF.

    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated).

    result = VALUE #( FOR req IN updated ( %tky = req-%tky %param = req ) ).
  ENDMETHOD.

  METHOD reject.
    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(requisitions).

    DATA updates TYPE TABLE FOR UPDATE zoa_r_purchreqtp\\PurchReq.

    LOOP AT requisitions INTO DATA(requisition).
      IF requisition-Status = status-submitted.
        APPEND VALUE #( %tky = requisition-%tky Status = status-rejected ) TO updates.
      ELSE.
        APPEND VALUE #( %tky = requisition-%tky ) TO failed-purchreq.
        APPEND VALUE #( %tky = requisition-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Only submitted requisitions can be rejected' ) )
               TO reported-purchreq.
      ENDIF.
    ENDLOOP.

    IF updates IS NOT INITIAL.
      MODIFY ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
        ENTITY PurchReq
          UPDATE FIELDS ( Status ) WITH updates.
    ENDIF.

    READ ENTITIES OF zoa_r_purchreqtp IN LOCAL MODE
      ENTITY PurchReq
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(updated).

    result = VALUE #( FOR req IN updated ( %tky = req-%tky %param = req ) ).
  ENDMETHOD.

ENDCLASS.
