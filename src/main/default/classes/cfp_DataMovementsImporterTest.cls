@IsTest
private class cfp_DataMovementsImporterTest {
    private static cfp_System_Context__c createSystemContext(String name) {
        cfp_System_Context__c sysCtx = new cfp_System_Context__c(Name = name);
        insert sysCtx;
        return sysCtx;
    }

    private static cfp_FunctionalProcess__c createFunctionalProcess(String name) {
        cfp_System_Context__c sysCtx = createSystemContext(name + ' Context');
        cfp_FunctionalProcess__c fp = new cfp_FunctionalProcess__c(
            Name = name,
            cfp_System_Context__c = sysCtx.Id
        );
        insert fp;
        return fp;
    }

    private static String getSystemContextName(cfp_FunctionalProcess__c fp) {
        return [SELECT Name FROM cfp_System_Context__c WHERE Id = :fp.cfp_System_Context__c LIMIT 1].Name;
    }

    private static String buildPayload() {
        return '{"dataMovements":[' +
            '{"name":"Open record page (WorkOrder)","order":1,"movementType":"E","dataGroupRef":"WorkOrder","implementationType":"flexipage","isApiCall":false,"artifactName":"WO_Record_Page"},' +
            '{"name":"Read page record (WorkOrder)","order":2,"movementType":"R","dataGroupRef":"WorkOrder","implementationType":"flexipage","isApiCall":false,"artifactName":"WO_Record_Page"}' +
        ']}';
    }

    private static String buildPayloadWithUnknownRef() {
        return '{"dataMovements":[' +
            '{"name":"Known ref","order":1,"movementType":"E","dataGroupRef":"WorkOrder","implementationType":"flexipage","isApiCall":false},' +
            '{"name":"Unknown ref","order":2,"movementType":"R","dataGroupRef":"UnknownObject","implementationType":"flexipage","isApiCall":false}' +
        ']}';
    }

    @IsTest
    static void testInsertModeCreatesRows() {
        cfp_FunctionalProcess__c fp = createFunctionalProcess('Importer Insert Mode');
        String expectedExternalId = getSystemContextName(fp).toLowerCase() + '|workorder';
        insert new cfp_DataGroups__c(
            Name = 'WorkOrder',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = fp.cfp_System_Context__c,
            cfp_External_Id__c = expectedExternalId
        );
        Integer beforeCount = [
            SELECT COUNT()
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
        ];

        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = fp.Id;
        req.jsonPayload = buildPayload();
        req.replaceExistingForProcess = false;

        Test.startTest();
        List<cfp_DataMovementsImporter.Response> results =
            cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);
        System.assertEquals(2, results[0].insertedCount);
        System.assertEquals(null, results[0].errorMessage);

        Integer afterCount = [
            SELECT COUNT()
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
        ];
        System.assertEquals(beforeCount + 2, afterCount, 'Importer should add exactly 2 rows.');

