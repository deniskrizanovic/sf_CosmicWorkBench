@IsTest
private class cfp_DataGroupExternalIdBackfillTest {
    private static cfp_System_Context__c createSystemContext(String name) {
        cfp_System_Context__c sysCtx = new cfp_System_Context__c(Name = name);
        insert sysCtx;
        return sysCtx;
    }

    @IsTest
    static void testDryRunDoesNotUpdateButReportsCounts() {
        cfp_System_Context__c sysCtx = createSystemContext('Backfill DryRun Context');
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'WorkOrder',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = sysCtx.Id,
            cfp_External_Id__c = null
        );
        insert dg;

        cfp_DataGroupExternalIdBackfill.Result result =
            cfp_DataGroupExternalIdBackfill.runBackfill(false);

        System.assert(result.scannedCount > 0, 'Should scan Data Groups.');
        System.assertEquals(0, result.updatedCount, 'Dry run should never update records.');

        cfp_DataGroups__c reloaded = [
            SELECT cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE Id = :dg.Id
        ];
        System.assertEquals(sysCtx.Name.toLowerCase() + '|workorder', reloaded.cfp_External_Id__c,
            'Dry run must not change already-canonical values.');
    }

    @IsTest
    static void testApplyModeUpdatesExternalId() {
        cfp_System_Context__c sysCtx = createSystemContext('Backfill Apply Context');
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'Case',
            cfp_Object_Name__c = 'Case',
            cfp_System_Context__c = sysCtx.Id,
            cfp_External_Id__c = null
        );
        insert dg;

        cfp_DataGroupExternalIdBackfill.Result result =
            cfp_DataGroupExternalIdBackfill.runBackfill(true);

        System.assert(result.updatedCount >= 0, 'Apply mode should complete successfully.');

        cfp_DataGroups__c reloaded = [
            SELECT cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE Id = :dg.Id
        ];
        System.assertEquals(sysCtx.Name.toLowerCase() + '|case', reloaded.cfp_External_Id__c);
    }

    @IsTest
    static void testBackfillUsesObjectNameNotRecordName() {
        cfp_System_Context__c sysCtx = createSystemContext('Backfill ObjectName Context');
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'Work Orders (Custom Label)',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = sysCtx.Id,
            cfp_External_Id__c = 'stale|value'
        );
        insert dg;

        cfp_DataGroupExternalIdBackfill.runBackfill(true);

        cfp_DataGroups__c reloaded = [
            SELECT cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE Id = :dg.Id
        ];
        System.assertEquals(
            sysCtx.Name.toLowerCase() + '|workorder',
            reloaded.cfp_External_Id__c,
            'Backfill should key on cfp_Object_Name__c, not Name.'
        );
    }
}
