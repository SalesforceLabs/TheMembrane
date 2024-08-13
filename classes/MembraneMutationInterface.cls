global interface MembraneMutationInterface {

    Object mutateRecord(Object cartridge,sObject record,Object originalValue);
    Object mutateJson(Object cartridge,Map<String,Object> jsonMap,Object originalValue);
        
}