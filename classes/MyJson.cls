public with sharing class MyJson {

    String jsonStr;
    public Boolean fuzzy;

    public MyJson(String jsonStr,Boolean fuzzy) {
        this.jsonStr = jsonStr;
        this.fuzzy = fuzzy;
    }

    public Boolean equals(Object obj) {
        if (obj instanceof MyJson) {
            MyJson myjson = (MyJson)obj;
            String rhsJsonStr = myjson.jsonStr;
            String lhsDigest = generateDigest(jsonStr);
            String rhsDigest = generateDigest(rhsJsonStr);
            return (lhsDigest == rhsDigest);
        }
        return false;
    }

    public Integer hashCode() {
        return generateDigest(jsonStr).hashCode();
    }

    private String generateDigest(String jsonInput){
        List<String> keyChain = new List<String>();
        extractKeys(jsonInput,keyChain);

        String facelessMembrane = String.join(keyChain,' ');

        Blob digestBlob = Crypto.generateDigest('MD5', Blob.valueOf(facelessMembrane));
        String digest = EncodingUtil.base64Encode(digestBlob);
        return digest;
    }

    public Map<String, Object> extractKeys(String jsonObject,List<String> keyChain){

        
        Map<String, Object> rhs = (Map<String, Object>) JSON.deserializeUntyped(jsonObject);

        List<String> keys = new List<String>();
        for(String key:rhs.keyset()){
            keys.add(key);
        }

        /** Comment the below line for an order sensitive JSON comparison */
        keys.sort();
        /** */
        
        Map<String, Object> jsonKeysOnly = new Map<String, Object>();
        for(String key:keys){
            keyChain.add(key);
            
            String cartridgetype = getValueType(rhs.get(key));

            if(cartridgetype == 'object'){
                keyChain.add('{');
                jsonKeysOnly.put(key,extractKeys(JSON.serialize(rhs.get(key)),keyChain));
                keyChain.add('}');

            }
            else if(cartridgetype == 'array'){
                if(fuzzy)
                    continue;

                keyChain.add('[');

                List<Object> children = new List<Object>();
                children = (List<Object>)rhs.get(key);
                if(children.size()>0){
                    if(getValueType(children[0]) == 'object'){
                        keyChain.add('{');
                        jsonKeysOnly.put(key,extractKeys(JSON.serialize(children[0]),keyChain));
                        keyChain.add('}');

                    }
                    else{
                        jsonKeysOnly.put(key,null);
                    }
                    
                }
                else{
                    jsonKeysOnly.put(key,null);
                }
                keyChain.add(']');

                
            }
            else{
                jsonKeysOnly.put(key,'');
            }
            
        }
        
        return jsonKeysOnly;
    }

    private String getValueType(Object value){
        
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

    /*
    public Map<String, Object> sortMembrane(String jsonObject,List<String> keyChain){

        
        Map<String, Object> rhs = (Map<String, Object>) JSON.deserializeUntyped(jsonObject);

        System.debug('\n\n ============  Sorting Membrane ============= \n\n'+ JSON.serializePretty(rhs)+'\n\n=================\n\n');

        List<String> keys = new List<String>();
        for(String key:rhs.keyset()){
            keys.add(key);
        }

        keys.sort();
        
        Map<String, Object> sortedmembrane = new Map<String, Object>();
        for(String key:keys){
            keyChain.add(key);
            System.debug('+++++++++ Key:'+ key);
            System.debug('+++++++++ Key Chain so far:'+ String.join(keyChain,','));
            
            String cartridgetype = getValueType(rhs.get(key));

            if(cartridgetype == 'object'){
                keyChain.add('{');
                sortedmembrane.put(key,sortMembrane(JSON.serialize(rhs.get(key)),keyChain));
                keyChain.add('}');

            }
            else if(cartridgetype == 'array'){
                keyChain.add('[');

                List<Object> children = new List<Object>();
                children = (List<Object>)rhs.get(key);
                if(children.size()>0){
                    // TODO if array is mix of object and primitive data-type
                    if(getValueType(children[0]) == 'object'){
                        keyChain.add('{');
                        sortedmembrane.put(key,sortMembrane(JSON.serialize(children[0]),keyChain));
                        keyChain.add('}');

                    }
                    else{
                        sortedmembrane.put(key,null);
                    }
                    
                }
                else{
                    sortedmembrane.put(key,null);
                }
                keyChain.add(']');

                
            }
            else{
                sortedmembrane.put(key,'');
            }
            
        }
        System.debug('\n\n ============  Final Key Chain ============= \n\n'+ keyChain+'\n\n=================\n\n');
        
        return sortedmembrane;
        
    }
        */

}