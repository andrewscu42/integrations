@isTest
public class ErrorLogCleanupBatchTest {

    @isTest
    static void testErrorLogCleanupBatch() {
        Log_Entry__c logEntry = new Log_Entry__c(
            Error_Message__c = 'Test error message',
            Comment__c = 'Test comment',
            Context_Type__c = 'Trigger',
            Error_Class__c = 'Test error class',
            Stack_Trace__c = 'Test stack trace',
            Keep_Long_Term__c = false
        );
        insert logEntry;
        
        Test.setCreatedDate(logEntry.Id, DateTime.now().addDays(-20));
        
        Test.startTest();
        ErrorLogCleanupBatch batch = new ErrorLogCleanupBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        List<Log_Entry__c> logEntries = [SELECT Id FROM Log_Entry__c WHERE Id = :logEntry.Id];
        System.assertEquals(0, logEntries.size(), 'Log entry should have been deleted');
    }
}