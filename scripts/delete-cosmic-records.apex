// Delete System Context, Data Groups, and Functional Processes from home-denispoc.
// Order: Data Movements -> Functional Process -> Data Groups -> System Context (children first)
// Run: sf apex run -f scripts/delete-cosmic-records.apex -o home-denispoc
List<cfp_Data_Movements__c> dm = [SELECT Id FROM cfp_Data_Movements__c];
delete dm;
System.debug('Deleted ' + dm.size() + ' Data Movements');

List<cfp_FunctionalProcess__c> fp = [SELECT Id FROM cfp_FunctionalProcess__c];
delete fp;
System.debug('Deleted ' + fp.size() + ' Functional Processes');

List<cfp_DataGroups__c> dg = [SELECT Id FROM cfp_DataGroups__c];
delete dg;
System.debug('Deleted ' + dg.size() + ' Data Groups');

List<cfp_System_Context__c> sc = [SELECT Id FROM cfp_System_Context__c];
delete sc;
System.debug('Deleted ' + sc.size() + ' System Contexts');
