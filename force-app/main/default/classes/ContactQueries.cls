public class ContactQueries {
    public List<Contact> queryContactsByIds(Set<Id> contactIds) {
        return [
            SELECT Id, FirstName, LastName, Email, 
            Stripe_Customer_ID__c, MailingStreet, MailingPostalCode
            FROM Contact
            WHERE Id IN :contactIds
        ];
    }
}

