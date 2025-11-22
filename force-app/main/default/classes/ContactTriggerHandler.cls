public class ContactTriggerHandler {
    public void afterInsert(List<Contact> newContacts, Map<Id, Contact> newMap) {
        Set<Id> contactIds = newMap.keySet();
        System.enqueueJob(new StripeCreateCustomerQueueable(contactIds));
    }
    public void afterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact contact : newContacts) {
            if (oldContacts.containsKey(contact.Id) && 
                contact.Email != oldContacts.get(contact.Id).Email) {
                contactIds.add(contact.Id);
            }
        }
        System.enqueueJob(new StripeCreateCustomerQueueable(contactIds));
    }
    
    public void generatePaymentLinks(Set<Id> contactIds) {
        System.enqueueJob(new PaymentLinkQueueable(contactIds));
    }
}
