@isTest
private class MembraneDataModelQueueableTest {

    @TestSetup
    static void makeData(){

        //String jsonInput = '{\n  \"Description\": {\n    \"key\": \"value\"\n  },\n  \"Site\": \"Test Site\",\n  \"Parent\": {\n    \"Site\": \"Parent Site\"\n  },\n  \"Contacts\": [\n    {\n      \"LastName\": \"Test Contact\",\n      \"HasOptedOutOfFax\": false\n    }\n  ]\n}';
        String jsonInput = '{\n  \"Description\": {\n    \"key\": \"value\"\n  },\n  \"Site\": \"Test Site\",\n  \"Parent\": {\n    \"Site\": \"Parent Site\"\n  },\n  \"Custom Field\": \"Test Custom\",\n  \"Contacts\": [\n    {\n      \"LastName\": \"Test Contact\",\n      \"HasOptedOutOfFax\": false\n    }\n  ]\n}';
       
        Map<String, Object> membrane = Osmosis.generateMembrane(jsonInput,null);

        Membrane_External_Data_Source__c source = new Membrane_External_Data_Source__c();

        
        insert source;

        List<Membrane_Definition__c> mds = new List<Membrane_Definition__c>();
        Membrane_Definition__c md = new Membrane_Definition__c();
        md.Sample_JSON__c = jsonInput;
        md.Main_Object__c = 'Account';
        //md.Membrane__c = '{\n  \"SKIPFORDMA\": false,\n  \"extrafields\": [],\n  \"sobjectdefinition\": {\n    \"namefieldlabel\": \"Name\",\n    \"namefieldtype\": \"Text\",\n    \"defaultrecordtype\": \"\",\n    \"label\": \"account\"\n  },\n  \"sobject\": \"account\",\n  \"externalsourcepk\": \"\",\n  \"externalidfield\": \"\",\n  \"membrane\": {\n    \"Contacts\": {\n      \"membrane\": {\n        \"LastName\": {\n          \"default\": null,\n          \"notafield\": false,\n          \"fielddefinition\": {\n            \"fieldtype\": \"Text\",\n            \"label\": \"LastName\"\n          },\n          \"fieldapi\": \"Contact.lastname\",\n          \"SKIPFORDMA\": false,\n          \"notakey\": false,\n          \"readonly\": false,\n          \"mutationcapsule\": {\n            \"metadata\": {},\n            \"interfaceclass\": \"\"\n          },\n          \"cartridgetype\": \"text\"\n        },\n        \"HasOptedOutOfFax\": {\n          \"default\": null,\n          \"notafield\": false,\n          \"fielddefinition\": {\n            \"fieldtype\": \"Checkbox\",\n            \"label\": \"HasOptedOutOfFax\"\n          },\n          \"fieldapi\": \"Contact.HasOptedOutOfFax\",\n          \"SKIPFORDMA\": false,\n          \"notakey\": false,\n          \"readonly\": false,\n          \"mutationcapsule\": {\n            \"metadata\": {},\n            \"interfaceclass\": \"\"\n          },\n          \"cartridgetype\": \"boolean\"\n        }\n      },\n      \"lookupfield\": \"Contact.accountid\",\n      \"relationship\": \"Contacts\",\n      \"default\": null,\n      \"externalsourcepk\": \"\",\n      \"externalidfield\": \"\",\n      \"sobjectdefinition\": {\n        \"namefieldlabel\": \"Name\",\n        \"namefieldtype\": \"AutoNumber\",\n        \"defaultrecordtype\": \"\",\n        \"label\": \"Contact\"\n      },\n      \"extrafields\": [],\n      \"sobject\": \"Contact\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"metadata\": {},\n        \"interfaceclass\": \"\"\n      },\n      \"cartridgetype\": \"array\"\n    },\n    \"Parent\": {\n      \"membrane\": {\n        \"Site\": {\n          \"default\": null,\n          \"notafield\": false,\n          \"fielddefinition\": {\n            \"fieldtype\": \"Text\",\n            \"label\": \"Site\"\n          },\n          \"fieldapi\": \"account.site\",\n          \"SKIPFORDMA\": false,\n          \"notakey\": false,\n          \"readonly\": false,\n          \"mutationcapsule\": {\n            \"interfaceclass\": \"\",\n            \"metadata\": {}\n          },\n          \"cartridgetype\": \"text\"\n        }\n      },\n      \"default\": null,\n      \"lookupfield\": \"account.parentid\",\n      \"externalsourcepk\": \"\",\n      \"externalidfield\": \"\",\n      \"sobjectdefinition\": {\n        \"namefieldlabel\": \"Name\",\n        \"namefieldtype\": \"Text\",\n        \"defaultrecordtype\": \"\",\n        \"label\": \"account\"\n      },\n      \"extrafields\": [\n        \"AccountSource\"\n      ],\n      \"sobject\": \"account\",\n      \"relationship\": \"Parent\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"interfaceclass\": \"\",\n        \"metadata\": {}\n      },\n      \"cartridgetype\": \"object\"\n    },\n    \"Site\": {\n      \"default\": null,\n      \"notafield\": false,\n      \"fielddefinition\": {\n        \"fieldtype\": \"Text\",\n        \"label\": \"Site\"\n      },\n      \"fieldapi\": \"account.Site\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"metadata\": {},\n        \"interfaceclass\": \"\"\n      },\n      \"cartridgetype\": \"text\"\n    },\n    \"Description\": {\n      \"default\": null,\n      \"notafield\": false,\n      \"fielddefinition\": {\n        \"fieldtype\": \"TextArea\",\n        \"label\": \"Description\"\n      },\n      \"fieldapi\": \"account.description\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"interfaceclass\": \"StripeMutationCapsule\",\n        \"metadata\": {}\n      },\n      \"cartridgetype\": \"objectasis\"\n    }\n  }\n}';
        md.Membrane__c ='{\n  \"SKIPFORDMA\": false,\n  \"extrafields\": [\n    \"AccountSource\"\n  ],\n  \"sobjectdefinition\": {\n    \"namefieldlabel\": \"Name\",\n    \"namefieldtype\": \"Text\",\n    \"defaultrecordtype\": \"\",\n    \"label\": \"account\"\n  },\n  \"sobject\": \"account\",\n  \"externalsourcepk\": \"\",\n  \"externalidfield\": \"Id\",\n  \"membrane\": {\n    \"Contacts\": {\n      \"membrane\": {\n        \"LastName\": {\n          \"default\": null,\n          \"notafield\": false,\n          \"fielddefinition\": {\n            \"fieldtype\": \"Text\",\n            \"label\": \"LastName\"\n          },\n          \"fieldapi\": \"Contact.lastname\",\n          \"SKIPFORDMA\": false,\n          \"notakey\": false,\n          \"readonly\": false,\n          \"mutationcapsule\": {\n            \"interfaceclass\": \"\",\n            \"metadata\": {}\n          },\n          \"cartridgetype\": \"text\"\n        },\n        \"HasOptedOutOfFax\": {\n          \"default\": null,\n          \"notafield\": false,\n          \"fielddefinition\": {\n            \"fieldtype\": \"Checkbox\",\n            \"label\": \"HasOptedOutOfFax\"\n          },\n          \"fieldapi\": \"Contact.HasOptedOutOfFax\",\n          \"SKIPFORDMA\": false,\n          \"notakey\": false,\n          \"readonly\": false,\n          \"mutationcapsule\": {\n            \"interfaceclass\": \"\",\n            \"metadata\": {}\n          },\n          \"cartridgetype\": \"boolean\"\n        }\n      },\n      \"lookupfield\": \"Contact.accountid\",\n      \"relationship\": \"Contacts\",\n      \"default\": null,\n      \"externalsourcepk\": \"\",\n      \"externalidfield\": \"\",\n      \"sobjectdefinition\": {\n        \"namefieldlabel\": \"Name\",\n        \"namefieldtype\": \"AutoNumber\",\n        \"defaultrecordtype\": \"\",\n        \"label\": \"Contact\"\n      },\n      \"extrafields\": [],\n      \"sobject\": \"Contact\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"interfaceclass\": \"\",\n        \"metadata\": {}\n      },\n      \"cartridgetype\": \"array\"\n    },\n    \"Custom Field\": {\n      \"default\": null,\n      \"notafield\": true,\n      \"fielddefinition\": {\n        \"fieldtype\": \"Text\",\n        \"label\": \"Custom Field\"\n      },\n      \"fieldapi\": \"account.mxf_CustomField__c\",\n      \"SKIPFORDMA\": true,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"metadata\": {},\n        \"interfaceclass\": \"\"\n      },\n      \"cartridgetype\": \"text\"\n    },\n    \"Parent\": {\n      \"membrane\": {\n        \"Site\": {\n          \"default\": null,\n          \"notafield\": false,\n          \"fielddefinition\": {\n            \"fieldtype\": \"Text\",\n            \"label\": \"Site\"\n          },\n          \"fieldapi\": \"account.site\",\n          \"SKIPFORDMA\": false,\n          \"notakey\": false,\n          \"readonly\": false,\n          \"mutationcapsule\": {\n            \"metadata\": {},\n            \"interfaceclass\": \"\"\n          },\n          \"cartridgetype\": \"text\"\n        }\n      },\n      \"default\": null,\n      \"lookupfield\": \"account.parentid\",\n      \"externalsourcepk\": \"\",\n      \"externalidfield\": \"\",\n      \"sobjectdefinition\": {\n        \"namefieldlabel\": \"Name\",\n        \"namefieldtype\": \"Text\",\n        \"defaultrecordtype\": \"\",\n        \"label\": \"account\"\n      },\n      \"extrafields\": [\n        \"AccountSource\"\n      ],\n      \"sobject\": \"account\",\n      \"relationship\": \"Parent\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"metadata\": {},\n        \"interfaceclass\": \"\"\n      },\n      \"cartridgetype\": \"object\"\n    },\n    \"Site\": {\n      \"default\": null,\n      \"notafield\": false,\n      \"fielddefinition\": {\n        \"fieldtype\": \"Text\",\n        \"label\": \"Site\"\n      },\n      \"fieldapi\": \"account.Site\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"interfaceclass\": \"\",\n        \"metadata\": {}\n      },\n      \"cartridgetype\": \"text\"\n    },\n    \"Description\": {\n      \"default\": null,\n      \"notafield\": false,\n      \"fielddefinition\": {\n        \"fieldtype\": \"TextArea\",\n        \"label\": \"Description\"\n      },\n      \"fieldapi\": \"account.description\",\n      \"SKIPFORDMA\": false,\n      \"notakey\": false,\n      \"readonly\": false,\n      \"mutationcapsule\": {\n        \"metadata\": {},\n        \"interfaceclass\": \"StripeMutationCapsule\"\n      },\n      \"cartridgetype\": \"objectasis\"\n    }\n  }\n}';
        md.Membrane_External_Data_Source__c = source.Id;
        // Populate md fields as required
        mds.add(md);
        insert mds;

        Account pa = new Account(Name='Parent Test Account',Site='Parent Test Site');
        insert pa;

        Account a = new Account(Name='Test Account',Site='Test Site', ParentId=pa.Id,Description='{\"key\":\"value\"}');
        insert a;

        Contact c = new Contact(LastName = 'Test Contact',AccountId=a.Id);
        insert c;


        Membrane_Health_Check__c hc = new Membrane_Health_Check__c(
            membrane__c = md.Membrane__c,
            sample_json__c = jsonInput,
            record_id__c = a.Id,
            Membrane_Definition__c = md.Id
        );
        insert hc;
        
    }

