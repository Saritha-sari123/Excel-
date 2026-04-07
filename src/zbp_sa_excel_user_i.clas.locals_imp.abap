CLASS lhc_XLHead DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR XLHead RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR XLHead RESULT result.
    METHODS UploadExcelData FOR MODIFY
      IMPORTING keys FOR ACTION XLHead~UploadExcelData RESULT result.
    METHODS FillFileStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR XLHead~FillFileStatus.
    METHODS FillSelectedStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR XLHead~FillSelectedStatus.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE XLHead.

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
      IF <lfs_xlhead>-FileId IS  INITIAL.
        TRY.

            <lfs_xlhead>-FileId = cl_system_uuid=>create_uuid_x16_static(  ).
          CATCH cx_uuid_error.
        ENDTRY.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD UploadExcelData.
    TYPES:BEGIN OF gty_gr_xl,
            po_number       TYPE string,
            po_item         TYPE string,
            gr_quantity     TYPE string,
            unit_of_measure TYPE string,
            site_id         TYPE string,
            header_text     TYPE string,
            linenum         TYPE string,
            line_id         TYPE string,
          END OF gty_GR_XL.

    DATA : lt_rows         TYPE STANDARD TABLE OF string,
           lv_content      TYPE string,
           lo_table_descr  TYPE REF TO cl_abap_tabledescr,
           lo_struct_descr TYPE REF TO cl_abap_structdescr,
           lt_excel        TYPE STANDARD TABLE OF gty_gr_xl,
           lt_data         TYPE TABLE FOR CREATE zsa_excel_user_i\_XLData,
           lv_index        TYPE sy-index.

    FIELD-SYMBOLS:<lfs_col_header> TYPE string.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name(  ).

    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_entity).

    DATA(lv_attachment) = lt_file_entity[ 1 ]-attachment.
    CHECK lv_attachment IS NOT INITIAL.


    "move excel data to internal table
    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content(
    iv_file_content = lv_attachment )->read_access(  ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook(  )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) =
    xco_cp_xlsx_selection=>pattern_builder->simple_from_to(  )->get_pattern(  ).

    DATA(lo_execute) = lo_worksheet->select( lo_selection_pattern )->row_stream(  )->operation->write_to( REF #( lt_excel ) ).
    lo_execute->set_value_transformation(
                xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute(  ).

    "get the number of columns in upload file for validation
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type(  ).
        DATA(lv_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        " Implement error handling
    ENDTRY.

    " Validate the header record
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
            lv_has_error = COND #( WHEN lv_value <> 'GR QUANTITY' THEN abap_true ELSE lv_has_error ).
          WHEN 4.
            lv_has_error = COND #( WHEN lv_value <> 'UNIT OF MEASURE' THEN abap_true ELSE lv_has_error ).
          WHEN 5.
            lv_has_error = COND #( WHEN lv_value <> 'SITE ID' THEN abap_true ELSE lv_has_error ).
          WHEN 6.
            lv_has_error = COND #( WHEN lv_value <> 'HEADER TEXT' THEN abap_true ELSE lv_has_error ).
          WHEN 9.
            lv_has_error = ABap_true.
        ENDCASE.
        IF lv_has_error = abap_true.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky ) TO failed-xlhead.
          APPEND VALUE #(
          %tky =  lt_file_entity[ 1 ]-%tky
          %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Worng File Format!!' )
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


    " fill Line Id / Line Number
    TRY.
        DATA(lv_line_id) = cl_system_uuid=>create_uuid_x16_static(  ).
      CATCH cx_uuid_error.

    ENDTRY.

    LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<lfs_excel>).
      <lfs_excel>-line_id = lv_line_id.
      <lfs_excel>-linenum = sy-tabix.
    ENDLOOP.


*    LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<lfs_excel>).
*
*      TRY.
*          <lfs_excel>-line_id = cl_system_uuid=>create_uuid_x16_static( ).
*        CATCH cx_uuid_error.
*      ENDTRY.
*
*      <lfs_excel>-linenum = sy-tabix.
*
*    ENDLOOP.
    " Preparing data for child entity(XLData)
    lt_data = VALUE #(
    (      %cid_ref = keys[ 1 ]-%cid_ref
           %is_draft = keys[ 1 ]-%is_draft
           EndUser = keys[ 1 ]-EndUser
           FileId = keys[ 1 ]-FileId
           %target = VALUE #(
           FOR lwa_excel  IN lt_excel INDEX INTO lv_index1  (
               %cid = |CID{ lv_index1 }|
               %is_draft = keys[ 1 ]-%is_draft
               %data = VALUE #(
                   EndUser = keys[ 1 ]-EndUser
                   FileId = keys[ 1 ]-FileId
                   LineId = lwa_excel-line_id
                   Linenum = lwa_excel-linenum
                   PoNumber = lwa_excel-po_number
                   PoItem = lwa_excel-po_item
                   GrQuantity = lwa_excel-gr_quantity
                   UnitOfMeasure = lwa_excel-unit_of_measure
                   SiteId = lwa_excel-site_id
                   HeaderText = lwa_excel-header_text
                   )
                   %control = VALUE #(
                   EndUser = if_abap_behv=>mk-on
                   FileId = if_abap_behv=>mk-on
                   LineId = if_abap_behv=>mk-on
                   Linenum = if_abap_behv=>mk-on
                   PoNumber = if_abap_behv=>mk-on
                   PoItem = if_abap_behv=>mk-on
                   GrQuantity = if_abap_behv=>mk-on
                   UnitOfMeasure = if_abap_behv=>mk-on
                   SiteId = if_abap_behv=>mk-on
                   HeaderText = if_abap_behv=>mk-on
                   )
                )
                )
                )
                ).



    "Delete Existing Entry if any
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLHead BY \_XLData
      ALL FIELDS WITH CORRESPONDING #( keys  )
      RESULT DATA(lt_existing_XLData).

    IF lt_existing_XLData IS NOT INITIAL.
      MODIFY ENTITIES OF  zsa_excel_user_i IN LOCAL MODE
      ENTITY XLData DELETE FROM VALUE #(
      FOR lwa_data IN lt_existing_XLData (
       %key = lwa_data-%key
       %is_draft = lwa_data-%is_draft
       )

     )
