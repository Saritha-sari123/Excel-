@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: ' root consumption entity for user'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root  view entity ZSA_EXCEL_USER_C
  provider contract transactional_query as projection on ZSA_EXCEL_USER_I
{
    key EndUser,
    key FileId,
    FileStatus,
          @Semantics.largeObject: {
                 mimeType: 'Mimetype',
                 fileName: 'Filename',
                 acceptableMimeTypes: ['*/*'], // Using these annotation it accepts any file types( PDF/EXCEL/WORD/TEXT )
//                 acceptableMimeTypes: [
//                     'application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','text/csv' ],
                 contentDispositionPreference: #INLINE}
    Attachment,
    Mimetype,
    Filename,
    LocalCreatedBy,
    LocalCreatedAt,
    LocalLastChangedBy,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _XLData: redirected to composition child ZSA_EXCEL_DATA_C 
}
