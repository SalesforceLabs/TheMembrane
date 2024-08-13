public with sharing class MembraneAutomation {
    public MembraneAutomation() {

    }
    
    @InvocableMethod(label='Generate Membrane Metadata' description='')
    public static List<MembraneResult> createMembraneMetadata(List<MembraneRequest> requestList){

        List<MembraneResult> resultList = new List<MembraneResult>();
        for(MembraneRequest request:requestList){
            resultList.add(createMembraneMetadata(request));
        }

        return resultList;
   
    }

    static MembraneResult createMembraneMetadata(MembraneRequest request){

        MembraneResult result = new MembraneResult();
        String membraneDefinitionId = '';
        Boolean isCreateMembrane = false;
        Boolean isCreateDataModel = false;
        Boolean isCreateFields = false;
        Boolean isHealthCheck = false;
        Boolean isValidationOnly = false;


        try{

            membraneDefinitionId = request.membraneDefinitionId;
            isCreateMembrane = request.createMembrane==null?false:request.createMembrane;
            isCreateDataModel = request.createDataModel==null?false:request.createDataModel;
            isCreateFields = request.createFields==null?false:request.createFields;
            isHealthCheck = request.healthCheck==null?false:request.healthCheck;
            isValidationOnly = request.validationOnly==null?false:request.validationOnly;


            List<Membrane_Definition__c> mds = [SELECT 
                                                    Id,
                                                    membrane__c,
                                                    Sample_JSON__c,
                                                    Membrane_Notes__c,
                                                    Membrane_External_Data_Source__r.Name,
                                                    Membrane_External_Data_Source__r.Unique_Prefix__c,
                                                    Main_Object__c
                                                FROM 
                                                    Membrane_Definition__c 
                                                WHERE 
                                                    Id =:membraneDefinitionId
                                                WITH USER_MODE
                                                ];

            if(isHealthCheck){

                ID jobID = System.enqueueJob(new MembraneDataModelQueueable(mds,'compositegraphrequest',false));
                result.membraneDefinitionId = membraneDefinitionId;
                result.success = true;
                result.message = 'Healthcheck queued. For status execute:AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors FROM AsyncApexJob WHERE Id=\''+jobID+'\'];';

            }

            if(isCreateMembrane){
                for(Membrane_Definition__c md: mds){
                    String uniquePrefix = md.Membrane_External_Data_Source__r.Unique_Prefix__c;
                    if(uniquePrefix!=null && uniquePrefix!=''){
                        MembrameMemory.mxo = uniquePrefix+'o_';
                        MembrameMemory.mxf = uniquePrefix+'f_';

                    }

                    if(md.Main_Object__c!=null && md.Main_Object__c!=''){
                        MembrameMemory.mainObjLabel = md.Main_Object__c.toLowerCase().replaceAll('__c','').replaceAll('_',' ');
                    }
                    Map<String, Object> membrane = Osmosis.generateMembrane(md.Sample_Json__c,md.membrane__c);
                    if(Schema.sObjectType.Membrane_Health_Check__c.fields.Composite_Graph_Result__c.isCreateable()){
                        md.membrane__c = JSON.serializepretty(membrane);
                    }
                }
                
                SObjectAccessDecision decision = Security.stripInaccessible(
                                                                AccessType.READABLE,
                                                                mds
                                                            );
                mds = decision.getRecords();

                if(mds.size()>0){
                    Database.SaveResult[] results = Database.update(mds);
                    result.membraneDefinitionId = membraneDefinitionId;
                    result.success = true;
                    result.message = 'Membrane Created successfully';
                }
                else{
                    result.membraneDefinitionId = membraneDefinitionId;
                    result.success = false;
                    result.message = 'Membrane creation failed';
                }

            }

            if(isCreateDataModel){
                ID jobID = System.enqueueJob(new MembraneDataModelQueueable(mds,'createobject',isValidationOnly));
                result.membraneDefinitionId = membraneDefinitionId;
                result.success = true;
                result.message = 'Data Model creation queued. For status execute:AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors FROM AsyncApexJob WHERE Id=\''+jobID+'\'];';
                
            }

            if(isCreateFields){
                ID jobID = System.enqueueJob(new MembraneDataModelQueueable(mds,'createfields',isValidationOnly));
                result.membraneDefinitionId = membraneDefinitionId;
                result.success = true;
                result.message = 'Fields creation queued. For status execute:AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors FROM AsyncApexJob WHERE Id=\''+jobID+'\'];';
                
            }

            return result;
            
        }
        catch(Exception e){
            result.membraneDefinitionId = membraneDefinitionId;
            result.success = false;
            result.message = e.getMessage()+e.getStackTraceString();
            return result;
        }
        

    }
    
    
    public class MembraneRequest{
        
        @InvocableVariable
        public String membraneDefinitionId;

        @InvocableVariable
        public Boolean createMembrane;
        
        @InvocableVariable
        public Boolean  createDataModel;

        @InvocableVariable
        public Boolean  createFields;

        @InvocableVariable
        public Boolean  healthCheck;

        @InvocableVariable
        public Boolean  validationOnly;
    }
    
    public class MembraneResult{
        @InvocableVariable
        public String membraneDefinitionId;
        
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }
}