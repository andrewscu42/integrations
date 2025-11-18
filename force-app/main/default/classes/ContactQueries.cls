public class ContactQueries {
    public List<Contact> queryContactsByIds(Set<Id> contactIds) {
        return [
            SELECT Id, FirstName, LastName, Email, 
            Stripe_Customer_ID__c, MailingStreet, MailingPostalCode,
            Stripe_Payment_Link__c
            FROM Contact
            WHERE Id IN :contactIds
        ];
    }
}

