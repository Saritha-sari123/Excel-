@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
serviceQuality: #X,
sizeCategory: #S,
dataClass: #MIXED
}
define view entity ZSA_EXCEL_DATA_I as select from ZSA_EXCEL_DATA

association to parent ZSA_EXCEL_USER_I as _XLUser on $projection.EndUser = _XLUser.Enduser
                                                 and $projection.FileId = _XLUser.FileId 

{
    key end_user as EndUser,
    key file_id as FileId,
    key line_id as LineId,
    key line_no as LineNumber,
    po_number as PoNumber,
    po_item as PoItem,
    gr_quantity as GrQuantity,
    unit_of_measure as UnitOfMeasure,
    site_id as SiteId,
    header_text as HeaderText,
    
    
    _XLUser
}
