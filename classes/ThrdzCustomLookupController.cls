public with sharing class ThrdzCustomLookupController {
    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupData(string searchKey , string sObjectApiName,string queryfilter) { 
        
        System.debug('\n>>>>>>>>>>>fetchLookupData:'+searchKey+':'+sObjectApiName+':'+queryfilter);
        List < sObject > returnList = new List < sObject > ();
        //sObjectApiName = 'Account';
        String fields = 'Id,Name';
        String addedFilter='';
       
        string sWildCardText = '%' + searchKey + '%';

        string sQuery = 'Select '+fields+' From ' + sObjectApiName + ' Where Name Like : sWildCardText '+queryfilter+addedFilter+ ' order by lastmodifieddate DESC LIMIT 50';
        List<SObject> records = new List<SObject>();
        records = Database.query(String.escapeSingleQuotes(sQuery));
        SObjectAccessDecision decision = Security.stripInaccessible(
                                                        AccessType.READABLE,
                                                        records
                                                    );
        records = decision.getRecords();
        for (sObject obj: records) {
            
            returnList.add(obj);
        }
        return returnList;
    }
    
    // Method to fetch lookup default value 
    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId , string sObjectApiName) {
        string sRecId = recordId;    
        string sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        
        List<SObject> records = new List<SObject>();
        records = Database.query(String.escapeSingleQuotes(sQuery));
                SObjectAccessDecision decision = Security.stripInaccessible(
                                                                AccessType.READABLE,
                                                                records
                                                            );
        records = decision.getRecords();
        for (sObject obj: records) {
            return obj;
        }
        return null;
    }
}