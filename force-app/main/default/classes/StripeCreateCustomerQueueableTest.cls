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
    static void testCreateStripeCustomerAPIResponseFailure() {
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
            MailingPostalCode = '12345',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;
        
        testContact.Stripe_Customer_ID__c = null;
        update testContact;
        
        Test.getEventBus().deliver();
        
        Set<Id> contactIds = new Set<Id>{testContact.Id};
        Test.setMock(HttpCalloutMock.class, StripeMock.customerExists());
        Test.startTest();
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(null, updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null when customer already exists in Stripe');
    }
}