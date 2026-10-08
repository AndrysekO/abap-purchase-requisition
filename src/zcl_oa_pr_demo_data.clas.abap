CLASS zcl_oa_pr_demo_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.


CLASS zcl_oa_pr_demo_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA suppliers TYPE STANDARD TABLE OF zoa_supplier WITH EMPTY KEY.

    " The client field is filled automatically by ABAP SQL, so we leave it out
    suppliers = VALUE #(
      ( supplier_id = 'S0001' name = 'Moravia Office Supplies s.r.o.' city = 'Brno'    country = 'CZ' blocked = abap_false )
      ( supplier_id = 'S0002' name = 'Brno Tech Distribution a.s.'    city = 'Brno'    country = 'CZ' blocked = abap_false )
      ( supplier_id = 'S0003' name = 'Vltava IT Hardware s.r.o.'      city = 'Praha'   country = 'CZ' blocked = abap_false )
      ( supplier_id = 'S0004' name = 'Nábytek Ostrava s.r.o.'         city = 'Ostrava' country = 'CZ' blocked = abap_false )
      ( supplier_id = 'S0005' name = 'Donau Industrial Supply GmbH'   city = 'Wien'    country = 'AT' blocked = abap_false )
      ( supplier_id = 'S0006' name = 'Old Partner Trading s.r.o.'     city = 'Olomouc' country = 'CZ' blocked = abap_true ) ).

    " Start from a clean state, then insert the demo set
    DELETE FROM zoa_supplier.
    INSERT zoa_supplier FROM TABLE @suppliers.

    out->write( |{ lines( suppliers ) } suppliers inserted, 1 of them blocked (S0006).| ).
  ENDMETHOD.

ENDCLASS.
