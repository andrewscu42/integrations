public with sharing class PaymentLinkQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> contactIds;

    public PaymentLinkQueueable(Set<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public void execute(QueueableContext context) {
        generateLinkAndUpdateContacts();
    }

    public void generateLinkAndUpdateContacts() {
        try {
            ContactQueries contactQueries = new ContactQueries();
            List<Contact> contactsToUpdate = contactQueries.queryContactsByIds(contactIds);

            for (Contact contact : contactsToUpdate) {
                try {
                    PaymentLinkCallout linkCallout = new PaymentLinkCallout();
                    String paymentLink = linkCallout.generateLink(contact);
                    if (paymentLink != null) {
                        contact.Stripe_Payment_Link__c = paymentLink;
                    }
                } catch (Exception e) {
                    ErrorLogger.logError(
                        e.getMessage(),
                        'Failed to generate payment link for Contact ID: ' + contact.Id,
                        'Queueable',
                        'PaymentLinkQueueable',
                        e.getStackTraceString()
                    );
                }
            }

            update contactsToUpdate;
        } catch (Exception e) {
            List<String> contactIdStrings = new List<String>();
            for (Id contactId : contactIds) {
                contactIdStrings.add(String.valueOf(contactId));
            }
            ErrorLogger.logError(
                e.getMessage(),
                'Failed to generate payment links for Contact IDs: ' + String.join(contactIdStrings, ', '),
                'Queueable',
                'PaymentLinkQueueable',
                e.getStackTraceString()
            );
        }
    }
}
