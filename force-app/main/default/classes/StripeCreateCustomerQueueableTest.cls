@isTest
private class StripeCreateCustomerQueueableTest {
    
    @isTest
    static void testCreateStripeCustomerSuccess() {
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@example.com',
            MailingStreet = '456 Oak Ave',
            MailingPostalCode = '67890'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('cus_test123', updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should be set');
    }
    
    @isTest
    static void testNoAPIResponse() {
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@example.com',
            MailingStreet = '456 Oak Ave',
            MailingPostalCode = '67890'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        
        Test.setMock(HttpCalloutMock.class, StripeMock.failure());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(null, updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null on failure');
    }
    
    @isTest
    static void testSkipContactWithExistingStripeId() {
        Contact testContact = new Contact(
            FirstName = 'Bob',
            LastName = 'Wilson',
            Email = 'bob.wilson@example.com',
            Stripe_Customer_ID__c = 'cus_existing123'
        );
        insert testContact;
        
        String originalStripeId = testContact.Stripe_Customer_ID__c;
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(originalStripeId, updatedContact.Stripe_Customer_ID__c, 'Existing Stripe Customer ID should not change');
    }
    
    @isTest
    static void testCreateStripeCustomerWithInvalidEmail() {
        Contact contactNoEmail = new Contact(
            FirstName = 'NoEmail',
            LastName = 'Email',
            Email = null,
            MailingStreet = '789 Pine St',
            MailingPostalCode = '10110'
        );
        
        Contact contactInvalidEmail = new Contact(
            FirstName = 'Invalid',
            LastName = 'Email2',
            Email = 'invalid.email@example.com.com',
            MailingStreet = '789 Pine St',
            MailingPostalCode = '10110'
        );
        
        insert new List<Contact>{contactNoEmail, contactInvalidEmail};
        
        Set<Id> contactIds = new Set<Id>{contactNoEmail.Id, contactInvalidEmail.Id};
        
        Test.setMock(HttpCalloutMock.class, StripeMock.failure());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContactNoEmail = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contactNoEmail.Id];
        Contact updatedContactInvalidEmail = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contactInvalidEmail.Id];
        System.assertEquals(null, updatedContactNoEmail.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null for no email');
        System.assertEquals(null, updatedContactInvalidEmail.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null for invalid email');
    }
    
    @isTest
    static void customerWithSameEmailExists() {
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MailingStreet = '123 Main St',
            MailingPostalCode = '12345'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.customerExists());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('cus_existing123', updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should be set from existing customer search');
    }
    
    @isTest
    static void testFindStripeCustomerIdByEmailNotFound() {
        Contact testContact = new Contact(
            FirstName = 'New',
            LastName = 'Contact',
            Email = 'new.contact@example.com',
            MailingStreet = '456 New St',
            MailingPostalCode = '54321'
        );
        insert testContact;
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals('cus_test123', updatedContact.Stripe_Customer_ID__c, 'New Stripe Customer ID should be created when not found in search');
    }

    @isTest
    static void testUpdateStripeCustomerSuccess() {
        Contact testContact = new Contact(
            FirstName = 'Update',
            LastName = 'Test',
            Email = 'update.test@example.com',
            MailingStreet = '789 Update St',
            MailingPostalCode = '99999',
            Stripe_Customer_ID__c = 'cus_existing456'
        );
        insert testContact;
        
        StripeCreateCustomerQueueable queueable = new StripeCreateCustomerQueueable(new Set<Id>{testContact.Id});
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        String updatedCustomerId = queueable.updateStripeCustomer('cus_existing456', testContact);
        Test.stopTest();
        
        System.assertEquals('cus_test123', updatedCustomerId, 'Stripe Customer ID should be returned from update');
    }

    @isTest
    static void testExtractErrorMessage() {
        Map<String, Object> errorMap = new Map<String, Object>{
            'type' => 'invalid_request_error',
            'message' => 'Invalid email address'
        };
        Map<String, Object> responseMap = new Map<String, Object>{
            'error' => errorMap
        };
        
        StripeCreateCustomerQueueable queueable = new StripeCreateCustomerQueueable(new Set<Id>());
        Test.startTest();
        String errorMessage = queueable.extractErrorMessage(responseMap, 400);
        Test.stopTest();
        
        System.assert(errorMessage.contains('400'), 'Error message should contain status code');
        System.assert(errorMessage.contains('Invalid email address'), 'Error message should contain error message');
        System.assert(errorMessage.contains('invalid_request_error'), 'Error message should contain error type');
        
        List<Log_Entry__c> logEntries = [
            SELECT Error_Message__c, Context_Type__c, Error_Class__c 
            FROM Log_Entry__c
        ];

        System.assertEquals(1, logEntries.size(), 'Error should have been logged');
        
        Set<String> validContextTypes = new Set<String>{
            'Trigger', 'Batch', 'Queueable', 'Schedulable', 'Flow', 'REST', 'LWC', 'Integration'
        };
        
        System.assert(
            validContextTypes.contains(logEntries[0].Context_Type__c),
            'Context type should be set to a valid value. Was: ' + logEntries[0].Context_Type__c
        );
        System.assertEquals('StripeCreateCustomerQueueable', logEntries[0].Error_Class__c, 'Error class should be set correctly');
    }
}