@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
serviceQuality: #X,
sizeCategory: #S,
dataClass: #MIXED
}
define root view entity ZSA_EXCEL_USER_I
 as select from zsa_excel_user
composition[0..*] of ZSA_EXCEL_DATA_I as _XLDATA
{
    key end_user as EndUser,
    key file_id as FileId,
    file_status as FileStatus,
    attachment as Attachment,
    @Semantics.mimeType: true
    mimetype as Mimetype,
    filename as Filename,
    @Semantics.user.createdBy: true
    local_created_by as LocalCreatedBy,
    @Semantics.systemDateTime.createdAt: true
    local_created_at as LocalCreatedAt,
    @Semantics.user.localInstanceLastChangedBy: true
    local_last_changed_by as LocalLastChangedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    local_last_changed_at as LocalLastChangedAt,
    @Semantics.systemDateTime.lastChangedAt: true
    last_changed_at as LastChangedAt,
    
    
    _XLDATA
}
