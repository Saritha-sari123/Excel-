CLASS lhc_XLHead DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR XLHead RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR XLHead RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE XLHead.

    METHODS uploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION XLHead~uploadExcelData RESULT result.

    METHODS FillFileStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR XLHead~FillFileStatus.

    METHODS FillSelectedStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR XLHead~FillSelectedStatus.

ENDCLASS.

CLASS lhc_XLHead IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name(  ).
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_entities>).
      APPEND CORRESPONDING #( <lfs_entities> ) TO mapped-xlhead
      ASSIGNING FIELD-SYMBOL(<lfs_xlhead>).
      <lfs_xlhead>-EndUser = lv_user.
      IF <lfs_xlhead>-FileId IS INITIAL.
        TRY.
            <lfs_xlhead>-FileId = cl_system_uuid=>create_uuid_x16_static(  ).
          CATCH cx_uuid_error.
            "do nothing proceed to other entry
        ENDTRY.
      ENDIF.


    ENDLOOP.


  ENDMETHOD.

  METHOD uploadExcelData.

    DATA: lt_rows         TYPE STANDARD TABLE OF string,
          lv_content      TYPE string,
          lo_table_descr  TYPE REF TO cl_abap_tabledescr,
          lo_struct_descr TYPE REF TO cl_abap_structdescr,
          lt_excel        TYPE  STANDARD TABLE OF zsa_cl_bp_xl_user=>gty_gr_xl,
          lt_data         TYPE TABLE FOR CREATE zsa_excel_user_i\_xldata,
          lv_index        TYPE sy-index.

    FIELD-SYMBOLS: <lfs_col_header> TYPE string.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name(  ).
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_entity).

    DATA(lv_attachment) = lt_file_entity[ 1 ]-Attachment.
    CHECK lv_attachment IS NOT INITIAL.

    "move the excel data to internal table
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
    iv_file_content = lv_attachment )->read_access(  ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook(  )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(  )->get_pattern(  ).
    DATA(lo_execute) = lo_worksheet->select(
    lo_selection_pattern )->row_stream(  )->operation->write_to(
    REF #( lt_excel ) ).
    lo_execute->set_value_transformation(
    xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute(  ).

    "Get the number of columns in upload file for validation
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type(  ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        "Implement error handling
    ENDTRY.


    "Validate the header record
    DATA(ls_excel) = VALUE #( lt_excel[ 1 ] OPTIONAL ).
    IF ls_excel IS NOT INITIAL.
      DO lv_no_of_cols TIMES.
        lv_index = sy-index.
        ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
        CHECK <lfs_col_header> IS ASSIGNED.
        DATA(lv_value) = to_upper( <lfs_col_header> ).
        DATA(lv_has_error) = abap_false.
        CASE lv_index.
          WHEN 1.
            lv_has_error = COND #( WHEN lv_value <> 'PO NUMBER' THEN abap_true ELSE lv_has_error ).
          WHEN 2.
            lv_has_error = COND #( WHEN lv_value <> 'PO ITEM' THEN abap_true ELSE lv_has_error ).
          WHEN 3.
            lv_has_error = COND #( WHEN lv_value <> 'GR QUANTITY ' THEN abap_true ELSE lv_has_error ).
          WHEN 4.
            lv_has_error = COND #( WHEN lv_value <> 'UNIT OF MEASURE' THEN abap_true ELSE lv_has_error ).
          WHEN 5.
            lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
          WHEN 6.
            lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
          WHEN 9.
            lv_has_error =  abap_true .
        ENDCASE.
        IF lv_has_error = abap_true.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky ) TO failed-xlhead.
          APPEND VALUE #(
            %tky = lt_file_entity[ 1 ]-%tky
            %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text =  'Wrong File Format !!' )
                    ) TO reported-xlhead.
          UNASSIGN <lfs_col_header>.
          EXIT.
        ENDIF.
        UNASSIGN <lfs_col_header>.
      ENDDO.
    ENDIF.
    CHECK lv_has_error = abap_false.

    DELETE lt_excel INDEX 1.
    DELETE lt_excel WHERE po_number IS INITIAL.
    "fill line id / line number
    TRY.
        DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static(  ).
      CATCH cx_uuid_error.
    ENDTRY.

  ENDMETHOD.

  METHOD FillFileStatus.

    "read the data to be modified
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    FIELDS ( EndUser FileStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_user).


    "update the file status
    LOOP AT lt_user INTO DATA(ls_user).
      MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLHead
      UPDATE FIELDS ( FileStatus )
      WITH VALUE #( (
       %tky = ls_user-%tky
       %data-FileStatus = 'File Not Selected'
       %control-FileStatus = if_abap_behv=>mk-on
         ) ).


    ENDLOOP.


  ENDMETHOD.

  METHOD FillSelectedStatus.

    " Delete XLDATA Existing (if any)
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead BY \_xldata
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_existing_XLData).

    IF lt_existing_xldata IS NOT INITIAL.
      MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLData DELETE FROM VALUE #(
      FOR lwa_data IN lt_existing_XLData (
      %key = lwa_data-%key
      %is_draft = lwa_data-%is_draft
      ) ).
    ENDIF.

    "read the xl_head entities and  change the file status

    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_XlHead).

    "update file status
    LOOP AT lt_xlhead INTO DATA(ls_xlhead).
      MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLHead
      UPDATE FIELDS ( FileStatus )
      WITH VALUE #( (
      %tky = ls_xlhead-%tky
      %data-FileStatus = COND #(
                            WHEN ls_xlhead-Attachment IS INITIAL
                            THEN 'File Not Selelcted'
                            ELSE 'File Selelcted' )
      %control-FileStatus = if_abap_behv=>mk-on
              ) ).

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