    @isTest
    static void testUpdateHealthCheck() {

        Membrane_Health_Check__c hc =  [SELECT Id FROM Membrane_Health_Check__c LIMIT 1];
        

        MembraneHealthCheckAutomation.MembraneRequest request = new MembraneHealthCheckAutomation.MembraneRequest();
        request.healthcheckId = hc.Id;
        request.generateJson = true;

        List<MembraneHealthCheckAutomation.MembraneRequest> requestList = new List<MembraneHealthCheckAutomation.MembraneRequest>();
        requestList.add(request);

        // Call the updateHealthCheck method
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        List<MembraneHealthCheckAutomation.MembraneResult> results = MembraneHealthCheckAutomation.updateHealthCheck(requestList);
        Test.stopTest();

    }

    // Mock response class for HTTP callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class WebServiceMockImpl implements WebServiceMock 
	{
		public void doInvoke(
			Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName,
			String responseNS, String responseName, String responseType) 
		{
			if(request instanceof MetadataService.retrieve_element)
				response.put('response_x', new MetadataService.retrieveResponse_element());
			else if(request instanceof MetadataService.checkDeployStatus_element)
				response.put('response_x', new MetadataService.checkDeployStatusResponse_element());
			else if(request instanceof MetadataService.listMetadata_element)
				response.put('response_x', new MetadataService.listMetadataResponse_element());
			else if(request instanceof MetadataService.checkRetrieveStatus_element)
				response.put('response_x', new MetadataService.checkRetrieveStatusResponse_element());
			else if(request instanceof MetadataService.describeMetadata_element)
				response.put('response_x', new MetadataService.describeMetadataResponse_element());
			else if(request instanceof MetadataService.deploy_element)
				response.put('response_x', new MetadataService.deployResponse_element());
            else if(request instanceof MetadataService.updateMetadata_element)
                response.put('response_x', new MetadataService.updateMetadataResponse_element());
            else if(request instanceof MetadataService.renameMetadata_element)
                response.put('response_x', new MetadataService.renameMetadataResponse_element());
            else if(request instanceof  MetadataService.cancelDeploy_element)
                response.put('response_x', new MetadataService.cancelDeployResponse_element());
            else if(request instanceof  MetadataService.deleteMetadata_element)
                response.put('response_x', new MetadataService.deleteMetadataResponse_element());
            else if(request instanceof  MetadataService.upsertMetadata_element)
                response.put('response_x', new MetadataService.upsertMetadataResponse_element());
            else if(request instanceof  MetadataService.createMetadata_element)
                response.put('response_x', new MetadataService.createMetadataResponse_element());
            else if(request instanceof  MetadataService.deployRecentValidation_element)
                response.put('response_x', new MetadataService.deployRecentValidationResponse_element());
            else if(request instanceof MetadataService.describeValueType_element)
                response.put('response_x', new MetadataService.describeValueTypeResponse_element());
            else if(request instanceof MetadataService.checkRetrieveStatus_element)
                response.put('response_x', new MetadataService.checkRetrieveStatusResponse_element());
			return;
		}
	} 
    
