public with sharing class ErrorLogger {
    public static void logError(
        String message,
        String comment,
        String contextType,
        String errorClass,
        String stackTrace
    ) {
        Log_Entry__c logEntry = new Log_Entry__c();
        logEntry.Error_Message__c = message;
        logEntry.Comment__c = comment;
        logEntry.Context_Type__c = contextType;
        logEntry.Error_Class__c = errorClass;
        logEntry.Stack_Trace__c = stackTrace;
        insert logEntry;
    }

    public static void logError(Exception exceptionToLog) {
        logError(
            exceptionToLog.getMessage(), 
            String.valueOf(exceptionToLog.getLineNumber()), 
            '', 
            '', 
            exceptionToLog.getStackTraceString()
        );
    }
}