MAPPED DATA(lt_mapped)
REPORTED DATA(lt_reported)
FAILED DATA(lt_del_failed).
    ENDIF.

    "adding new entry for XLData
    MODIFY ENTITIES OF  zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead CREATE BY \_XLData
    AUTO FILL CID WITH lt_data
    MAPPED DATA(lt_map)
    REPORTED DATA(lt_report)
    FAILED DATA(lt_failed).


    " Modify Status
    MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    UPDATE FROM VALUE #( (
    %tky =  lt_file_entity[ 1 ]-%tky
    FileStatus = 'File Uploaded'
    %control-FileStatus = if_abap_behv=>mk-on ) )
    MAPPED DATA(lt_upd_mapped)
    FAILED DATA(lt_upd_failed)
    REPORTED DATA(lt_upd_reported).


    "read the updated entry
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_updated_XLHead).
    "send the status to front end
    resUlt = VALUE #(
    FOR lwa_upd_head IN lt_updated_XLHead (
    %tky = lwa_upd_head-%tky
    %param = lwa_upd_head ) ).







  ENDMETHOD.

  METHOD FillFileStatus.
    DATA: lv_time TYPE timestampl.
    GET TIME STAMP FIELD lv_time.

    "read the data to be modified
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    ALL FIELDS WITH
     CORRESPONDING #( keys  )
    RESULT DATA(lt_user).

    "Update the File status
    LOOP AT lt_user INTO DATA(ls_user).
      MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLHead
      UPDATE FIELDS ( FileStatus LocalLastChangedBy LastChangedAt  )
      WITH VALUE #(  (
                  %tky = ls_user-%tky
                  %data-FileStatus = 'File not Selected'
                  %data-LocalLastChangedBy  = cl_abap_context_info=>get_user_technical_name( )
                  %data-LastChangedAt  = lv_time
                  %control-FileStatus = if_abap_behv=>mk-on
                  %control-LocalLastChangedBy = if_abap_behv=>mk-on
                  %control-LastChangedAt = if_abap_behv=>mk-on

                   ) ) .
    ENDLOOP.

  ENDMETHOD.

  METHOD FillSelectedStatus.
    DATA: lv_time TYPE timestampl.
    GET TIME STAMP FIELD lv_time.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).


    "delete XLData existing if any
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead BY \_XLData
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_exisiting_XLData).


    IF  lt_exisiting_XLData IS NOT INITIAL.
      MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLData
      DELETE FROM VALUE #(
      FOR lwa_data IN lt_exisiting_XLData (
            %key = lwa_data-%key
            %is_draft = lwa_data-%is_draft       ) ).

    ENDIF.

    "Read XL_Head entities and change the  file status
    READ ENTITIES OF zsa_excel_user_i IN LOCAL MODE
    ENTITY XLHead
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_xlhead).

    " update the file status

    LOOP AT lt_xlhead INTO DATA(ls_xlhead).

      MODIFY ENTITIES OF zsa_excel_user_i IN LOCAL MODE
      ENTITY XLHead
      UPDATE FIELDS ( FileStatus LocalLastChangedBy LastChangedAt  )
      WITH VALUE #( (
      %tky = ls_xlhead-%tky
      %data-FileStatus = COND #(
      WHEN ls_xlhead-Attachment IS INITIAL
      THEN 'File Not Selelcted'
      ELSE 'File Selected' )
       %data-LocalLastChangedBy  = cl_abap_context_info=>get_user_technical_name( )
       %data-LastChangedAt  = lv_time
       %control-FileStatus = if_abap_behv=>mk-on
       %control-LocalLastChangedBy = if_abap_behv=>mk-on

       %control-LastChangedAt = if_abap_behv=>mk-on

       ) ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
