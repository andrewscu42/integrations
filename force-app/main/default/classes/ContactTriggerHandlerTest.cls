@isTest
private class ContactTriggerHandlerTest {
    
    @isTest
    static void testAfterInsertWithNullList() {
        ContactTriggerHandler handler = new ContactTriggerHandler();
        
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        Test.startTest();
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
        
        Test.setMock(HttpCalloutMock.class, new StripeFailureMock());
        Test.startTest();
        try {
            handler.afterInsert(emptyList);
            System.assert(false, 'Expected EmptyContactListException was not thrown');
        } catch (EmptyContactListException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterInsertWithValidContacts() {
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Contact1', Email = 'test1@example.com'),
            new Contact(FirstName = 'Test', LastName = 'Contact2', Email = 'test2@example.com')
        };
        insert contacts;
        
        contacts = [SELECT Id FROM Contact WHERE Email IN ('test1@example.com', 'test2@example.com')];
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
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
        
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
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
        
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
        try {
            handler.afterUpdate(emptyList, oldMap);
            System.assert(false, 'Expected EmptyContactListException was not thrown');
        } catch (EmptyContactListException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdateWithEmailChange() {
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'oldemail@example.com');
        insert contact;
        
        contact = [SELECT Id, Email FROM Contact WHERE Id = :contact.Id];
        Map<Id, Contact> oldMap = new Map<Id, Contact>{
            contact.Id => new Contact(Id = contact.Id, Email = 'oldemail@example.com')
        };
        contact.Email = 'newemail@example.com';
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
        handler.afterUpdate(new List<Contact>{contact}, oldMap);
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
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert contact;
        
        Map<Id, Contact> oldMap = new Map<Id, Contact>{
            contact.Id => new Contact(Id = contact.Id, Email = contact.Email)
        };
        
        ContactTriggerHandler handler = new ContactTriggerHandler();
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
        handler.afterUpdate(new List<Contact>{contact}, oldMap);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(jobs.size() > 0, 'Queueable job should have been enqueued even when email does not change');
    }
    
    @isTest
    static void testTriggerAfterInsert() {
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
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
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
        Contact contactToUpdate = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'original@example.com');
        insert contactToUpdate;
        
        contactToUpdate = [SELECT Id, Email FROM Contact WHERE Id = :contactToUpdate.Id];
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
        Test.setMock(HttpCalloutMock.class, new StripeSuccessMock());
        Test.startTest();
        Contact contactToUpdate = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert contactToUpdate;
        
        contactToUpdate = [SELECT Id, FirstName FROM Contact WHERE Id = :contactToUpdate.Id];
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
