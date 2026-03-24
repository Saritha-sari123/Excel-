@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZSA_EXCEL_USER_C
  provider contract transactional_query 
  as projection on ZSA_EXCEL_USER_I
{
    key EndUser,
    key FileId,
    FileStatus,
    @Semantics.largeObject:
    {
    mimeType: 'Mimetype',
    fileName: 'Filename',
    acceptableMimeTypes: [ 'application/vnd.ms-excel','application/vnd.openxmlformats-office.doucument.spreadsheetml.sheet' ],
    contentDispositionPreference: #INLINE }
    Attachment,
    Mimetype,
    Filename,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _XLDATA: redirected to composition child zsa_excel_data_c
}
