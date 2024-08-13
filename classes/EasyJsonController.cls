public with sharing class EasyJsonController {
    public EasyJsonController() {

    }

    static String objApiName;

    @AuraEnabled
    public static List<String> getObjects(){
        List<String> objectList = new List<String>();
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
           String name = objTyp.getDescribe().getName();
           String label = objTyp.getDescribe().getLabel();
           if(!name.containsignorecase('history') && !name.containsignorecase('tag') &&
                !name.containsignorecase('share') && !name.containsignorecase('feed') && 
               	!name.containsignorecase('group') && !name.containsignorecase('public') &&
                !objTyp.getDescribe().isCustomSetting() && objTyp.getDescribe().isCreateable() &&
                objTyp.getDescribe().getRecordTypeInfos().size() > 0){      
                objectList.add(name);
           }
        }
		System.debug(objectList);
        if(objectList != null && objectList.size() > 0){
        	return objectList;   
        }else{
            return null;
        }
    }

    @AuraEnabled
    public static List<String> getFields(String selectedSObject){
        List<String> fieldList = new List<String>();
        if(selectedSObject != null && selectedSObject != ''){
            
            Map<String,SObjectField> fList = new Map<String,SObjectField>();
            fList = Schema.getGlobalDescribe().get(selectedSObject)?.getDescribe().fields.getMap();
            if(fList!=null){
                for(String str: fList.keySet()){
                    fieldList.add(selectedSObject+'.'+str);                
                }
            }
            
        }
        return fieldList;
    }

    @AuraEnabled
    public static List<String> getSobjectRecordTypes(String selectedSObject){
        List<String> rtList = new List<String>();
        if(selectedSObject != null && selectedSObject != ''){
            
            List<RecordType> recordTypes = [SELECT Id,Name,DeveloperName FROM RecordType where sObjectType=:selectedSObject WITH USER_MODE];
            if(recordTypes!=null){
                for(RecordType rt: recordTypes){
                    rtList.add(selectedSObject+'.'+rt.DeveloperName+'['+rt.Id+']');                
                }
            }
            
        }
        return rtList;
    }


    @AuraEnabled
    public static String getJSONString(String currentRecordId, String fieldapiname){
        try{

            Id recId = currentRecordId;

            String query = 'SELECT ';
            List<String> fields = new List<String>();
            fields.add('Id');
            //fieldapiname = MembrameMemory.namespaceprefix + fieldapiname;
            fields.add(fieldapiname);

            List<SObject> record = new List<SObject>();
            if(recId!=null){
                objApiName = String.valueOf(recId.getSobjectType());

                System.debug('\n\n =========== sObject type:'+objApiName);
                query = query + String.join(fields,',')+' FROM '+objApiName+' WHERE Id=:currentRecordId';
                System.debug('\n\n----- Query :'+query);
                record = Database.query(String.escapeSingleQuotes(query));
                SObjectAccessDecision decision = Security.stripInaccessible(
                                                                AccessType.READABLE,
                                                                record
                                                            );
                record = decision.getRecords();
            }
            else{
                throw new EasyJsonException('Empty record');
            }

            //String recordStr = JSON.serialize(record).replaceAll(MembrameMemory.namespaceprefix, '');
            
            return JSON.serialize(record);//recordStr;
    
            
        }catch(EasyJsonException e){
            throw new EasyJsonException('EasyJsonException:'+e.getMessage());

        }
        catch(Exception e){
            throw e;
        }
        
    }

    public class EasyJsonException extends Exception {
        
    }
}