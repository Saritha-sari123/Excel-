@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption entity for data'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZSA_EXCEL_DATA_C 
as projection on ZSA_EXCEL_DATA_I
{
    key EndUser,
    key FileId,
    key LineId,
    key Linenum,
    PoNumber,
    PoItem,
    GrQuantity,
    UnitOfMeasure,
    SiteId,
    HeaderText,
    /* Associations */
    _XLUser:redirected to parent ZSA_EXCEL_USER_C
}
