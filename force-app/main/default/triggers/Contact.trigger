trigger Contact on Contact (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        new ContactTriggerHandler().afterInsert(Trigger.new, Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        new ContactTriggerHandler().afterUpdate(Trigger.new, Trigger.oldMap);
    }
}