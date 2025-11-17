public with sharing class PaymentLinkQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> contactIds;

    public PaymentLinkQueueable(Set<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public void execute(QueueableContext context) {
        generateLinkAndUpdateContacts();
    }

    public void generateLinkAndUpdateContacts() {
        ContactQueries contactQueries = new ContactQueries();
        List<Contact> contactsToUpdate = contactQueries.queryContactsByIds(contactIds);

        for (Contact contact : contactsToUpdate) {
            PaymentLinkCallout linkCallout = new PaymentLinkCallout();
            String paymentLink = linkCallout.generateLink(contact);
            contact.Description = 'Payment Link: ' + paymentLink;
        }

        update contactsToUpdate;
    }
}

