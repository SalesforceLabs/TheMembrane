public with sharing class MembraneHealthCheckAutomation {
    public MembraneHealthCheckAutomation() {

    }
    
    @InvocableMethod(label='Healthcheck Automation' description='')
    public static List<MembraneResult> updateHealthCheck(List<MembraneRequest> requestList){

        List<MembraneResult> resultList = new List<MembraneResult>();
        for(MembraneRequest request:requestList){
            resultList.add(updateHealthCheck(request));
        }

        return resultList;
   
    }

    static MembraneResult updateHealthCheck(MembraneRequest request){

        MembraneResult result = new MembraneResult();
        String healthcheckId = '';
        Boolean isGenerateJson=false;


        try{

            healthcheckId = request.healthcheckId;
            isGenerateJson = request.generateJson==null?false:request.generateJson;
            
            List<Membrane_Health_Check__c> hcs = [  SELECT  Id,
                                                            membrane__c,
                                                            sample_json__c,
                                                            generated_json__c,
                                                            record_id__c,
                                                            Schema_Check_Status__c
                                                            FROM Membrane_Health_Check__c 
                                                            WHERE Id =:healthcheckId
                                                            WITH USER_MODE
                                                ];

            if(isGenerateJson){
                for(Membrane_Health_Check__c hc: hcs){
                    Map<String, Object> generatedJson = Osmosis.generateJson(hc.record_id__c,hc.membrane__c);
                    hc.generated_json__c = JSON.serialize(generatedJson);
                    MyJson mySampleJson  = new MyJson(hc.sample_json__c,true);
                    MyJson myGeneratedJson = new MyJson(hc.generated_json__c,true);
                    Boolean fuzzycheck = (mySampleJson == myGeneratedJson);

                    mySampleJson.fuzzy = false;
                    myGeneratedJson.fuzzy = false;
                    Boolean strictcheck = (mySampleJson == myGeneratedJson);

                    if(fuzzycheck && strictcheck){
                        hc.Schema_Check_Status__c = 'Strict Pass';
                    }
                    else if(fuzzycheck){
                        hc.Schema_Check_Status__c = 'Fuzzy Pass';
                    }
                    else{
                        hc.Schema_Check_Status__c = 'Failed';
                    }

                }
                Database.SaveResult[] results = Database.update(hcs);
                result.healthcheckId = healthcheckId;
                result.success = true;
                result.message = 'Healthcheck updated successfully';

            }

            return result;
            
        }
        catch(Exception e){
            result.healthcheckId = healthcheckId;
            result.success = false;
            result.message = e.getMessage()+e.getStackTraceString();
            return result;
        }
        

    }
    
    
    public class MembraneRequest{
        
        @InvocableVariable
        public String healthcheckId;

        @InvocableVariable
        public Boolean generateJson;
        
    }
    
    public class MembraneResult{
        @InvocableVariable
        public String healthcheckId;
        
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }
}