    @isTest
    static void testCreateObjectsOperation() {

        List<Membrane_Definition__c> mds = [SELECT Id, Sample_JSON__c, Membrane__c, Membrane_External_Data_Source__r.Name FROM Membrane_Definition__c];
        
        // Create the queueable job instance
        //MembraneDataModelQueueable queueable = new MembraneDataModelQueueable(mds, 'createobject', false);
        MembraneDataModelQueueable queueable = new MembraneDataModelQueueable
        (
            'createobject', 
            new List<MetadataService.Metadata>(),
            new List<MetadataService.CustomField>(),
            new List<MetadataService.Metadata>(),
            false,
            true
        );
        queueable.mds = mds;


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        Account pa = new Account(Name='Parent Test Account',Site='Parent Test Site');
        insert pa;

        Account a = new Account(Name='Test Account',Site='Test Site', ParentId=pa.Id,Description='{\"key\":\"value\"}');
        insert a;

        Contact c = new Contact(LastName = 'Test Contact',AccountId=a.Id);
        insert c;
        Osmosis.generateJson(a.Id, mds[0].membrane__c);
        Osmosis.createFieldSecurity('Name');
        MembrameMemory.getNamespacePrefix();
        // Execute the queueable job
        System.enqueueJob(queueable);
        Test.stopTest();

        // Add assertions as needed to verify expected behavior
        // Example: Check that the fields creation logic works as expected
        // Example assertion: System.assertEquals(expectedValue, actualValue, 'Failure message');
    }

