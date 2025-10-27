trigger CustomerTrigger on Customer__c (after insert, after update) {
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        DuplicateMatcher.findDuplicates(Trigger.new);
    }
}