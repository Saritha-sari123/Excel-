CLASS zsa_cl_bp_xl_user DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zsa_excel_user_i.
  PUBLIC SECTION.
    TYPES:BEGIN OF gty_gr_xl,
            po_number       TYPE string,
            po_item         TYPE string,
            gr_quantity     TYPE string,
            unit_of_measure TYPE string,
            site_id         TYPE string,
            header_text     TYPE string,
            line_number     TYPE string, " Internal use during Upload
            line_id         TYPE string, " Internal use during Upload
          END OF gty_gr_xl.

ENDCLASS.


CLASS zsa_cl_bp_xl_user IMPLEMENTATION.
ENDCLASS.