    @isTest
    static void testCreateObjectsOperationOne() {

        List<Membrane_Definition__c> mds = [SELECT Id, Sample_JSON__c, Membrane__c, Membrane_External_Data_Source__r.Name FROM Membrane_Definition__c];
        
        // Create the queueable job instance
        //MembraneDataModelQueueable queueable = new MembraneDataModelQueueable(mds, 'createobject', false);
        MembraneDataModelQueueable queueable = new MembraneDataModelQueueable
        (
            'createobject', 
            new List<MetadataService.Metadata>(),
            new List<MetadataService.CustomField>(),
            new List<MetadataService.Metadata>(),
            false,
            false
        );
        queueable.mds = mds;


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        Account pa = new Account(Name='Parent Test Account',Site='Parent Test Site');
        insert pa;

        Account a = new Account(Name='Test Account',Site='Test Site', ParentId=pa.Id,Description='{\"key\":\"value\"}');
        insert a;

        Contact c = new Contact(LastName = 'Test Contact',AccountId=a.Id);
        insert c;
        Osmosis.generateJson(a.Id, mds[0].membrane__c);
        Osmosis.createFieldSecurity('Name');
        MembrameMemory.getNamespacePrefix();
        // Execute the queueable job
        System.enqueueJob(queueable);
        Test.stopTest();

    }


