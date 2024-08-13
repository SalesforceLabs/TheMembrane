public with sharing class MembrameMemory {
    @AuraEnabled
    public static String getNamespacePrefix(){
        return namespacePrefix;
    }


    public static String namespacePrefix{
        get{
            if (namespacePrefix == null) {
                String[] parts = String.valueOf(MembrameMemory.class).split('\\.', 2);
                namespacePrefix = parts.size() == 2 ? parts[0] : '';
            }
            return namespacePrefix==''?'':namespacePrefix+'__';
        }

        set;
    }

    public static String mxo = 'mxo_';
    public static String mxf = 'mxf_';
    public static String mainObjLabel = 'Primary Object'; 

}