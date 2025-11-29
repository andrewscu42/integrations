
@isTest
public class ErrorLoggerTest {
    @isTest
    static void testLogErrorCreatesLogEntry() {
        String expectedMessage = 'NullPointerException: Attempt to dereference a null object';
        String expectedComment = 'Line 123';
        String expectedContextType = 'Trigger';
        String expectedErrorClass = 'ContactTriggerHandler';
        String expectedStackTrace = 'System.NullPointerException: Attempt to dereference a null object (line 123, file ContactTriggerHandler.cls)';

        Test.startTest();
        ErrorLogger.logError(
            expectedMessage, 
            expectedComment, 
            expectedContextType, 
            expectedErrorClass, 
            expectedStackTrace
        );
        Test.stopTest();

        Log_Entry__c[] logEntries = [SELECT Error_Message__c, Comment__c, Context_Type__c, Error_Class__c, Stack_Trace__c FROM Log_Entry__c];
        System.assertEquals(1, logEntries.size(), 'A single Log_Entry__c record should have been created.');
        Log_Entry__c entry = logEntries[0];

        System.assertEquals(expectedMessage, entry.Error_Message__c, 'Error_Message__c should be populated.');
        System.assertEquals(expectedComment, entry.Comment__c, 'Comment__c should be populated.');
        System.assertEquals(expectedContextType, entry.Context_Type__c, 'Context_Type__c should be used.');
        System.assertEquals(expectedErrorClass, entry.Error_Class__c, 'Error_Class__c should be populated.');
        System.assertEquals(expectedStackTrace, entry.Stack_Trace__c, 'Stack_Trace__c should be populated.');
    }

    @isTest
    static void testLogErrorWithException() {
        Test.startTest();
        try {
            String nullString = null;
            Integer length = nullString.length();
        } catch (Exception e) {
            ErrorLogger.logError(e);
        }
        Test.stopTest();

        Log_Entry__c[] logEntries = [SELECT Error_Message__c, Comment__c, Stack_Trace__c FROM Log_Entry__c];
        System.assertEquals(1, logEntries.size(), 'A single Log_Entry__c record should have been created.');
        Log_Entry__c entry = logEntries[0];
        System.assertNotEquals(null, entry.Error_Message__c, 'Error_Message__c should be populated from exception.');
        System.assertNotEquals(null, entry.Stack_Trace__c, 'Stack_Trace__c should be populated from exception.');
    }
}