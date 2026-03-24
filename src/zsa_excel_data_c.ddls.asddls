@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity zsa_excel_data_c as projection on ZSA_EXCEL_DATA_I
{
    key EndUser,
    key FileId,
    key LineId,
    key LineNumber,
    PoNumber,
    PoItem,
    GrQuantity,
    UnitOfMeasure,
    SiteId,
    HeaderText,
    /* Associations */
    _XLUser:redirected to parent ZSA_EXCEL_USER_C
}
