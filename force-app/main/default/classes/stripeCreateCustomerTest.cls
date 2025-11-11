@isTest
private class stripeCreateCustomerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'john.doe@example.com',
                MailingStreet = '123 Main St',
                MailingPostalCode = '12345',
                Stripe_Customer_ID__c = 'cus_test123'
            ),
            new Contact(
                FirstName = 'Jane',
                LastName = 'Smith',
                Email = 'jane.smith@example.com',
                MailingStreet = '456 Oak Ave',
                MailingPostalCode = '67890'
            ),
            new Contact(
                FirstName = 'Bob',
                LastName = 'Wilson',
                Email = 'bob.wilson@example.com',
                Stripe_Customer_ID__c = 'cus_existing123'
            ),
            new Contact(
                FirstName = 'NoEmail',
                LastName = 'Email',
                Email = null,
                MailingStreet = '789 Pine St',
                MailingPostalCode = '10110'
            ),
            new Contact(
                FirstName = 'Invalid',
                LastName = 'Email2',
                Email = 'invalid.email@example.com.com',
                MailingStreet = '789 Pine St',
                MailingPostalCode = '10110'
            )
        };
        insert contacts;
    }
    
    @isTest
    static void testCreateStripeCustomerSuccess() {
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'jane.smith@example.com'];
        Set<Id> contactIds = new Set<Id>{contacts[0].Id};
        
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        
        Test.startTest();
        stripeCreateCustomer.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contacts[0].Id];
        System.assertEquals('cus_test123', updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should be set');
    }
    
    @isTest
    static void testCreateStripeCustomerAPIResponseFailure() {
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'jane.smith@example.com'];
        Set<Id> contactIds = new Set<Id>{contacts[0].Id};
        
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        
        Test.startTest();
        stripeCreateCustomer.createCustomersFromContacts(contactIds);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contacts[0].Id];
        System.assertEquals(null, updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null on failure');
    }
    
    @isTest
    static void testSkipContactWithExistingStripeId() {
        List<Contact> contacts = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Email = 'bob.wilson@example.com'];
        Set<Id> contactIds = new Set<Id>{contacts[0].Id};
        String originalStripeId = contacts[0].Stripe_Customer_ID__c;
        
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        
        Test.startTest();
        stripeCreateCustomer.createCustomersFromContacts(contactIds);
        Test.stopTest();
        
        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contacts[0].Id];
        System.assertEquals(originalStripeId, updatedContact.Stripe_Customer_ID__c, 'Existing Stripe Customer ID should not change');
    }
    @isTest
    static void testCreateStripeCustomerWithInvalidEmail() {
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = null OR Email = 'invalid.email@example.com.com'];
        Set<Id> contactIds = new Set<Id>{contacts[0].Id};
        
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        
        Test.startTest();
        stripeCreateCustomer.createCustomersFromContacts(contactIds);
        Test.stopTest();

        
        Contact updatedContactNoEmail = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contacts[0].Id];
        Contact updatedContactInvalidEmail = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contacts[1].Id];
        System.assertEquals(null, updatedContactNoEmail.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null for no email');
        System.assertEquals(null, updatedContactInvalidEmail.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null for invalid email');
    }
    @isTest
    static void customerWithSameEmailExists() {
        List<Contact> contacts = [SELECT Id, Stripe_Customer_ID__c FROM Contact WHERE Email = 'john.doe@example.com'];
        contacts[0].Stripe_Customer_ID__c = null;
        update contacts[0];
        
        Set<Id> contactIds = new Set<Id>{contacts[0].Id};
        
        Test.setMock(HttpCalloutMock.class, new StripeCustomerExistsMock());
        
        Test.startTest();
        stripeCreateCustomer.createCustomersFromContacts(contactIds);
        Test.stopTest();

        Contact updatedContact = [SELECT Stripe_Customer_ID__c FROM Contact WHERE Id = :contacts[0].Id];
        System.assertEquals(null, updatedContact.Stripe_Customer_ID__c, 'Stripe Customer ID should remain null when customer already exists in Stripe');
    }
}

