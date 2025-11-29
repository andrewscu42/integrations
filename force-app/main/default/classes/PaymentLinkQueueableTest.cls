
@isTest
private class PaymentLinkQueueableTest {

    @isTest
    static void testGeneratePaymentLinkSuccess() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        PaymentLinkQueueable queueable = new PaymentLinkQueueable(contactIds);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Payment_Link__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('https://buy.stripe.com/test_link_123', updatedContact.Stripe_Payment_Link__c, 'Payment link should be set on contact');
    }
    
    @isTest
    static void testGeneratePaymentLinkWithCustomerCreation() {
        Contact testContact = new Contact(
            FirstName = 'New',
            LastName = 'Customer',
            Email = 'new.customer@example.com'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        PaymentLinkQueueable queueable = new PaymentLinkQueueable(contactIds);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Customer_ID__c, Stripe_Payment_Link__c FROM Contact WHERE Id = :testContact.Id];
        System.assertNotEquals(null, updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should be created');
        System.assertEquals('https://buy.stripe.com/test_link_123', updatedContact.Stripe_Payment_Link__c, 'Payment link should be set');
    }
    
    @isTest
    static void testGeneratePaymentLinkFailure() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Failure',
            Email = 'test.failure@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.failure());
        Test.startTest();
        PaymentLinkQueueable queueable = new PaymentLinkQueueable(contactIds);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Payment_Link__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(null, updatedContact.Stripe_Payment_Link__c, 'Payment link should remain null on failure');
        
        List<Log_Entry__c> logEntries = [
            SELECT Error_Message__c, Context_Type__c, Error_Class__c 
            FROM Log_Entry__c 
            WHERE Error_Class__c = 'PaymentLinkQueueable'
        ];
        System.assert(logEntries.size() > 0, 'Error should be logged');
        System.assertEquals('Queueable', logEntries[0].Context_Type__c, 'Context type should be Queueable');
    }
    
    @isTest
    static void testGeneratePaymentLinkMultipleContacts() {
        Contact contact1 = new Contact(
            FirstName = 'Contact',
            LastName = 'One',
            Email = 'contact1@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        Contact contact2 = new Contact(
            FirstName = 'Contact',
            LastName = 'Two',
            Email = 'contact2@example.com',
            Stripe_Customer_ID__c = 'cus_test456'
        );
        insert new List<Contact>{contact1, contact2};
        
        Set<Id> contactIds = new Set<Id>{contact1.Id, contact2.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        PaymentLinkQueueable queueable = new PaymentLinkQueueable(contactIds);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        List<Contact> updatedContacts = [
            SELECT Stripe_Payment_Link__c 
            FROM Contact 
            WHERE Id IN :contactIds
        ];
        System.assertEquals(2, updatedContacts.size(), 'Both contacts should be updated');
        for (Contact contact : updatedContacts) {
            System.assertEquals('https://buy.stripe.com/test_link_123', contact.Stripe_Payment_Link__c, 'Payment link should be set');
        }
    }

    @isTest
    static void testGeneratePaymentLinkOuterCatchBlock() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'OuterCatch',
            Email = 'test.outercatch@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        
        Test.setMock(HttpCalloutMock.class, StripeMock.longUrl());
        Test.startTest();
        PaymentLinkQueueable queueable = new PaymentLinkQueueable(contactIds);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        List<Log_Entry__c> allLogEntries = [
            SELECT Error_Message__c, Context_Type__c, Error_Class__c, Comment__c
            FROM Log_Entry__c 
            WHERE Error_Class__c = 'PaymentLinkQueueable'
        ];
        
        Log_Entry__c outerCatchLog = null;
        for (Log_Entry__c logEntry : allLogEntries) {
            if (logEntry.Comment__c != null && 
                logEntry.Comment__c.contains('Failed to generate payment links for Contact IDs') &&
                logEntry.Comment__c.contains(String.valueOf(testContact.Id))) {
                outerCatchLog = logEntry;
                break;
            }
        }
        
        System.assertNotEquals(null, outerCatchLog, 'Error should be logged in outer catch block');
        System.assertEquals('Queueable', outerCatchLog.Context_Type__c, 'Context type should be Queueable');
        System.assertEquals('PaymentLinkQueueable', outerCatchLog.Error_Class__c, 'Error class should be PaymentLinkQueueable');
        System.assert(outerCatchLog.Comment__c.contains(String.valueOf(testContact.Id)), 'Comment should contain Contact ID');
    }
}