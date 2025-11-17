@isTest
private class ContactTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'Test',
                LastName = 'Contact1',
                Email = 'test1@example.com'
            ),
            new Contact(
                FirstName = 'Test',
                LastName = 'Contact2',
                Email = 'test2@example.com'
            )
        };
        insert contacts;
    }
    
    @isTest
    static void testAfterInsertWithNullList() {
        ContactTriggerHandler handler = new ContactTriggerHandler();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        try {
            handler.afterInsert(null);
            System.assert(false, 'Expected EmptyContactListException was not thrown');
        } catch (EmptyContactListException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterInsertWithEmptyList() {
        ContactTriggerHandler handler = new ContactTriggerHandler();
        List<Contact> emptyList = new List<Contact>();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        try {
            handler.afterInsert(emptyList);
            System.assert(false, 'Expected EmptyContactListException was not thrown');
        } catch (EmptyContactListException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterInsertWithValidContacts() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 2];
        ContactTriggerHandler handler = new ContactTriggerHandler();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        handler.afterInsert(contacts);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued');
    }
    
    @isTest
    static void testAfterUpdateWithNullList() {
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Map<Id, Contact> oldMap = new Map<Id, Contact>();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        try {
            handler.afterUpdate(null, oldMap);
            System.assert(false, 'Expected EmptyContactListException was not thrown');
        } catch (EmptyContactListException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdateWithEmptyList() {
        ContactTriggerHandler handler = new ContactTriggerHandler();
        List<Contact> emptyList = new List<Contact>();
        Map<Id, Contact> oldMap = new Map<Id, Contact>();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        try {
            handler.afterUpdate(emptyList, oldMap);
            System.assert(false, 'Expected EmptyContactListException was not thrown');
        } catch (EmptyContactListException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdateWithEmailChange() {
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 1];
        Contact originalContact = contacts[0];
        
        Map<Id, Contact> oldMap = new Map<Id, Contact>{
            originalContact.Id => new Contact(Id = originalContact.Id, Email = 'oldemail@example.com')
        };
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        handler.afterUpdate(contacts, oldMap);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued when email changes');
    }
    
    @isTest
    static void testAfterUpdateWithoutEmailChange() {
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 1];
        Contact originalContact = contacts[0];
        
        Map<Id, Contact> oldMap = new Map<Id, Contact>{
            originalContact.Id => new Contact(Id = originalContact.Id, Email = originalContact.Email)
        };
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        handler.afterUpdate(contacts, oldMap);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued even when email does not change');
    }
    
    @isTest
    static void testAfterUpdateWithMultipleContacts() {
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 2];
        
        Map<Id, Contact> oldMap = new Map<Id, Contact>{
            contacts[0].Id => new Contact(Id = contacts[0].Id, Email = 'oldemail1@example.com'),
            contacts[1].Id => new Contact(Id = contacts[1].Id, Email = contacts[1].Email)
        };
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        handler.afterUpdate(contacts, oldMap);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued');
    }
    
    @isTest
    static void testTriggerAfterInsert() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Contact newContact = new Contact(
            FirstName = 'Trigger',
            LastName = 'Test',
            Email = 'trigger@example.com'
        );
        insert newContact;
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued by trigger');
    }
    
    @isTest
    static void testTriggerAfterUpdateWithEmailChange() {
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 1];
        Contact contactToUpdate = contacts[0];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        contactToUpdate.Email = 'updated@example.com';
        update contactToUpdate;
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued by trigger when email changes');
    }
    
    @isTest
    static void testTriggerAfterUpdateWithoutEmailChange() {
        List<Contact> contacts = [SELECT Id, FirstName FROM Contact LIMIT 1];
        Contact contactToUpdate = contacts[0];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        contactToUpdate.FirstName = 'UpdatedName';
        update contactToUpdate;
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued by trigger even when email does not change');
    }
}
