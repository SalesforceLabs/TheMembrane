global with sharing class StripeMutationCapsule implements MembraneMutationInterface{
    public StripeMutationCapsule() {

    }

    public Object mutateRecord(Object cartridge,sObject record,Object originalValue){

        /*
        System.debug('\n\n-------------------------- Mutation Capsule before:\n\n'+originalValue);
        originalValue = 'value 1';
        System.debug('\n\n-------------------------- Mutation Capsule after:\n\n'+originalValue);
        String multiSelectValue = String.valueOf(originalValue);
        List<String> multiSelectArray = multiSelectValue.split(';');
        multiSelectArray.add('value 2');
        return multiSelectArray;
        */

        return JSON.deserializeUntyped(String.valueOf(originalValue));
        
    }

    public Object mutateJson(Object cartridge,Map<String,Object> jsonMap,Object originalValue){

        return JSON.serialize(originalValue);
        
    }
}