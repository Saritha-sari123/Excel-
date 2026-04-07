@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface entity for excel data'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZSA_EXCEL_DATA_I 
as select from zsa_excel_data
association to parent ZSA_EXCEL_USER_I  as _XLUser on $projection.EndUser =_XLUser.EndUser
                                                   and $projection.FileId = _XLUser.FileId
{
    key end_user as EndUser,
    key file_id as FileId,
    key line_id as LineId,
    key linenum as Linenum,
    po_number as PoNumber,
    po_item as PoItem,
    gr_quantity as GrQuantity,
    unit_of_measure as UnitOfMeasure,
    site_id as SiteId,
    header_text as HeaderText,
    _XLUser
}
