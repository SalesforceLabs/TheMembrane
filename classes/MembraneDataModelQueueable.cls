public class MembraneDataModelQueueable implements Queueable,Database.AllowsCallouts  {

    public List<Membrane_Definition__c> mds = new List<Membrane_Definition__c>();
    public String operation;
    List<MetadataService.Metadata> newObjectsList;
    List<MetadataService.CustomField> newFieldsList;
    List<MetadataService.Metadata> psList;
    List<String> psListNames;
    List<MetadataService.PermissionSetFieldPermissions> fieldSecList;
    Boolean isContinuation;

    Boolean isValidationOnly;

    Integer MAX_SIZE = 10;


    public MembraneDataModelQueueable(List<Membrane_Definition__c> mds,String operation,Boolean isValidationOnly){
        this.mds = mds;
        this.operation = operation;
        this.isContinuation = false;
        this.isValidationOnly = isValidationOnly;
    }

    public MembraneDataModelQueueable(  String operation, 
                                        List<MetadataService.Metadata> newObjectsList,
                                        List<MetadataService.CustomField> newFieldsList,
                                        List<MetadataService.Metadata> psList,
                                        Boolean isContinuation,
                                        Boolean isValidationOnly
                                    ){
        this.operation = operation;
        this.newObjectsList = newObjectsList;
        this.newFieldsList = newFieldsList;
        this.psList = psList;
        this.isContinuation = isContinuation;
        this.isValidationOnly = isValidationOnly;

        if(this.psList?.size()>0){
            for(MetadataService.Metadata ps:psList){
                this.psListNames.add(ps.fullName);
            }
        }
    }

    public void execute(QueueableContext context) {
        
        List<String> existingObjects = EasyJsonController.getObjects();
        MetadataService.PermissionSet integrationuserps = new MetadataService.PermissionSet();

        if(mds.size()>0){
            String psSuffix = mds[0].Membrane_External_Data_Source__r.Name;
            integrationuserps.fullName = psSuffix?.replaceAll(' ','_')+'_Integration_User';
            integrationuserps.label = psSuffix+' Integration User';
        }
        else{
            integrationuserps.fullName = 'The_Membrane_Integration_Permissions';
            integrationuserps.label = 'The Membrane Integration Permissions';
        }

       
        
        
        Map<String,List<String>> existingFields= new Map<String,List<String>>();

        if(!isContinuation){
            newObjectsList = new List<MetadataService.Metadata>();
            newFieldsList = new List<MetadataService.CustomField>();
            psList = new List<MetadataService.Metadata>();
            psListNames = new List<String>();
            fieldSecList = new List<MetadataService.PermissionSetFieldPermissions>();

            for(Membrane_Definition__c md: mds){
                Map<String, Object> membraneMap = (Map<String, Object>) JSON.deserializeUntyped(md.membrane__c);

                String mainsobject = String.valueOf(membraneMap.get('sobject'));
                Osmosis.DataModelAbstractionFromMembrane(newObjectsList,newFieldsList,existingObjects,existingFields,mainsobject,membraneMap,fieldSecList);

                System.debug('\n\nMS Validation Data Model:'+isValidationOnly);
                if(isValidationOnly){
                    String objectsinfo = '<p><b>Objects Info:</b></p>';
                    if(newObjectsList.size()==0){
                        objectsinfo = objectsinfo + '<p style="margin-left:10px">'+'No new objects available for creation'+'</p>';
                    }
                    for(MetadataService.Metadata objMdt:newObjectsList){
                        MetadataService.CustomObject co = (MetadataService.CustomObject)objMdt;
                        if(!objectsinfo.contains(co.fullName)){
                            objectsinfo = objectsinfo + '<p style="margin-left:10px">'+co.fullName+'</p>';
                        }
                        System.debug('\n\nMS Object Metadata'+co);
                        
                    }

                    String fieldsinfo = '<p><b>Fields Info:</b></p>';
                    if(newFieldsList.size()==0){
                        fieldsinfo = fieldsinfo + '<p style="margin-left:10px">'+'No new fields available for creation'+'</p>';
                    }
                    for(MetadataService.Metadata fieldMdt:newFieldsList){
                        MetadataService.CustomField cf = (MetadataService.CustomField)fieldMdt;
                        if(!fieldsinfo.contains(cf.fullName)){
                            fieldsinfo = fieldsinfo + '<p style="margin-left:10px">'+cf.fullName+'</p>';
                        }
                        System.debug('\n\nMS Object Metadata'+cf);
                        
                    }

                    String fieldspsinfo = '<p><b>Fields Permissions Info:</b></p>';
                    if(fieldSecList.size()==0){
                        fieldspsinfo = fieldspsinfo + '<p style="margin-left:10px">'+'No new field permissions available for creation'+'</p>';
                    }
                    for(MetadataService.PermissionSetFieldPermissions fs:fieldSecList){
                        //MetadataService.PermissionSetFieldPermissions fs = (MetadataService.PermissionSetFieldPermissions)fieldpsMdt;
                        if(!fieldspsinfo.contains(fs.field)){
                            fieldspsinfo = fieldspsinfo + '<p style="margin-left:10px">'+fs.field+'</p>';
                        }
                        System.debug('\n\nMS Fields PS Metadata'+fs);
                        
                    }

                    if(Schema.sObjectType.Membrane_Definition__c.fields.Membrane_Notes__c.isCreateable()){
                        md.Membrane_Notes__c = 
                            isContinuation? md.Membrane_Notes__c + '</br>' + objectsinfo + fieldsinfo + fieldspsinfo : objectsinfo + fieldsinfo + fieldspsinfo;
                    }
                }
                
            }

            if(isValidationOnly && mds.size()>0){
                update mds;
            }
        }

        //Fields creation chaining
        List<MetadataService.CustomField> newFieldsListSlice = new List<MetadataService.CustomField>();
        if(newFieldsList.size() > MAX_SIZE){
            
            for(Integer i = MAX_SIZE ; i < newFieldsList.size() ; i++){
                newFieldsListSlice.add(newFieldsList[i]);
            }

           
            while(newFieldsList.size() > MAX_SIZE){

                newFieldsList.remove(newFieldsList.size()-1);
            }

            System.debug('\n\n In MembraneAutomation:'+newFieldsList.size()+' =/= '+newFieldsListSlice.size());


        }

        //Object creation Chaining
        List<MetadataService.Metadata> newObjectsListSlice = new List<MetadataService.Metadata>();

        if(newObjectsList.size() > MAX_SIZE){
            for(Integer i = MAX_SIZE ; i < newObjectsList.size() ; i++){
                newObjectsListSlice.add(newObjectsList[i]);
            }

            while(newObjectsList.size() > MAX_SIZE){
                newObjectsList.remove(newObjectsList.size() - 1);
            }

            System.debug('\n\n In MembraneAutomation:'+newObjectsList.size()+' =/= '+newObjectsListSlice.size());


        }

        if(operation == 'createfields'){
            List<FieldPermissions> existingPermissions = new List<FieldPermissions>();
            List<MetadataService.Metadata> psListSlice = new List<MetadataService.Metadata>();

            if(!isValidationOnly){
                if(!isContinuation){
                    
                    //existingPermissions = [SELECT id,field, PermissionsRead, PermissionsEdit,parent.Name FROM FieldPermissions WHERE parent.Name = 'The_Membrane_Integration_User'];
                    existingPermissions = [SELECT id,field, PermissionsRead, PermissionsEdit,parent.Name FROM FieldPermissions WHERE parent.Name = :psListNames];

                    if(existingPermissions.size()>0){
                        for(FieldPermissions eps:existingPermissions){
            
                            MetadataService.PermissionSetFieldPermissions fieldSec = new MetadataService.PermissionSetFieldPermissions();
                            fieldSec.field=eps.field;
                            fieldSec.editable=eps.PermissionsEdit;
                            fieldSec.readable=eps.PermissionsRead;
                            fieldSecList.add(fieldSec);
                        }
                    }
            
                    integrationuserps.fieldPermissions  = fieldSecList;
                    psList.add(integrationuserps);
                }

                System.debug('\n\n In MembraneAutomation:'+newFieldsList.size());
                if(newFieldsList.size()>0){
                    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
                    service.SessionHeader = new MetadataService.SessionHeader_element();
                    service.SessionHeader.sessionId = UserInfo.getSessionId();
                    List<MetadataService.SaveResult> results = service.createMetadata(newFieldsList);


                    //Fields security creation/updation chaining

                    if(psList.size() > MAX_SIZE){
                        for(Integer i = MAX_SIZE ; i < psList.size() ; i++){
                            psListSlice.add(psList[i]);
                        }

                        while(psList.size() > MAX_SIZE){
                            psList.remove(psList.size() - 1);
                        }
                        System.debug('\n\n In MembraneAutomation:'+psList.size()+' =/= '+psListSlice.size());

                    }
                    
                    List<MetadataService.SaveResult> results_ps;
                    if(existingPermissions.size()>0 || (isContinuation && psList.size()>0)){
                        results_ps = service.updateMetadata(psList);
                    }
                    else{
                        results_ps = service.createMetadata(psList);
                    }

                    /*
                    if(results!=null){
                        for(MetadataService.SaveResult result:results){
                            System.debug('\n\n========================================\n\n');
                            System.debug(result);
                            System.debug('\n\n========================================\n\n');
                        }
                    }

                    if(results_ps!=null){
                        for(MetadataService.SaveResult result:results_ps){
                            System.debug('\n\nPS Results++++++++++++++++++++++++++++++++++++++++\n\n');
                            System.debug(result);
                            System.debug('\n\nPS Results++++++++++++++++++++++++++++++++++++++++\n\n');
                        }
                    }
                    */
                }
            }

            if(newFieldsListSlice.size()>0){
                
                ID jobID = System.enqueueJob(new MembraneDataModelQueueable('createfields',newObjectsList,newFieldsListSlice,psList,true,isValidationOnly));
            }

            if(psListSlice.size()>0){
                
                ID jobID = System.enqueueJob(new MembraneDataModelQueueable('createfields',newObjectsList,newFieldsListSlice,psListSlice,true,isValidationOnly));
            }
        }
        else if(operation == 'compositegraphrequest'){

            List<Membrane_Health_Check__c> healthCheckLilst = new List<Membrane_Health_Check__c>();
            for(Membrane_Definition__c md: mds){

                Membrane_Health_Check__c hc = new Membrane_Health_Check__c();
                if(Schema.sObjectType.Membrane_Health_Check__c.fields.Membrane_Definition__c.isCreateable())
                    hc.Membrane_Definition__c = md.Id;
                if(Schema.sObjectType.Membrane_Health_Check__c.fields.Membrane__c.isCreateable())
                    hc.Membrane__c = md.membrane__c;
                if(Schema.sObjectType.Membrane_Health_Check__c.fields.Sample_JSON__c.isCreateable())
                    hc.Sample_JSON__c = md.Sample_JSON__c;
                if(Schema.sObjectType.Membrane_Health_Check__c.fields.Composite_Graph_Request__c.isCreateable())
                    hc.Composite_Graph_Request__c = JSON.serializepretty(Osmosis.generateCompositeGraph(md.Sample_JSON__c,md.membrane__c));
                String baseURL = URL.getOrgDomainURL().toExternalForm(); 
                String compositeGraphURL = baseURL + '/services/data/v58.0/composite/graph/';  
                
                HttpRequest httpRequest = new HttpRequest();  
                httpRequest.setMethod('POST');   
                httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());        
                httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
                httpRequest.setHeader('Content-Type', 'application/json');
                
                String body = hc.Composite_Graph_Request__c;

                httpRequest.setBody(body);  
                httpRequest.setEndpoint(compositeGraphURL);  
                String prettyResponse = '';
                try {  
                    Http http = new Http();   
                    HttpResponse response = http.send(httpRequest);  
                    if (response.getStatusCode() == 200 ) {  
                        prettyResponse = JSON.serializePretty( JSON.deserializeUntyped(response.getBody()) );  
                    } else {  
                        System.debug(' response ' + response.getBody() );  
                        throw new CalloutException( response.getBody() );  
                    }   
                } catch( System.Exception e) {  
                    System.debug('ERROR: '+ e);  
                    throw e;  
                }  
    
                if(Schema.sObjectType.Membrane_Health_Check__c.fields.Composite_Graph_Result__c.isCreateable()){
                    hc.Composite_Graph_Result__c = prettyResponse;
                    healthCheckLilst.add(hc);
                }
   
            }

            SObjectAccessDecision decision = Security.stripInaccessible(
                                                                AccessType.READABLE,
                                                                healthCheckLilst
                                                            );
            healthCheckLilst = decision.getRecords();
            if(healthCheckLilst.size()>0){
                Database.SaveResult[] results = Database.insert(healthCheckLilst,AccessLevel.USER_MODE);
            }

        }
        else if(operation == 'createobject'){

            if(!isValidationOnly){
                if(newObjectsList.size()>0){
                    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
                    service.SessionHeader = new MetadataService.SessionHeader_element();
                    service.SessionHeader.sessionId = UserInfo.getSessionId();
                    List<MetadataService.SaveResult> results = service.createMetadata(newObjectsList);
                }
            }


            if(newObjectsListSlice.size()>0){
                ID jobID = System.enqueueJob(new MembraneDataModelQueueable('createobject',newObjectsListSlice,newFieldsList,psList,true,isValidationOnly));
            }
        }
        else{
            //Invalid Operation TODO
        }
        
              
    }
}