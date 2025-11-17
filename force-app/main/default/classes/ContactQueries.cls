public with sharing class ContactQueries {
    public static List<Contact> queryContactsByIds(Set<Id> contactIds) {
        return [
            SELECT Id, FirstName, LastName, Email, Description
            FROM Contact
            WHERE Id IN :contactIds
        ];
    }
}

