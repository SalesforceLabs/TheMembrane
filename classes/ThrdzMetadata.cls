public with sharing class ThrdzMetadata {
    public ThrdzMetadata() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();	
        MetadataService.CustomObject customObject = new MetadataService.CustomObject();
        customObject.fullName = 'Test__c';
        customObject.label = 'Test';
        customObject.pluralLabel = 'Tests';
        customObject.nameField = new MetadataService.CustomField();
        customObject.nameField.type_x = 'Text';
        customObject.nameField.label = 'Test Record';
        customObject.deploymentStatus = 'Deployed';
        customObject.sharingModel = 'ReadWrite';
        List<MetadataService.SaveResult> results = service.createMetadata(new List<MetadataService.Metadata> { customObject });


        List<MetadataService.CustomField> fields = new List<MetadataService.CustomField>();
        MetadataService.CustomField customField = new MetadataService.CustomField();
        String sobjectname = 'Test__c';
        customField.fullName = sobjectname+'.custom_create_field__c';
        customField.label = 'Custom created field';
        customField.defaultvalue = 'false';
        customField.type_x = 'Checkbox';
        fields.add(customField);
        service.createMetadata(fields);
        List<MetadataService.SaveResult> saveResults = service.createMetadata(fields);

        /*
        CustomField cf = new CustomField();
        cf.fullName = SFType + "." + fieldName + "__c";
        cf.type = FieldType.Lookup;
        //type specified is required to avoid FIELD_INTEGRITY_EXCEPTION: https://developer.salesforce.com/forums/ForumsMain?id=906F0000000Ad5LIAS
        cf.typeSpecified = true;
        cf.label = fieldName + " label";
        cf.referenceTo = "Opportunity";
        cf.relationshipLabel = "Test Accounts";
        cf.relationshipName = "test";
        cf.relationshipOrderSpecified = false;
        cf.lengthSpecified = false;
        */

    }
}