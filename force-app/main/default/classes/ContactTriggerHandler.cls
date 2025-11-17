public class ContactTriggerHandler {
    public void afterInsert(List<Contact> newContacts) {
        if (newContacts == null || newContacts.isEmpty()) {
            throw new EmptyContactListException('The contact list cannot be null or empty.');
        }
        
        Set<Id> contactIds = new Set<Id>();
        for (Contact contact : newContacts) {
            contactIds.add(contact.Id);
        }
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
    }
    public void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        if (newContacts == null || newContacts.isEmpty()) {
            throw new EmptyContactListException('The contact list cannot be null or empty.');
        }
        
        Set<Id> contactIds = new Set<Id>();
        for (Contact contact : newContacts) {
            if (contact.Email != oldContacts.get(contact.Id).Email) {
                contactIds.add(contact.Id);
            }
        }
        StripeCreateCustomerQueueable.createCustomersFromContacts(contactIds);
    }
    
    public static void generatePaymentLinks(Set<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            throw new EmptyContactListException('The contact ID set cannot be null or empty.');
        }
        System.enqueueJob(new PaymentLinkQueueable(contactIds));
    }
}
