// Delete all cfp_DataGroups__c records in the target org.
// Run: sf apex run -f scripts/delete-all-datagroups.apex -o home-denispoc
List<cfp_DataGroups__c> all = [SELECT Id FROM cfp_DataGroups__c];
System.debug('Deleting ' + all.size() + ' cfp_DataGroups__c records');
delete all;
System.debug('Done.');