        List<cfp_Data_Movements__c> rows = [
            SELECT Name, cfp_order__c, cfp_movementtype__c, cfp_implementationtype__c, cfp_is_API_Call__c, cfp_FunctionalProcess__c, cfp_artifactName__c
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
            AND Name = 'Open record page (WorkOrder)'
            ORDER BY cfp_order__c ASC
        ];
        System.assert(rows.size() > 0, 'Expected imported row to exist.');
        System.assertEquals('Open record page (WorkOrder)', rows[0].Name);
        System.assertEquals(1, rows[0].cfp_order__c);
        System.assertEquals('E', rows[0].cfp_movementtype__c);
        System.assertEquals('Flexipage', rows[0].cfp_implementationtype__c, 'Expected picklist normalization from flexipage -> Flexipage');
        System.assertEquals(false, rows[0].cfp_is_API_Call__c);
        System.assertEquals('WO_Record_Page', rows[0].cfp_artifactName__c);
    }

    @IsTest
    static void testInsertModeAllowsDuplicatesAcrossRuns() {
        cfp_FunctionalProcess__c fp = createFunctionalProcess('Importer Duplicate Mode');
        String payload = buildPayload();
        Integer beforeCount = [
            SELECT COUNT()
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
        ];

        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = fp.Id;
        req.jsonPayload = payload;
        req.replaceExistingForProcess = false;

        Test.startTest();
        cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        Integer countRows = [
            SELECT COUNT()
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
        ];
        System.assertEquals(beforeCount + 4, countRows, 'Second run should insert another set in insert mode.');
    }

    @IsTest
    static void testReplaceModeDeletesExistingThenInserts() {
        cfp_FunctionalProcess__c fp = createFunctionalProcess('Importer Replace Mode');
        String payload = buildPayload();
        cfp_DataMovementsImporter.Request seedReq = new cfp_DataMovementsImporter.Request();
        seedReq.functionalProcessId = fp.Id;
        seedReq.jsonPayload = payload;
        seedReq.replaceExistingForProcess = false;
        cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ seedReq });

        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = fp.Id;
        req.jsonPayload = payload;
        req.replaceExistingForProcess = true;

        Test.startTest();
        List<cfp_DataMovementsImporter.Response> results =
            cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].success);
        System.assertEquals(2, results[0].insertedCount);

        List<cfp_Data_Movements__c> rows = [
            SELECT Name
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
        ];
        System.assertEquals(2, rows.size(), 'Replace mode should keep only freshly inserted rows.');
    }

    @IsTest
    static void testInvalidJsonReturnsError() {
        cfp_FunctionalProcess__c fp = createFunctionalProcess('Importer Invalid JSON');

        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = fp.Id;
        req.jsonPayload = 'not-json';

        Test.startTest();
        List<cfp_DataMovementsImporter.Response> results =
            cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage != null && results[0].errorMessage.length() > 0);
    }

    @IsTest
    static void testMissingFunctionalProcessIdReturnsError() {
        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = null;
        req.jsonPayload = buildPayload();

        Test.startTest();
        List<cfp_DataMovementsImporter.Response> results =
            cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].success);
        System.assert(results[0].errorMessage != null && results[0].errorMessage.length() > 0);
    }

    @IsTest
    static void testImporterLinksDataGroupByExternalId() {
        cfp_FunctionalProcess__c fp = createFunctionalProcess('Importer External Id Linking');
        String expectedExternalId = getSystemContextName(fp).toLowerCase() + '|workorder';
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'WorkOrder',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = fp.cfp_System_Context__c,
            cfp_External_Id__c = expectedExternalId
        );
        insert dg;

        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = fp.Id;
        req.jsonPayload = buildPayload();
        req.replaceExistingForProcess = false;

        Test.startTest();
        List<cfp_DataMovementsImporter.Response> results =
            cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].success);

        List<cfp_Data_Movements__c> rows = [
            SELECT Name, cfp_DataGroups__c
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
            AND Name IN ('Open record page (WorkOrder)', 'Read page record (WorkOrder)')
            ORDER BY cfp_order__c ASC
        ];
        System.assertEquals(2, rows.size());
        System.assertEquals(dg.Id, rows[0].cfp_DataGroups__c, 'Known dataGroupRef should map by external id.');
        System.assertEquals(dg.Id, rows[1].cfp_DataGroups__c, 'Known dataGroupRef should map by external id.');
    }

    @IsTest
    static void testImporterNonBlockingWhenDataGroupUnresolved() {
        cfp_FunctionalProcess__c fp = createFunctionalProcess('Importer Unresolved DataGroupRef');
        String expectedExternalId = getSystemContextName(fp).toLowerCase() + '|workorder';
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'WorkOrder',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = fp.cfp_System_Context__c,
            cfp_External_Id__c = expectedExternalId
        );
        insert dg;

        cfp_DataMovementsImporter.Request req = new cfp_DataMovementsImporter.Request();
        req.functionalProcessId = fp.Id;
        req.jsonPayload = buildPayloadWithUnknownRef();
        req.replaceExistingForProcess = false;

        Test.startTest();
        List<cfp_DataMovementsImporter.Response> results =
            cfp_DataMovementsImporter.importFromJson(new List<cfp_DataMovementsImporter.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].success, 'Importer should remain non-blocking by default.');
        System.assert(results[0].errorMessage != null && results[0].errorMessage.contains('UnknownObject'),
            'Response should list unresolved key(s).');

        List<cfp_Data_Movements__c> rows = [
            SELECT Name, cfp_DataGroups__c
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
            AND Name IN ('Known ref', 'Unknown ref')
            ORDER BY cfp_order__c ASC
        ];
        System.assertEquals(2, rows.size());
        System.assertEquals(dg.Id, rows[0].cfp_DataGroups__c, 'Known reference should still be linked.');
        System.assertEquals(null, rows[1].cfp_DataGroups__c, 'Unknown reference should stay blank (non-blocking).');
    }
}
