/** TODO
 * Conditional Keying. E.g., Dont send Null keys / Empty Keys - Booelan Engine? 
 **/

//Nested Child records design change

public with sharing class Osmosis {
    public Osmosis() {

    }

    public enum DIRECTION  {INBOUND,OUBOUND}

    public static Boolean letTriggerRun = true;

    static Map<String,Integer> sobjectCountMap = new Map<String,Integer>();

    public static Map<String,Object> getMainMembrane(Map<String,Object> membraneMap){
        return (Map<String,Object>)membraneMap.get('membrane');
    }

    static String getValueType(Object value){
        
        if(value instanceof Map<String,Object>){
            return 'object';
        }
        else if(value instanceof Integer){
            return 'number';
        }
        else if(value instanceof Decimal){
            return 'float';
        }
        else if(value instanceof List<Object>){
            return 'array';
        }
        else if(value instanceof Boolean){
            return 'boolean';
        }
        else if(value instanceof String){
            return 'text';
        }
        else {		  
            return 'empty';
        }  
    }

    static String fieldTypeFromCartridge(String cartridgeType){
        
        if(cartridgeType == 'number'){
            return 'Number';
        }
        else if(cartridgeType == 'float'){
            return 'Number';
        }
        else if(cartridgeType == 'boolean'){
            return 'Checkbox';
        }
        else if(cartridgeType == 'text'){
            return 'Text';
        }
        else{		  
            return '';
        }  
    }

    /** =================================================================================================================== */

    static Integer incrementAndGetSobjectCount(String sobjectname){
        if(sobjectCountMap.containsKey(sobjectname)){
            
            sobjectCountMap.put(sobjectname,sobjectCountMap.get(sobjectname)+1);
        }
        else{
            sobjectCountMap.put(sobjectname,1);
        }

        return sobjectCountMap.get(sobjectname);
    }

    public static String generateRandomString() {
        Integer len = 5;
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }
    

    static CompositeGraphWrapper.cls_compositeRequest generateCompositeRequest( Map<String, Object> membrane,
                                                                                Map<String,Object> body,
                                                                                Map<String, Object> sampleJson,
                                                                                String relationType,
                                                                                CompositeGraphWrapper.cls_compositeRequest parentCompositeReq
                                                                                ){

        System.debug('++++++++ cartridge:'+membrane);
        String sobjectname = String.valueOf(membrane.get('sobject'));
        String externalidfield = String.valueOf(membrane.get('externalidfield'));
        if(externalidfield?.contains('.')){
            externalidfield = externalidfield.substring(externalidfield.indexOf('.')+1,externalidfield.length());
        }
        String externalsourcepk = String.valueOf(membrane.get('externalsourcepk'));
        String url = '/services/data/v58.0/sobjects/'+sobjectname+'/'; //TODO
        String externalid = String.valueOf(sampleJson.get(externalsourcepk));
        
        
        String referenceId = sobjectname+'_'+incrementAndGetSobjectCount(sobjectname);


        if(membrane.containsKey('lookupfield')){
            String lookupfield = String.valueOf(membrane.get('lookupfield'));

            System.debug('++++++++ CG lookupfield:'+lookupfield+':'+relationType);

            if(lookupfield!='' && lookupfield.contains('.')){
                String lookupfieldapi = lookupfield.substring(lookupfield.indexOf('.')+1,lookupfield.length());
                if(relationType == 'child'){
                    body.put(lookupfieldapi,'@{'+parentCompositeReq.referenceId+'.id}');
                }
                else{
                    parentCompositeReq.body.put(lookupfieldapi,'@{'+referenceId+'.id}');
                }
            }

        }

        Map<String,Object> sobjectdefinition = (Map<String,Object>)membrane.get('sobjectdefinition');
        String defaultrecordtype = String.valueOf(sobjectdefinition.get('defaultrecordtype'));
        if(defaultrecordtype!=''){
            String rtid = defaultrecordtype.substring(defaultrecordtype.indexOf('[')+1,defaultrecordtype.indexOf(']'));
            body.put('recordtypeid',rtid);
        }

        String namefieldtype =  String.valueOf(sobjectdefinition.get('namefieldtype'));
        if(namefieldtype == 'Text'){
            body.put('Name',String.valueOf(generateRandomString()));
        }
        
        String method = 'POST'; //TODO - Get it from Cache layer or RESTContext

        System.debug('\n\n ============  External Field Check for CG ============= \n\n'+ externalidfield + '\n' + externalid +'\n\n=================\n\n');

        if(externalidfield!=null && externalid!=null){
            url += externalidfield+'/'+externalid;
            method = 'PATCH';
        }

        CompositeGraphWrapper.cls_compositeRequest cr = new CompositeGraphWrapper.cls_compositeRequest(url,body,method,referenceId);
        return cr;
    }
    
    class CompReqNode{

        CompositeGraphWrapper.cls_compositeRequest cr;
        CompReqNode nextCr;
        CompReqNode previousCr;

        public CompReqNode(CompositeGraphWrapper.cls_compositeRequest cr){
            this.cr = cr;
        }
        
        public void insertBefore(CompReqNode refCr){
            
            this.previousCr = refCr.previousCr;

            if(refCr.previousCr!=null)
                refCr.previousCr.nextCr = this;
            
            refCr.previousCr = this;

            this.nextCr = refCr;
        }

        public void insertAfter(CompReqNode refCr){
            
            if(refCr.nextCr!=null)
                refCr.nextCr.previousCr = this;
            
            this.nextCr = refCr.nextCr;

            this.previousCr = refCr;
            
            refCr.nextCr = this;
        }

        public List<CompositeGraphWrapper.cls_compositeRequest> getOrderedList(){
            List<CompositeGraphWrapper.cls_compositeRequest>  crList = new List<CompositeGraphWrapper.cls_compositeRequest>();
            CompReqNode runningCr = this;

            while(runningCr.previousCr!=null){
                runningCr = runningCr.previousCr;
            }

            while(runningCr!=null){
                crList.add(runningCr.cr);
                runningCr = runningCr.nextCr;
            }
            return crList;
        }

    }

    public static CompositeGraphWrapper generateCompositeGraph(String sampleJsonString, String membraneJsonString){


        Map<String, Object> membraneMap = (Map<String, Object>) JSON.deserializeUntyped(membraneJsonString);
        Map<String, Object> sampleJson = (Map<String, Object>) JSON.deserializeUntyped(sampleJsonString);


        System.debug('\n\n ============  Composite Graph with membrane ============= \n\n'+ JSON.serializePretty(membraneMap)+'\n\n=================\n\n');
        System.debug('\n\n ============  Sample JSON ============= \n\n'+ JSON.serializePretty(sampleJson)+'\n\n=================\n\n');

        CompositeGraphWrapper recordsGraph = new CompositeGraphWrapper();
        CompositeGraphWrapper.cls_graph graph = new CompositeGraphWrapper.cls_graph();
        recordsGraph.graphs.add(graph);

        Map<String, Object> membrane = getMainMembrane(membraneMap);
        Map<String,Object> body = new Map<String,Object>();

        CompositeGraphWrapper.cls_compositeRequest mainSobjectCompositeReq = generateCompositeRequest(membraneMap,body,sampleJson,'',null);

        CompReqNode rootCompReqNode = new CompReqNode(mainSobjectCompositeReq);
        //CompReqNode - graph.compositeRequest.add(mainSobjectCompositeReq);

        buildCompositeGraph(sampleJson,graph,body,membrane,rootCompReqNode);

        graph.compositeRequest.addAll(rootCompReqNode.getOrderedList());

        System.debug('\n\n --------- Final Graph ----------\n\n'+JSON.serializePretty(recordsGraph)+'\n\n---------------------\n\n');

        return recordsGraph;
    }

    static void buildCompositeGraph(    Map<String, Object> sampleJson, 
                                        CompositeGraphWrapper.cls_graph recordsGraph, 
                                        Map<String,Object> body, 
                                        Map<String, Object> membrane,
                                        CompReqNode parentCompeReqNode){
       
        System.debug('\n\n ============ Building Composite Graph with membrane ============= \n\n'+ JSON.serializePretty(membrane)+'\n\n=================\n\n');


        if(sampleJson==null) return;
        
        for(String key:membrane.keyset()){
            

            Map<String,Object> cartridge = (Map<String,Object>)membrane.get(key);

            Boolean readonly = Boolean.valueOf(cartridge.get('readonly'));
            if(readonly)continue;

            String cartridgetype = String.valueOf(cartridge.get('cartridgetype'));
            System.debug('+++++ cartridgetype for '+key+' is:'+cartridgetype);
            //-- CG System.debug('+++++ notafield:'+cartridge.get('notafield'));

            //--CG Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));

            //external key subjson in recursion change 07/24
            if(cartridgetype=='object'){

                //if(!readonly){
                    //CG-- String relationship;
                    Map<String,Object> rhsObject = (Map<String,Object>)sampleJson.get(key);
                    if(cartridge.get('relationship')!=null && cartridge.get('relationship')!=''){
                        //CG -- relationship = String.valueOf(cartridge.get('relationship'));
                        System.debug('+++++ building body for relationship:'+cartridge.get('relationship'));
                        
                        Map<String,Object> newbody = new  Map<String,Object>();

                        /*
                        CompositeGraphWrapper.cls_compositeRequest cr = new CompositeGraphWrapper.cls_compositeRequest(url,newbody,method,referenceId);
                        */
                        CompositeGraphWrapper.cls_compositeRequest sobjectCompositeReq = generateCompositeRequest(cartridge,newbody,rhsObject,'lookup',parentCompeReqNode.cr);
                        CompReqNode newCompReqNode = new CompReqNode(sobjectCompositeReq);

                        newCompReqNode.insertBefore(parentCompeReqNode);
                        //CompReqNode - recordsGraph.compositeRequest.add(sobjectCompositeReq);

                        System.debug('\n\n --------- Compo Node for 3:'+ key +' ----------\n\n'+newCompReqNode+'\n\n---------------------\n\n');

                        
                        buildCompositeGraph(rhsObject,recordsGraph,newbody,(Map<String,Object>)cartridge.get('membrane'),newCompReqNode);
                    }
                    else{
                        buildCompositeGraph(rhsObject,recordsGraph,body,(Map<String,Object>)cartridge.get('membrane'),parentCompeReqNode);
                    }
                /*    
                }
                else{
                    //TODO
                }
                */
            }
            else if(cartridgetype=='array'){
                String relationship;
                
                if(cartridge.get('relationship')!=null /*&& !notafield*/){
                    relationship = String.valueOf(cartridge.get('relationship'));
                    
                }
                else{
                    relationship = '';
                }
                
                if(relationship!=''){
                    
                    List<Object> children = new List<Object>();
                    children = (List<Object>)sampleJson.get(key);
                    System.debug('CG Children ----------- '+children);
                    if(children!=null){
                        for (Object child : children)
                        {
                            
                            Map<String,Object> childObjectMap = (Map<String,Object>)child;
                            Map<String,Object> childBody = new Map<String,Object>();
                            /*
                            CompositeGraphWrapper.cls_compositeRequest cr = new CompositeGraphWrapper.cls_compositeRequest(url,childBody,method,referenceId);
                            */
                            CompositeGraphWrapper.cls_compositeRequest sobjectCompositeReq = generateCompositeRequest(cartridge,childBody,sampleJson,'child',parentCompeReqNode.cr);
                            CompReqNode newCompReqNode = new CompReqNode(sobjectCompositeReq);
                            newCompReqNode.insertAfter(parentCompeReqNode);
                            //CompReqNode - recordsGraph.compositeRequest.add(sobjectCompositeReq);

                            buildCompositeGraph((Map<String,Object>)child,recordsGraph,childBody,(Map<String,Object>)cartridge.get('membrane'),newCompReqNode);
                        }
                    }
                    
                }
                else{
                    //buildJson(relationship,sampleJson,rhsArray,(Map<String,Object>)cartridge.get('membrane'));
                    //TODO save array as is
                }
            }
            else{
                String fieldapi = String.valueOf(cartridge.get('fieldapi'));
                System.debug('+++++ In CG fieldapi for '+key+' is:'+fieldapi);
                Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));
                Boolean notakey = Boolean.valueOf(cartridge.get('notakey'));

                //Boolean readonly = Boolean.valueOf(cartridge.get('readonly'));


                if(!notafield /*&& !readonly*/ && fieldapi!=null && fieldapi.contains('.')){
                    //fieldapi = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                    //System.debug('+++++ In CG2 fieldapi for '+key+' is:'+fieldapi);
                    String fieldapiwithoutobjname = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                    
                    Object finalValue = sampleJson.get(key);
                    if(notakey && finalValue==null){
                        finalValue = String.valueOf(cartridge.get('default'));
                    }

                    System.debug('\n\n-------------------------- CG Final Body for key \n\n'+key+' is: '+finalValue+' - '+fieldapiwithoutobjname);

                    Map<String,Object> mutationcapsule = (Map<String,Object>)cartridge.get('mutationcapsule');
                    String mutationClass = String.valueOf(mutationcapsule.get('interfaceclass'));
                    if(mutationClass!=''){
                        
                        System.debug('+++++ Capsule for '+fieldapi+' is:'+mutationcapsule);

                        MembraneMutationInterface mutationClassInstance = (MembraneMutationInterface) Type.forName(mutationClass).newInstance();
                        finalValue = mutationClassInstance.mutateJson(cartridge,sampleJson,finalValue);
                        System.debug('\n\n-------------------------- CG Mutation Capsule late after:\n\n'+finalValue);
                        body.put(fieldapiwithoutobjname,finalValue);
                        
                    }
                    else{
                        if(cartridgetype == 'objectasis'){
                            body.put(fieldapiwithoutobjname,JSON.serialize(finalValue));
                        }
                        else if(cartridgetype == 'multiselect'){
                            List<String> multiSelectArray = new List<String>();

                            for(Object picklistObj:(List<Object>)finalValue){
                                multiSelectArray.add(String.valueOf(picklistObj));
                            }
                            body.put(fieldapiwithoutobjname, String.join(multiSelectArray,';'));

                        }
                        else{
                            System.debug('\n\n-------------------------- CG Final Body for key \n\n'+key+' is: '+finalValue+' - '+fieldapiwithoutobjname);

                            body.put(fieldapiwithoutobjname,finalValue);
                        }
                    }
                }
                else{
                    //--CG Not a field so dont put in composite request also, else dml will fail. This must be there for buldjson however. body.put(key,cartridge.get('default'));
                }
            }
                            
        }
        System.debug('\n\n ****** Composite Graph SO FAR *******\n\n'+recordsGraph+'\n\n ******************************\n\n');
    }
    /** =================================================================================================================== */





    /* ===================================== Reverse Osmosis JSON to sObject Record Start =================================*/

    /* ============================================= Reverse Osmosis JSON to sObject Record End ===========================================*/


    public static Map<String, Object> generateJson(String recordId, String membraneJsonString){


        Map<String, Object> membraneMap = (Map<String, Object>) JSON.deserializeUntyped(membraneJsonString);

        System.debug('\n\n ============  Osmosis with membrane ============= \n\n'+ JSON.serializePretty(membraneMap)+'\n\n=================\n\n');
        Map<String, Object> jsonOutput = new Map<String, Object>();

        Id recId = recordId;
        String objApiName = String.valueOf(recId.getSobjectType());
        sObject sObjRecord = Schema.getGlobalDescribe().get(objApiName).newSObject();

        //Map<String,List<SObject>> childRecordsMap = new Map<String,List<SObject>>();
        //Map<String,String> relationshipQueryMap = new Map<String,String>();


        //9th July String query = generateQuery(objApiName,membraneMap,relationshipQueryMap,recordId)+' WHERE Id=:recordId';
        String query = generateQuery(objApiName,membraneMap)+' WHERE Id=:recordId';
        System.debug('\n\n --------- Query ----------\n\n'+query+'\n\n---------------------\n\n');

        sObject sObjectRecord = Database.query(String.escapeSingleQuotes(query));
        
        /* No longer needed after SOQL subquery with 5 levels deep
        for(String relationship:relationshipQueryMap.keySet()){
            String subquery = relationshipQueryMap.get(relationship);
            System.debug('\n\n --------- Sub Query ----------\n\n'+subquery+'\n\n---------------------\n\n');

            childRecordsMap.put(relationship,Database.query(String.escapeSingleQuotes(subquery)));
        }
        */

        System.debug('\n\n --------- Record ----------\n\n'+sObjectRecord+'\n\n---------------------\n\n');

        buildJson(sObjectRecord,jsonOutput,getMainMembrane(membraneMap));

        System.debug('\n\n --------- Final JSON fron sObject ----------\n\n'+JSON.serializePretty(jsonOutput)+'\n\n---------------------\n\n');

        return jsonOutput;
    }

    /*************************************************************** I N T E R N A L S     S T A R T *********************************************************/

    static String generateQuery(String objApiName,Map<String, Object> membraneMap /*,Map<String,String> relationshipQueryMap, String recordId*/){

        String query = 'SELECT ';
        List<String> fields = new List<String>();
        fields.add('id');

        List<Object> extrafields = (List<Object>)membraneMap.get('extrafields');
        for(Object extrafield:extrafields){
            String fieldapi = String.valueOf(extrafield);

            if(fieldapi!=null && !fields.contains(fieldapi) ){
                fieldapi = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                //String finalField = prefix!=''?prefix+'.'+relationship+'.'+fieldapi:relationship+'.'+fieldapi;
                if(!fields.contains(fieldapi.toLowerCase())){
                    fields.add(fieldapi.toLowerCase());
                }
            }
        }
        
        //9th July gatherFields4Query('',fields,getMainMembrane(membraneMap),relationshipQueryMap,recordId);
        gatherFields4Query('',fields,getMainMembrane(membraneMap));

        query = query + String.join(fields,',')+' FROM '+objApiName;

        return query;
    }

    static void buildJson(sObject record, Map<String, Object> jsonOutput, Map<String, Object> membrane /*,Map<String,List<SObject>> childRecordsMap*/){

        if(record==null) return;
        
        for(String key:membrane.keyset()){
            Map<String,Object> cartridge = (Map<String,Object>)membrane.get(key);

            Boolean notakey = Boolean.valueOf(cartridge.get('notakey'));
            if(notakey) continue;

            String cartridgetype = String.valueOf(cartridge.get('cartridgetype'));
            System.debug('+++++ cartridgetype for '+key+' is:'+cartridgetype);
            if(cartridgetype=='object'){
                //--Moving notafield only for leaf fields Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));
                Map<String,Object> rhsObject = new Map<String,Object>();
                jsonOutput.put(key,rhsObject);

                //if(!notafield){
                    String relationship;
                    if(cartridge.get('relationship')!=null /*Moving notafield only for leaf fields && !notafield*/){
                        relationship = String.valueOf(cartridge.get('relationship'));
                    }
                    else{
                        relationship ='';
                    }
                    
                    if(relationship!=''){
                        /* __r will be provided in membrane for lookup relationship so no suffix
                        String sobjectapiname = String.valueOf(cartridge.get('sobject'));
                        String relationshipsuffix = sobjectapiname.endsWith('__c')?'__r':'';
                        */
                        // 09th July buildJson(record.getSObject(relationship),rhsObject,(Map<String,Object>)cartridge.get('membrane'),childRecordsMap);
                        buildJson(record.getSObject(relationship),rhsObject,(Map<String,Object>)cartridge.get('membrane'));

                    }
                    else{
                        //9th July buildJson(record,rhsObject,(Map<String,Object>)cartridge.get('membrane'),childRecordsMap);
                        buildJson(record,rhsObject,(Map<String,Object>)cartridge.get('membrane'));
                    }
                //}
                /*
                else{
                    //TODO
                }
                */
                
            }
            else if(cartridgetype=='array'){
                String relationship;
                if(cartridge.get('relationship')!=null){
                    relationship = String.valueOf(cartridge.get('relationship'));
                }
                else{
                    relationship ='';
                }
                
                List<Object> rhsArray = new List<Object>();
                jsonOutput.put(key,rhsArray);
                if(relationship!=''){
                    List<SObject> children = new List<SObject>();

                    String sobjectapiname = String.valueOf(cartridge.get('sobject'));
                    String relationshipsuffix = sobjectapiname.endsWith('__c')?'__r':'';
                    
                    //nested child record design change 
                    children = record.getSObjects(relationship+relationshipsuffix);
                    // -- 9th July children = childRecordsMap.get(relationship);
                    System.debug('+++++++++++++++ children:'+children);
                    if(children!=null){
                        for (SObject child : children)
                        {
                            Map<String,Object> childObject = new Map<String,Object>();
                            rhsArray.add(childObject);
                            //9th July buildJson(child,childObject,(Map<String,Object>)cartridge.get('membrane'),childRecordsMap);
                            buildJson(child,childObject,(Map<String,Object>)cartridge.get('membrane'));
                        }
                    }
                    
                }
                else{
                    //buildJson(relationship,record,rhsArray,(Map<String,Object>)cartridge.get('membrane'));
                }
     
            }
            else{
                String fieldapi = String.valueOf(cartridge.get('fieldapi'));
                Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));

                System.debug('+++++ fieldapi for '+key+' is:'+fieldapi);

                if(!notafield && fieldapi!=null){
                    fieldapi = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());

                    Object finalValue = record.get(fieldapi);

                    System.debug('+++++ IN BUILDJOSN final value for '+key+' is:'+finalValue+' serialize to '+String.valueOf(finalValue));

                    String mutationClass = '';
                    if(cartridge.get('mutationcapsule')!=null){

                        Map<String,Object> mutationcapsule = (Map<String,Object>)cartridge.get('mutationcapsule');
                        System.debug('+++++ Capsule for '+fieldapi+' is:'+mutationcapsule);
                        mutationClass = String.valueOf(mutationcapsule.get('interfaceclass'));
                    }

                    
                    if(mutationClass!=''){
                        MembraneMutationInterface mutationClassInstance = (MembraneMutationInterface) Type.forName(mutationClass).newInstance();
                        finalValue = mutationClassInstance.mutateRecord(cartridge,record,finalValue);
                        System.debug('\n\n-------------------------- Mutation Capsule late after:\n\n'+finalValue);
                        jsonOutput.put(key,finalValue);
                    }
                    else{
                        if(cartridgetype == 'objectasis'){
                            /*
                            try{
                                Map<String,Object> str2Obj = (Map<String,Object>)finalValue;
                                jsonOutput.put(key,str2Obj);
                            }catch(System.TypeException e){
                                try{
                                    String asisstr = String.valueOf(finalValue);
                                    System.debug('\n\n-------------------------- Asis test. asisstr:'+asisstr);

                                    List<Object> str2array = (List<Object>)JSON.deserializeUntyped(asisstr.unescapeHtml4());
                                    System.debug('\n\n-------------------------- Asis test. str2array:'+str2array);

                                    jsonOutput.put(key,str2array);
                                    System.debug('\n\n-------------------------- Asis test. jsonOutput:'+jsonOutput);

                                }catch(System.TypeException e2){
                                    jsonOutput.put(key,String.valueOf(finalValue));
                                    System.debug('\n\n-------------------------- Asis test final. jsonOutput:'+jsonOutput);

                                }

                            }
                            */
                            System.debug('\n\n-------------------------- finalValue:\n\n'+finalValue);
                            if(finalValue!=null){
                                jsonOutput.put(key,JSON.deserializeUntyped(String.valueOf(finalValue)));
                            }
                            
                        }
                        else if(cartridgetype == 'multiselect'){
                            String multiSelectValue = String.valueOf(finalValue);
                            List<String> multiSelectArray = multiSelectValue.split(';');
                            jsonOutput.put(key,multiSelectArray);
                        }
                        else{
                            jsonOutput.put(key,finalValue);
                        }
                    }

                    
                }
                else{
                    jsonOutput.put(key,cartridge.get('default'));
                }
 
            }
                   
        }

        System.debug('\n\n-------------------------- Asis test final just b4. jsonOutput:'+jsonOutput);
        
        System.debug('\n\n ****** JSONOUTPUT SO FAR *******\n\n'+jsonOutput+'\n\n ******************************\n\n');
    }


    static void gatherFields4Query(String prefix, List<String> fields, Map<String, Object> membrane /*,Map<String,String> relationshipQueryMap, String recordId*/){

        if(membrane==null) return;

        for(String key:membrane.keyset()){
            Map<String,Object> cartridge = (Map<String,Object>)membrane.get(key);
            String cartridgetype = String.valueOf(cartridge.get('cartridgetype'));
            System.debug('+++++ cartridgetype for '+key+' is:'+cartridgetype);
            //--Moving notafield only for leaf fields Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));
            //--Moving notafield only for leaf fields System.debug('+++++ notafield for '+key+' is:'+notafield);
            
            if(cartridgetype=='object'){
                String relationship;
                /* //--Moving notafield only for leaf fields 
                if(notafield){
                    relationship = '';
                }
                else{
                    relationship = String.valueOf(cartridge.get('relationship'));
                }
                */
                relationship = String.valueOf(cartridge.get('relationship'));

                /* __r will be provided in membrane for lookup relationship so no suffix
                String sobjectapiname = String.valueOf(cartridge.get('sobject'));
                String relationshipsuffix = sobjectapiname.endsWith('__c')?'__r':'';
                relationship = relationship+relationshipsuffix;
                */

                if(relationship!=''){

                   

                    List<Object> extrafields = (List<Object>)cartridge.get('extrafields');
                    for(Object extrafield:extrafields){
                        String fieldapi = String.valueOf(extrafield);

                        if(fieldapi!=null && !fields.contains(fieldapi) ){
                            fieldapi = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                            String finalField = prefix!=''?prefix+'.'+relationship+'.'+fieldapi:relationship+'.'+fieldapi;
                            if(!fields.contains(finalField.toLowerCase())){
                                fields.add(finalField.toLowerCase());
                            }
                        }
                    }

                    String nextPrefix = (prefix==''?'':prefix+'.')+relationship;
                     //To solve error like SObject row was retrieved via SOQL without querying the requested field:
                    //when there are no fields configured for a lookup field
                    fields.add(nextPrefix+'.Id');

                    //9th July gatherFields4Query(nextPrefix,fields,(Map<String,Object>)cartridge.get('membrane'),relationshipQueryMap,recordId);
                    gatherFields4Query(nextPrefix,fields,(Map<String,Object>)cartridge.get('membrane'));
                }
            }
            else if(cartridgetype=='array'){
                String relationship;
                String lookupfieldapi = String.valueOf(cartridge.get('lookupfield'));
                /* Moving notafield to leaf fields
                if(notafield){
                    relationship = '';
                }
                else{
                    relationship = String.valueOf(cartridge.get('relationship'));
                }
                */
                relationship = String.valueOf(cartridge.get('relationship'));

                String sobjectapiname = String.valueOf(cartridge.get('sobject'));
                String relationshipsuffix = sobjectapiname.endsWith('__c')?'__r':'';
                relationship = relationship+relationshipsuffix;


                if(relationship!=''){
                    /*
                    List<Object> extrafields = (List<Object>)cartridge.get('extrafields');
                    for(Object extrafield:extrafields){
                        String fieldapi = String.valueOf(extrafield);

                        if(fieldapi!=null && !fields.contains(fieldapi) ){
                            fieldapi = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                            String finalField = prefix!=''?prefix+'.'+fieldapi:fieldapi;
                            if(!fields.contains(finalField.toLowerCase())){
                                fields.add(finalField.toLowerCase());
                            }
                        }
                    }
                    */

                    /* __r will be provided in membrane for lookup relationship so no suffix
                    String sobjectapiname = String.valueOf(cartridge.get('sobject'));
                    //Needed. It is assumed that configurer will NOT enter the __r in relationship. The same is not added while generating membrane - this is incorrect. It is being added
                    //Discovered while trying afresh for Stripe
                    String relationshipsuffix = sobjectapiname.endsWith('__c')?'__r':'';
                    */
                    
                    // nested child design change 
                    //9th July fields.add('('+generateQuery(relationship,(Map<String,Object>)cartridge,relationshipQueryMap,recordId)+')');
                    fields.add('('+generateQuery(relationship,(Map<String,Object>)cartridge)+')');
                    //9th July relationshipQueryMap.put(relationship,generateQuery(sobjectapiname,(Map<String,Object>)cartridge,relationshipQueryMap,recordId)+' WHERE '+lookupfieldapi+'=:recordId');
                }
            }
            else{
                String fieldapi = String.valueOf(cartridge.get('fieldapi'));
                System.debug('+++++ fieldapi for '+key+' is:'+fieldapi);
                Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));

                if(!notafield && fieldapi!=null && !fields.contains(fieldapi) ){
                    fieldapi = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                    String finalField = prefix!=''?prefix+'.'+fieldapi:fieldapi;
                    if(!fields.contains(finalField.toLowerCase())){
                        fields.add(finalField.toLowerCase());
                    }
                }
            }
                            
        }
  
    }
    /*************************************************************** I N T E R N A L S     E N D ***********************************************************/

    


    /*************************************************************** JAVASCRIPTIFY *********************************************************/
    public static Map<String, Object> generateMembrane(String jsonObject,String existingMembraneJsonString){

        Map<String, Object> existingMembrane = new Map<String,Object>();
        if(existingMembraneJsonString!=null){
            existingMembrane = (Map<String, Object>) JSON.deserializeUntyped(existingMembraneJsonString);
        }

        Map<String,Object> sobjectdefinition = new Map<String,Object>();
        Map<String,Object> existingsobjectdefinition = (Map<String,Object>)existingMembrane.get('sobjectdefinition');

        mergeOrDefault(sobjectdefinition,'label',MembrameMemory.mainObjLabel,existingsobjectdefinition);
        mergeOrDefault(sobjectdefinition,'defaultrecordtype','',existingsobjectdefinition);
        mergeOrDefault(sobjectdefinition,'namefieldtype','Text',existingsobjectdefinition);
        mergeOrDefault(sobjectdefinition,'namefieldlabel','Name',existingsobjectdefinition);
        //sobjectdefinition.put('sharingModel','ReadWrite');


        String mainsobject = (existingMembrane.get('sobject') != null)?String.valueOf(existingMembrane.get('sobject')):MembrameMemory.mxo+cfy(MembrameMemory.mainObjLabel,'c');
        String externalidfield = (existingMembrane.get('externalidfield') != null)?String.valueOf(existingMembrane.get('externalidfield')):(mainsobject!=''?mainsobject+'.':'')+MembrameMemory.mxf+cfy(MembrameMemory.mainObjLabel,'e');
        String externalsourcepk = (existingMembrane.get('externalsourcepk') != null)?String.valueOf(existingMembrane.get('externalsourcepk')):'';


        List<Object> extrafields = (existingMembrane.get('extrafields') != null)?(List<Object>)existingMembrane.get('extrafields'):new List<String>();

        Map<String,Object> membrane = buildMembrane(jsonObject,(Map<String, Object>)existingMembrane.get('membrane'),mainsobject);

        return new Map<String,Object>{  'membrane' => membrane,
                                        'externalidfield' => externalidfield,
                                        'externalsourcepk' => externalsourcepk,
                                        'sobject' => mainsobject,
                                        'sobjectdefinition' => sobjectdefinition,
                                        'extrafields' => extrafields,
                                        'SKIPFORDMA' => false
                                    };
    }

    static void mergeOrDefault(Map<String,Object> cartridge,String key, Object defaultValue,Map<String,Object> existingMembraneCartridge){
        if(existingMembraneCartridge?.get(key)==null){
            cartridge.put(key,defaultValue);
        }
        else{
            cartridge.put(key,existingMembraneCartridge.get(key));
        }

    }
         
    static String cfy(String str,String suffix)
    {
        String pluralsuffix = suffix;
        if(suffix == 's' && (str.endsWith('s')||str.endsWith('sh')||str.endsWith('ch')||str.endsWith('x')||str.endsWith('z'))){
            pluralsuffix = 'es';
            suffix ='es';
        }
        String extsuffix = suffix;
        if(suffix=='e'){
            extsuffix = 'e';
            suffix='c';
        }
        if(str!=null){
            str = str.replaceAll(' ','')+(extsuffix=='e'?'_extid':'')+(pluralsuffix!='s' && pluralsuffix!='es'?'__':'')+suffix;
        }
        return str;
    }

    static String pluralize(String str)
    {
       
        if(str!=null){
            str = ((str.endsWith('s')||str.endsWith('sh')||str.endsWith('ch')||str.endsWith('x')||str.endsWith('z'))?str+'es':str+'s');
        }
        return str;
    }

    public static Map<String, Object> buildMembrane(String jsonObject,Map<String,Object> existingMembrane, String parentobj){

        Map<String, Object> rhs = (Map<String, Object>) JSON.deserializeUntyped(jsonObject);

        System.debug('\n\n ============  Generating Membrane for ============= \n\n'+ JSON.serializePretty(rhs)+'\n\n=================\n\n');

        Map<String, Object> membrane = new Map<String, Object>();
        for(String key:rhs.keyset()){
            //System.debug('\n---- Key:'+key);
            Map<String,Object> cartridge = new Map<String,Object>();
            Map<String,Object> existingMembraneCartridge = (Map<String, Object>)existingMembrane?.get(key);
            
            String cartridgetype = '';
            if(existingMembraneCartridge!=null && existingMembraneCartridge.get('cartridgetype')!=null){
                cartridgetype = String.valueOf(existingMembraneCartridge.get('cartridgetype'));
            }
            
            if(cartridgetype!='objectasis'){
                cartridgetype = getValueType(rhs.get(key));
            }
            
            cartridge.put('cartridgetype',cartridgetype);

            mergeOrDefault(cartridge,'mutationcapsule',new Map<String,Object>{'interfaceclass'=>'','metadata'=>new Map<String,Object>()},existingMembraneCartridge);
            //mergeOrDefault(cartridge,'notafield',true,existingMembraneCartridge);
            //cartridge.put('notafield',true);
            mergeOrDefault(cartridge,'readonly',false,existingMembraneCartridge);
            mergeOrDefault(cartridge,'notakey',false,existingMembraneCartridge);
            mergeOrDefault(cartridge,'SKIPFORDMA',false,existingMembraneCartridge);
            

            if(cartridgetype == 'object'){
                //cartridge.put('membrane',buildMembrane(JSON.serialize(rhs.get(key)), (Map<String,Object>)existingMembraneCartridge?.get('membrane')));

                mergeOrDefault(cartridge,'relationship',MembrameMemory.mxf+cfy(key,'r'),existingMembraneCartridge);
                
                Map<String,Object> sobjectdefinition = new Map<String,Object>();
                Map<String,Object> existingsobjectdefinition = (Map<String,Object>)existingMembraneCartridge?.get('sobjectdefinition');

                mergeOrDefault(sobjectdefinition,'label',key,existingsobjectdefinition);
                mergeOrDefault(sobjectdefinition,'defaultrecordtype','',existingsobjectdefinition);
                mergeOrDefault(sobjectdefinition,'namefieldtype','Text',existingsobjectdefinition);
                mergeOrDefault(sobjectdefinition,'namefieldlabel','Name',existingsobjectdefinition);
                //sobjectdefinition.put('sharingModel','ReadWrite');
                mergeOrDefault(cartridge,'sobject',MembrameMemory.mxo+cfy(key,'c'),existingMembraneCartridge);
                mergeOrDefault(cartridge,'extrafields',new List<String>(),existingMembraneCartridge);

                cartridge.put('sobjectdefinition',sobjectdefinition); //mergeOrDefault not needed here. Merge is taken care in the above steps.

                mergeOrDefault(cartridge,'externalidfield',String.valueOf(cartridge.get('sobject'))+'.'+MembrameMemory.mxf+cfy(key,'e'),existingMembraneCartridge);
                mergeOrDefault(cartridge,'externalsourcepk','',existingMembraneCartridge);
                mergeOrDefault(cartridge,'lookupfield', parentobj+'.'+MembrameMemory.mxf+cfy(key,'c') ,existingMembraneCartridge);

                mergeOrDefault(cartridge,'default',null,existingMembraneCartridge);

                cartridge.put('membrane',buildMembrane(JSON.serialize(rhs.get(key)), (Map<String,Object>)existingMembraneCartridge?.get('membrane'),String.valueOf(cartridge.get('sobject'))));
                
            }
            else if(cartridgetype == 'array'){
                Boolean saveAsIs = false;
                List<Object> children = new List<Object>();
                children = (List<Object>)rhs.get(key);   
                if(children.size()>0){
                    // TODO if array is mix of object and primitive data-type
                    if(getValueType(children[0]) == 'object'){

                        Map<String,Object> sobjectdefinition = new Map<String,Object>();
                        Map<String,Object> existingsobjectdefinition = (Map<String,Object>)existingMembraneCartridge?.get('sobjectdefinition');
        
                        mergeOrDefault(sobjectdefinition,'label',key,existingsobjectdefinition);
                        mergeOrDefault(sobjectdefinition,'defaultrecordtype','',existingsobjectdefinition);
                        mergeOrDefault(sobjectdefinition,'namefieldtype','Text',existingsobjectdefinition);
                        mergeOrDefault(sobjectdefinition,'namefieldlabel','Name',existingsobjectdefinition);
                        //sobjectdefinition.put('sharingModel','ReadWrite');
                        mergeOrDefault(cartridge,'sobject',MembrameMemory.mxo+cfy(key,'c'),existingMembraneCartridge);
                        mergeOrDefault(cartridge,'extrafields',new List<String>(),existingMembraneCartridge);

                        cartridge.put('sobjectdefinition',sobjectdefinition); //mergeOrDefault not needed here. Merge is taken care in the above steps.
        
                        mergeOrDefault(cartridge,'externalidfield',String.valueOf(cartridge.get('sobject'))+'.'+MembrameMemory.mxf+cfy(key,'e'),existingMembraneCartridge);
                        mergeOrDefault(cartridge,'externalsourcepk','',existingMembraneCartridge);

                        mergeOrDefault(cartridge,'default',null,existingMembraneCartridge);
                        
                        //cartridge.put('membrane',buildMembrane(JSON.serialize(children[0]), (Map<String,Object>)existingMembraneCartridge?.get('membrane')));
                        /* __r in relationship name is not allowed while creation. So disabling auto append
                        String sobjectapiname = String.valueOf(cartridge.get('sobject'));
                        String relationshipsuffix = sobjectapiname.endsWith('__c')?'__r':'';
                        */

                        mergeOrDefault(cartridge,'relationship',MembrameMemory.mxo+cfy(key,'s'),existingMembraneCartridge);
                        mergeOrDefault(cartridge,'lookupfield',MembrameMemory.mxo+cfy(key,'c')+'.'+parentobj.replace('mxo','mxf'),existingMembraneCartridge);

                        cartridge.put('membrane',buildMembrane(JSON.serialize(children[0]), (Map<String,Object>)existingMembraneCartridge?.get('membrane'),String.valueOf(cartridge.get('sobject'))));


                    }
                    else{
                        saveAsIs = true;
                        Map<String,Object> fielddefinition = new Map<String,Object>();
                        Map<String,Object> existingfielddefinition = (Map<String,Object>)existingMembraneCartridge?.get('fielddefinition');

                        mergeOrDefault(fielddefinition,'label',key,existingfielddefinition);
                        mergeOrDefault(fielddefinition,'fieldtype','',existingfielddefinition);
                        mergeOrDefault(cartridge,'fieldapi',(parentobj!=''?parentobj+'.':'')+MembrameMemory.mxf+cfy(key,'c'),existingMembraneCartridge);
                        cartridge.put('fielddefinition',fielddefinition);//mergeOrDefault not needed here. Merge is taken care in the above steps.
                        mergeOrDefault(cartridge,'notafield',true,existingMembraneCartridge);
                        cartridge.put('cartridgetype','multiselect');
                        mergeOrDefault(cartridge,'default',null,existingMembraneCartridge);

                    }
                    
                    
                }
                else{
                    cartridge.put('membrane',null);
                    cartridge.put('relationship','');
                    cartridge.put('lookupfield','');

                }

                /*
                if(saveAsIs){
                    Map<String,Object> fielddefinition = new Map<String,Object>();
                    Map<String,Object> existingfielddefinition = (Map<String,Object>)existingMembraneCartridge?.get('fielddefinition');

                    mergeOrDefault(fielddefinition,'label',key,existingfielddefinition);
                    mergeOrDefault(fielddefinition,'fieldtype','',existingfielddefinition);
                    mergeOrDefault(cartridge,'fieldapi',(parentobj!=''?parentobj+'.':'')+MembrameMemory.mxf+cfy(key,'c'),existingMembraneCartridge);
                    cartridge.put('fielddefinition',fielddefinition);//mergeOrDefault not needed here. Merge is taken care in the above steps.
                }
                else{
                    Map<String,Object> sobjectdefinition = new Map<String,Object>();
                    Map<String,Object> existingsobjectdefinition = (Map<String,Object>)existingMembraneCartridge?.get('sobjectdefinition');
    
                    mergeOrDefault(sobjectdefinition,'label',key,existingsobjectdefinition);
                    mergeOrDefault(sobjectdefinition,'defaultrecordtype','',existingsobjectdefinition);
                    mergeOrDefault(sobjectdefinition,'namefieldtype','Text',existingsobjectdefinition);
                    mergeOrDefault(sobjectdefinition,'namefieldlabel','Name',existingsobjectdefinition);
                    //sobjectdefinition.put('sharingModel','ReadWrite');
                    mergeOrDefault(cartridge,'sobject',MembrameMemory.mxo+cfy(key,'c'),existingMembraneCartridge);
                    mergeOrDefault(cartridge,'extrafields',new List<String>(),existingMembraneCartridge);

                    cartridge.put('sobjectdefinition',sobjectdefinition); //mergeOrDefault not needed here. Merge is taken care in the above steps.
    
                    mergeOrDefault(cartridge,'externalidfield',MembrameMemory.mxo+cfy(key,'e'),existingMembraneCartridge);
                    mergeOrDefault(cartridge,'externalsourcepk','',existingMembraneCartridge);

                    mergeOrDefault(cartridge,'default',null,existingMembraneCartridge);
                }
                */
                
            }
            else{
                
                Map<String,Object> fielddefinition = new Map<String,Object>();
                Map<String,Object> existingfielddefinition = (Map<String,Object>)existingMembraneCartridge?.get('fielddefinition');

                mergeOrDefault(fielddefinition,'label',key,existingfielddefinition);
                if(cartridgetype!='objectasis'){
                    mergeOrDefault(fielddefinition,'fieldtype',fieldTypeFromCartridge(cartridgetype),existingfielddefinition);
                }else{
                    fielddefinition.put('fieldtype','TextArea');
                }
                mergeOrDefault(cartridge,'fieldapi',(parentobj!=''?parentobj+'.':'')+MembrameMemory.mxf+cfy(key,'c'),existingMembraneCartridge);
                cartridge.put('fielddefinition',fielddefinition);//mergeOrDefault not needed here. Merge is taken care in the above steps.
                mergeOrDefault(cartridge,'notafield',true,existingMembraneCartridge);

                mergeOrDefault(cartridge,'default',null,existingMembraneCartridge);
            }

            membrane.put(key,cartridge);
            
        }
        return membrane;
        
    }


    /**^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
    public static MetadataService.PermissionSetFieldPermissions createFieldSecurity(String customField){   

        MetadataService.PermissionSetFieldPermissions fieldSec = new MetadataService.PermissionSetFieldPermissions();
        fieldSec.field=customField;
        fieldSec.editable=true;
        fieldSec.readable=true;
        return fieldSec;
        
    }

    //contains method for some reason was not working so wrote this custom method
    static Boolean alreadyHas(List<String> existingFieldsList,String fieldFullName){
        Boolean eFlag = false;
        for(String ef:existingFieldsList){
            System.debug(ef+'=='+fieldFullName+'?'+(ef==fieldFullName));
            if(ef == fieldFullName){
                eFlag = true;
                break;
            }
        }
        return eFlag;
    }

    public static void DataModelAbstractionFromMembrane(   
                                                    List<MetadataService.Metadata> newObjectsList, 
                                                    List<MetadataService.CustomField> newFieldsList,
                                                    List<String> existingObjects,
                                                    Map<String,List<String>> existingFields,
                                                    String myparent,
                                                    Map<String, Object> membraneMap,
                                                    List<MetadataService.PermissionSetFieldPermissions> fieldSecList
                                                ){
       

        if(membraneMap == null) return;

        Map<String,Object> membrane = (Map<String,Object>)membraneMap.get('membrane');

        /* ######################################################## Processing the main membrane sobject     S T A R T   ########################################################*/

        String main_sobjectvalue = String.valueOf(membraneMap.get('sobject'));
        String main_externalidfield = String.valueOf(membraneMap.get('externalidfield'));

        Boolean SKIPFORDMA = Boolean.valueOf(membraneMap.get('SKIPFORDMA'));

        if(main_sobjectvalue!=null && main_sobjectvalue!=''){
            if(!existingFields.containsKey(main_sobjectvalue)){
                existingFields.put(main_sobjectvalue,new List<String>());
            }

            existingFields.get(main_sobjectvalue).addAll(EasyJsonController.getFields(main_sobjectvalue));
            System.debug('\n\nMS============ existingFields after sobject:'+main_sobjectvalue+'='+existingFields);

        }
        
        if(!SKIPFORDMA && main_sobjectvalue!=null && main_sobjectvalue!='' && !existingObjects.contains(main_sobjectvalue)){

            MetadataService.CustomObject customObject = new MetadataService.CustomObject();
            Map<String,Object> sobjectdefinition = (Map<String,Object>)membraneMap.get('sobjectdefinition');
            customObject.fullName = main_sobjectvalue;
            customObject.label = String.valueOf(sobjectdefinition.get('label'));
            customObject.plurallabel = pluralize(customObject.label);//String.valueOf(sobjectdefinition.get('plurallabel'));
            customObject.nameField = new MetadataService.CustomField();
            customObject.nameField.type_x = String.valueOf(sobjectdefinition.get('namefieldtype'));
            if(customObject.nameField.type_x == 'AutoNumber'){
                customObject.nameField.startingNumber = 0;
                customObject.nameField.displayFormat = 'A-{0000}';
            }
            customObject.nameField.label = String.valueOf(sobjectdefinition.get('namefieldlabel'));
            customObject.deploymentStatus = 'Deployed';
            customObject.sharingModel = 'ReadWrite';

            newObjectsList.add(customObject);

        }

        System.debug('\n\nMS============ main_externalidfield for:'+main_sobjectvalue+'='+main_externalidfield);
        System.debug('\n\nMS============ alreadyHas Check:'+alreadyHas(existingFields.get(main_sobjectvalue),main_externalidfield));



        if(!SKIPFORDMA && /*main_sobjectvalue!=null && main_sobjectvalue!='' &&*/ main_externalidfield!=null && main_externalidfield!='' && existingFields.containsKey(main_sobjectvalue) && !alreadyHas(existingFields.get(main_sobjectvalue),main_externalidfield)){

            MetadataService.CustomField customField = new MetadataService.CustomField();
            Map<String,Object> sobjectdefinition = (Map<String,Object>)membraneMap.get('sobjectdefinition');
            customField.label = String.valueOf(sobjectdefinition.get('label'))+' '+'ExtId';
            customField.fullName = main_externalidfield;
            customField.type_x = 'Text';
            customField.length = 255;
            customField.externalId = true;
            customField.unique = true;
            
            newFieldsList.add(customField);
            System.debug('\n\n ======== Main object ext field:'+main_externalidfield);
            fieldSecList.add(createFieldSecurity(customField.fullName));
            
        }

        /* ######################################################## Processing the main membrane sobject     E N D   ########################################################*/



        if(membrane == null) return;


        
        for(String key:membrane.keyset()){
            Map<String,Object> cartridge = (Map<String,Object>)membrane.get(key);
            SKIPFORDMA = Boolean.valueOf(cartridge.get('SKIPFORDMA'));
            if(SKIPFORDMA) continue;
            String cartridgetype = String.valueOf(cartridge.get('cartridgetype'));
            //--Moving notafield only for leaf fields Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));

            if(cartridgetype=='object'){

                //if(!notafield){
                    String relationship;
                    if(cartridge.get('relationship')!=null /*&& !notafield*/){
                        relationship = String.valueOf(cartridge.get('relationship'));
                    }
                    else{
                        relationship ='';
                    }

                    
                    if(relationship!=''){

                        String sobjectvalue = String.valueOf(cartridge.get('sobject'));
                        String lookupfield = String.valueOf(cartridge.get('lookupfield'));


                        if(sobjectvalue!=null && sobjectvalue!=''){
                            if(!existingFields.containsKey(sobjectvalue)){
                                existingFields.put(sobjectvalue,new List<String>());
                            }
        
                            existingFields.get(sobjectvalue).addAll(EasyJsonController.getFields(sobjectvalue));
                            System.debug('\n\nMS============ existingFields after sobject:'+sobjectvalue+'='+existingFields);

                        }
                        
                        if(sobjectvalue!=null && sobjectvalue!='' && !existingObjects.contains(sobjectvalue)){

                            MetadataService.CustomObject customObject = new MetadataService.CustomObject();
                            Map<String,Object> sobjectdefinition = (Map<String,Object>)cartridge.get('sobjectdefinition');
                            customObject.fullName = sobjectvalue;
                            customObject.label = String.valueOf(sobjectdefinition.get('label'));
                            customObject.plurallabel = pluralize(customObject.label);//String.valueOf(sobjectdefinition.get('plurallabel'));
                            customObject.nameField = new MetadataService.CustomField();
                            customObject.nameField.type_x = String.valueOf(sobjectdefinition.get('namefieldtype'));
                            if(customObject.nameField.type_x == 'AutoNumber'){
                                customObject.nameField.startingNumber = 0;
                                customObject.nameField.displayFormat = 'A-{0000}';
                            }
                            customObject.nameField.label = String.valueOf(sobjectdefinition.get('namefieldlabel'));
                            customObject.deploymentStatus = 'Deployed';
                            customObject.sharingModel = 'ReadWrite';

                            
                            newObjectsList.add(customObject);

                        }


                        String fieldDerivedFullName = (lookupfield!=null?lookupfield:myparent+'.'+sobjectvalue);
                        System.debug('\n\nMS myparent for '+sobjectvalue+' is '+myparent);
                        System.debug('\n\nMS============ fieldDerivedFullName for:'+sobjectvalue+'='+fieldDerivedFullName);


                        if(sobjectvalue!=null && /*sobjectvalue!='' &&*/ myparent!=null && myparent!='' && 
                            existingFields.containsKey(sobjectvalue) && !alreadyHas(existingFields.get(myparent),fieldDerivedFullName)){

                            System.debug('\n\nMS Lookup Field to be created for '+sobjectvalue+' on '+myparent);

                            MetadataService.CustomField customField = new MetadataService.CustomField();

                            Map<String,Object> sobjectdefinition = (Map<String,Object>)cartridge.get('sobjectdefinition');

                            customField.fullName = fieldDerivedFullName;// (lookupfield!=null?lookupfield:myparent+'.'+sobjectvalue);
                            customField.label = String.valueOf(sobjectdefinition.get('label'));
                            customField.type_x = 'Lookup'; 
                            //Why hardcoding? because say the sobject in reference to which this field is getting created already exists and there are also some existing records
                            //System anyways won't allow MasterDetail. So better create Lookup by default. Admin can later update

                            customField.referenceTo = sobjectvalue;
                            customField.relationshipLabel = pluralize(myparent.replace('__c','').replaceAll('_',' '));
                            customField.relationshipName = pluralize(myparent.replace('__c','').replaceAll('_',''));


                            newFieldsList.add(customField);
                            fieldSecList.add(createFieldSecurity(customField.fullName));
                            System.debug('\n\nMS Lookup Fields newFieldsList'+newFieldsList);

                            
                        }

                        String externalidfield = String.valueOf(cartridge.get('externalidfield'));
                        System.debug('\n\nMS============ externalidfield for:'+sobjectvalue+'='+externalidfield);

                        if(/*sobjectvalue!=null && sobjectvalue!='' &&*/ externalidfield!=null && externalidfield!='' && 
                            existingFields.containsKey(sobjectvalue) && !alreadyHas(existingFields.get(sobjectvalue),externalidfield)){

                            MetadataService.CustomField customField = new MetadataService.CustomField();
                            Map<String,Object> sobjectdefinition = (Map<String,Object>)cartridge.get('sobjectdefinition');
                            customField.label = String.valueOf(sobjectdefinition.get('label'))+' '+'ExtId';
                            customField.fullName = externalidfield; //check 11th Sept. Why main_externalidfield?
                            customField.type_x = 'Text'; 
                            customField.length = 255;
                            customField.externalId = true;
                            customField.unique = true;
                            
                            newFieldsList.add(customField);
                            fieldSecList.add(createFieldSecurity(customField.fullName));
                            
                        }

                        //myparent = String.valueOf(cartridge.get('sobject'));
                        DataModelAbstractionFromMembrane(newObjectsList,newFieldsList,existingObjects,existingFields,String.valueOf(cartridge.get('sobject')),cartridge,fieldSecList);
                    }
                    else{
                        //Do not create any object and also continue the myparent value because this is not a lookup.
                        DataModelAbstractionFromMembrane(newObjectsList,newFieldsList,existingObjects,existingFields,String.valueOf(cartridge.get('sobject')),cartridge,fieldSecList);
                    }
                    
                //}
                /*
                else{
                    //TODO
                }
                */
                
            }
            else if(cartridgetype=='array'){
                String relationship;
                if(cartridge.get('relationship')!=null){
                    relationship = String.valueOf(cartridge.get('relationship'));
                }
                else{
                    relationship ='';
                }
                
                if(relationship!=''){

                    String sobjectvalue = String.valueOf(cartridge.get('sobject')); //sobjectvalue in this case is child object
                    String lookupfield = String.valueOf(cartridge.get('lookupfield'));


                    if(sobjectvalue!=null && sobjectvalue!=''){
                        if(!existingFields.containsKey(sobjectvalue)){
                            existingFields.put(sobjectvalue,new List<String>());
                        }
    
                        existingFields.get(sobjectvalue).addAll(EasyJsonController.getFields(sobjectvalue));
                        System.debug('\n\nMS============ existingFields after sobject:'+sobjectvalue+'='+existingFields);

                    }
                    
                    if(sobjectvalue!=null && sobjectvalue!='' && !existingObjects.contains(sobjectvalue)){

                        MetadataService.CustomObject customObject = new MetadataService.CustomObject();
                        Map<String,Object> sobjectdefinition = (Map<String,Object>)cartridge.get('sobjectdefinition');
                        customObject.fullName = sobjectvalue;
                        customObject.label = String.valueOf(sobjectdefinition.get('label'));
                        customObject.plurallabel = pluralize(customObject.label);//String.valueOf(sobjectdefinition.get('plurallabel'));
                        customObject.nameField = new MetadataService.CustomField();
                        customObject.nameField.type_x = String.valueOf(sobjectdefinition.get('namefieldtype'));
                        if(customObject.nameField.type_x == 'AutoNumber'){
                            customObject.nameField.startingNumber = 0;
                            customObject.nameField.displayFormat = 'A-{0000}';
                        }
                        customObject.nameField.label = String.valueOf(sobjectdefinition.get('namefieldlabel'));
                        customObject.deploymentStatus = 'Deployed';
                        customObject.sharingModel = 'ReadWrite';

                        
                        newObjectsList.add(customObject);

                    }

                    String fieldDerivedFullName = (lookupfield!=null?lookupfield:sobjectvalue+'.'+myparent);
                    System.debug('\n\nMS============ fieldDerivedFullName for:'+sobjectvalue+'='+fieldDerivedFullName);

                    if(/*sobjectvalue!=null && sobjectvalue!='' &&*/ myparent!=null && myparent!='' && 
                        existingFields.containsKey(sobjectvalue) && !alreadyHas(existingFields.get(sobjectvalue),fieldDerivedFullName)){
                        MetadataService.CustomField customField = new MetadataService.CustomField();
                        Map<String,Object> sobjectdefinition = (Map<String,Object>)cartridge.get('sobjectdefinition');
                        customField.fullName = fieldDerivedFullName;//(lookupfield!=null?lookupfield:sobjectvalue+'.'+myparent);
                        customField.label = String.valueOf(sobjectdefinition.get('label'));
                        customField.type_x = 'Lookup'; 
                        //Why hardcoding? because say the sobject in reference to which this field is getting created already exists and there are also some existing records
                        //System anyways won't allow MasterDetail. So better create Lookup by default. Admin can later update

                        customField.referenceTo = myparent;
                        customField.relationshipLabel = relationship;
                        customField.relationshipName = relationship;

                        newFieldsList.add(customField);
                        fieldSecList.add(createFieldSecurity(customField.fullName));
                        
                    }

                    String externalidfield = String.valueOf(cartridge.get('externalidfield'));
                    System.debug('\n\nMS============ externalidfield for:'+sobjectvalue+'='+externalidfield);


                        if(/*sobjectvalue!=null && sobjectvalue!='' &&*/ externalidfield!=null && externalidfield!='' && 
                            existingFields.containsKey(sobjectvalue) && !alreadyHas(existingFields.get(sobjectvalue),externalidfield)){

                            MetadataService.CustomField customField = new MetadataService.CustomField();
                            Map<String,Object> sobjectdefinition = (Map<String,Object>)cartridge.get('sobjectdefinition');
                            customField.label = String.valueOf(sobjectdefinition.get('label'))+' '+'ExtId';
                            customField.fullName = externalidfield;
                            customField.type_x = 'Text';
                            customField.length = 255;
                            customField.externalId = true;
                            customField.unique = true;
                            
                            newFieldsList.add(customField);
                            fieldSecList.add(createFieldSecurity(customField.fullName));
                            
                        }
                    
                    //myparent = String.valueOf(cartridge.get('sobject'));
                    DataModelAbstractionFromMembrane(newObjectsList,newFieldsList,existingObjects,existingFields,String.valueOf(cartridge.get('sobject')),cartridge,fieldSecList);
                        
                }
                else{
                    //DataModelAbstractionFromMembrane(relationship,record,rhsArray,(Map<String,Object>)cartridge.get('membrane'));
                }
                
                
                
            }
            else{
                System.debug('\n\nMS============ existingFields:'+existingFields);
                String fieldapi = String.valueOf(cartridge.get('fieldapi'));
                //notafield not required for field creaion check as SKIPFORDMA is now used Boolean notafield = Boolean.valueOf(cartridge.get('notafield'));

                if(/*!notafield && */fieldapi!=null && fieldapi.contains('.')){
                    String sobjectname = fieldapi.substring(0,fieldapi.indexOf('.'));
                    String fieldname = fieldapi.substring(fieldapi.indexOf('.')+1,fieldapi.length());
                    if( fieldapi!=null && fieldapi!='' && 
                        sobjectname!=null && sobjectname!='' && 
                        existingFields.containsKey(sobjectname) && !alreadyHas(existingFields.get(sobjectname),fieldapi)){

                        MetadataService.CustomField customField = new MetadataService.CustomField();
                        Map<String,Object> fielddefinition = (Map<String,Object>)cartridge.get('fielddefinition');
                        customField.type_x = String.valueOf(fielddefinition.get('fieldtype'));
                        if(customField.type_x !=''){
                           
                            customField.fullName = fieldapi;
                            customField.label = String.valueOf(fielddefinition.get('label'));



                            customField.type_x = String.valueOf(fielddefinition.get('fieldtype'));
                            if(customField.type_x == 'Checkbox'){
                                customField.defaultvalue = 'false';
                            }
                            if(customField.type_x == 'MultiselectPicklist' || customField.type_x == 'Picklist'){
                                MetadataService.ValueSet picklistValueSet= new MetadataService.ValueSet();

                                MetadataService.ValueSetValuesDefinition valueDefinition = new MetadataService.ValueSetValuesDefinition();  //ValueSetDefination
                                List<MetadataService.CustomValue> values = new List<MetadataService.CustomValue>();

                                //Value 1 
                                MetadataService.CustomValue customValue1 = new MetadataService.CustomValue();
                                customValue1.fullName = 'Testing Metadata value 1'; //API name of picklist value
                                customValue1.default_x = false;
                                customValue1.description = '';
                                customValue1.isActive = true;
                                customValue1.label = 'Testing Metadata value 1';
                                System.debug('customValue1' + customValue1);
                                values.add(customValue1);

                                //It will be list of CustomValue
                                valueDefinition.value = values;
                                valueDefinition.sorted = true;

                                //set the valueSetDefinition
                                picklistValueSet.valueSetDefinition = valueDefinition;
                                //picklistValueSet.valueSetName = 'Test Value Set';

                                //Set the valueSet for picklist type
                                customField.valueSet = picklistValueSet;
                                if(customField.type_x == 'MultiselectPicklist'){
                                    customField.visibleLines = 5;
                                }
                                
                            }
                            else if(customField.type_x == 'Number'){
                                customField.precision = 18;
                                customField.scale = 2;
                            }
                            else if(customField.type_x == 'Text'){
                                customField.length = 255;
                            }
                            else if(customField.type_x == 'LongTextArea'){
                                customField.visibleLines = 3; 
                            }
                            else if(customField.type_x == 'ExternalId'){
                                customField.type_x = 'Text';
                                customField.length = 255;
                                customField.externalId = true;
                                customField.unique = true; 
                            }

                            System.debug('\n\nMS ============ Custom Field Label:'+customField.label+','+customField.type_x+','+customField.fullName);

                            newFieldsList.add(customField);
                            fieldSecList.add(createFieldSecurity(customField.fullName));

                            /*
                            List<MetadataService.SaveResult> saveResults = service.createMetadata(fields);
                            */
                        }

                        
                    }
                }
                
            }
                            
        }
    }
    /**^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/


    
}