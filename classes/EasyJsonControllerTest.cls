@isTest
private class EasyJsonControllerTest {

    // Positive test case for getObjects method
    @isTest
    static void testGetObjects() {
        Test.startTest();
        List<String> objectList = EasyJsonController.getObjects();
        Test.stopTest();

        // Add assertions to verify the expected behavior
        System.assertNotEquals(null, objectList, 'Object list should not be null');
        System.assertNotEquals(0, objectList.size(), 'Object list should not be empty');
        // Add additional assertions based on your specific requirements
    }

    // Test case for getFields method with valid input
    @isTest
    static void testGetFieldsValidInput() {
        Test.startTest();
        List<String> fieldList = EasyJsonController.getFields('Account');
        Test.stopTest();

        // Add assertions to verify the expected behavior
        System.assertNotEquals(null, fieldList, 'Field list should not be null');
        // Add additional assertions based on your specific requirements
    }

    // Test case for getFields method with invalid input
    @isTest
    static void testGetFieldsInvalidInput() {
        Test.startTest();
        List<String> fieldList = EasyJsonController.getFields('NonExistingObject');
        Test.stopTest();

        // Add assertions to verify the expected behavior
        System.assertEquals(0, fieldList.size(), 'Field list should be empty for non-existing object');
        // Add additional assertions based on your specific requirements
    }

    // Test case for getSobjectRecordTypes method with valid input
    @isTest
    static void testGetSobjectRecordTypesValidInput() {
        Test.startTest();
        List<String> rtList = EasyJsonController.getSobjectRecordTypes('Account');
        Test.stopTest();

        // Add assertions to verify the expected behavior
        System.assertNotEquals(null, rtList, 'Record Type list should not be null');
        // Add additional assertions based on your specific requirements
    }

    // Test case for getSobjectRecordTypes method with invalid input
    @isTest
    static void testGetSobjectRecordTypesInvalidInput() {
        Test.startTest();
        List<String> rtList = EasyJsonController.getSobjectRecordTypes('NonExistingObject');
        Test.stopTest();

        // Add assertions to verify the expected behavior
        System.assertEquals(0, rtList.size(), 'Record Type list should be empty for non-existing object');
        // Add additional assertions based on your specific requirements
    }

    // Positive test case for getJSONString method
    @isTest
    static void testGetJSONString() {
        Test.startTest();
        // Create a test record (e.g., Account)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Get JSON string for the created record
        String jsonString = EasyJsonController.getJSONString(testAccount.Id, 'Name');
        Test.stopTest();

        // Add assertions to verify the expected behavior
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
        // Add additional assertions based on your specific requirements
    }

    
}