    // Positive test case for 'createfields' operation
    @isTest
    static void testCreateFieldsOperation() {

        List<Membrane_Definition__c> mds = [SELECT Id, Sample_JSON__c, Membrane__c,  Membrane_External_Data_Source__r.Name FROM Membrane_Definition__c];
        
        // Create the queueable job instance
        MembraneDataModelQueueable queueable = new MembraneDataModelQueueable(mds, 'createfields', false);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        MembrameMemory.getNamespacePrefix();
        // Execute the queueable job
        System.enqueueJob(queueable);
        Test.stopTest();

        // Add assertions as needed to verify expected behavior
        // Example: Check that the fields creation logic works as expected
        // Example assertion: System.assertEquals(expectedValue, actualValue, 'Failure message');
    }


    // Positive test case for 'compositegraphrequest' operation
    @isTest
    static void testCompositeGraphRequestOperation() {
    

        List<Membrane_Definition__c> mds = [SELECT Id, Sample_JSON__c, Membrane__c,  Membrane_External_Data_Source__r.Name FROM Membrane_Definition__c];

        // Create the queueable job instance
        MembraneDataModelQueueable queueable = new MembraneDataModelQueueable(mds, 'compositegraphrequest', false);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Execute the queueable job
        System.enqueueJob(queueable);
        Test.stopTest();

        // Add assertions as needed to verify expected behavior
        // Example: Check that the composite graph request logic works as expected
        // Example assertion: System.assertEquals(expectedValue, actualValue, 'Failure message');
    }

    // Test case for validation mode (isValidationOnly = true)
    @isTest
    static void testValidationMode() {
        List<Membrane_Definition__c> mds = [SELECT Id, Sample_JSON__c, Membrane__c,Membrane_External_Data_Source__r.Name FROM Membrane_Definition__c];
        
        // Create the queueable job instance for validation mode
        MembraneDataModelQueueable queueable = new MembraneDataModelQueueable
        (
            '', 
            new List<MetadataService.Metadata>(),
            new List<MetadataService.CustomField>(),
            new List<MetadataService.Metadata>(),
            true,
            true
        );
        queueable.mds = mds;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Execute the queueable job
        System.enqueueJob(queueable);
        Test.stopTest();

        // Add assertions as needed to verify behavior in validation mode
        // Example: Check that no actual metadata changes are made in validation mode
        // Example assertion: System.assertEquals(expectedValue, actualValue, 'Failure message');
    }

    @isTest
    static void testValidationModeOne() {
        List<Membrane_Definition__c> mds = [SELECT Id, Sample_JSON__c, Membrane__c,  Membrane_External_Data_Source__r.Name FROM Membrane_Definition__c];
        
        // Create the queueable job instance for validation mode
        MembraneDataModelQueueable queueable = new MembraneDataModelQueueable
        (
            '', 
            new List<MetadataService.Metadata>(),
            new List<MetadataService.CustomField>(),
            new List<MetadataService.Metadata>(),
            true,
            false
        );
        queueable.mds = mds;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Execute the queueable job
        System.enqueueJob(queueable);
        Test.stopTest();

    }
}