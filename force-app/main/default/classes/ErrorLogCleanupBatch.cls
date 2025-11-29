public with sharing class ErrorLogCleanupBatch implements Database.Batchable<Log_Entry__c> {
    public Iterable<Log_Entry__c> start(Database.BatchableContext bc) {
        return [
            SELECT Id 
            FROM Log_Entry__c 
            WHERE CreatedDate <= LAST_N_DAYS:15 
            AND Keep_Long_Term__c = false
        ];
    }

    public void execute(Database.BatchableContext bc, List<Log_Entry__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Error log cleanup batch completed');
    }
}