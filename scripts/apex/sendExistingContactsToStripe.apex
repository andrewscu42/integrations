// Script to retrieve existing Contacts and send them to Stripe
// Execute this in VS Code by running: SFDX: Execute Anonymous Apex with Editor Contents
// Or in Developer Console: Debug > Open Execute Anonymous Window

System.debug('=== Retrieving Existing Contacts ===');

// Query existing contacts EXCLUDING those already sent to Stripe
// Adjust the WHERE clause or LIMIT as needed
List<Contact> existingContacts = [
    SELECT Id, FirstName, LastName, Email, MailingStreet, MailingPostalCode, Stripe_Customer_ID__c
    FROM Contact
    WHERE Id = '003WT00000PwuUtYAJ'
];

if (existingContacts.isEmpty()) {
    System.debug('No contacts found. Please create contacts first using createContactsAndSendToStripe.apex');
} else {
    System.debug('Found ' + existingContacts.size() + ' contacts to process');
    
    // Display contacts that will be sent
    for (Contact c : existingContacts) {
        System.debug('Contact: ' + c.FirstName + ' ' + c.LastName + ' (ID: ' + c.Id + ')');
        System.debug('  Email: ' + c.Email);
        System.debug('  Address: ' + c.MailingStreet + ', ' + c.MailingPostalCode);
    }
    
    // Collect Contact IDs
    Set<Id> contactIds = new Set<Id>();
    for (Contact c : existingContacts) {
        contactIds.add(c.Id);
    }
    
    System.debug('');
    System.debug('=== Sending Contacts to Stripe ===');
    System.debug('Contact IDs to process: ' + contactIds);
    
    // Call the Queueable method to send contacts to Stripe
    stripeCreateCustomer.createCustomersFromContacts(contactIds);
    
    System.debug('');
    System.debug('=== Process Initiated ===');
    System.debug('The Queueable job has been enqueued.');
    System.debug('Check Debug Logs for async execution results.');
    System.debug('Stripe customers will be created asynchronously.');
    System.debug('');
    System.debug('To verify:');
    System.debug('1. Check Debug Logs for async job execution');
    System.debug('2. Check Stripe Dashboard: https://dashboard.stripe.com/test/customers');
}

