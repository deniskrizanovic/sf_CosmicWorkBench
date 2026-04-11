public with sharing class cfp_DataMovementsImporter {
    public class Request {
        @InvocableVariable(required=true)
        public String functionalProcessId;

        @InvocableVariable(required=true)
        public String jsonPayload;

        @InvocableVariable
        public Boolean replaceExistingForProcess;
    }

    public class Response {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public Integer insertedCount;

        @InvocableVariable
        public String errorMessage;
    }

    private class PayloadRoot {
        public List<Map<String, Object>> dataMovements;
    }

    @InvocableMethod(
        label='Import Data Movements from JSON'
        description='Imports Data Movements from JSON for a Functional Process.'
    )
    public static List<Response> importFromJson(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Map<String, String> implementationTypeMap = buildImplementationTypeMap();

        for (Request req : requests) {
            Response res = new Response();
            res.success = false;
            res.insertedCount = 0;

            try {
                validateRequest(req);
                Id functionalProcessId = (Id) req.functionalProcessId;
                String systemContextToken = getFunctionalProcessSystemContextToken(functionalProcessId);
                // #region agent log
                debugLog(
                    'H1',
                    'cfp_DataMovementsImporter.importFromJson',
                    'Resolved functional process system context token',
                    new Map<String, Object>{
                        'functionalProcessId' => functionalProcessId,
                        'systemContextToken' => systemContextToken
                    },
                    String.valueOf(functionalProcessId)
                );
                // #endregion
                PayloadRoot payload = parsePayload(req.jsonPayload);
                Map<String, Id> dataGroupByExternalId = resolveDataGroupsByExternalId(payload, systemContextToken);
                // #region agent log
                debugLog(
                    'H2',
                    'cfp_DataMovementsImporter.importFromJson',
                    'Resolved data groups by external id',
                    new Map<String, Object>{
                        'resolvedExternalIds' => new List<String>(dataGroupByExternalId.keySet()),
                        'resolvedCount' => dataGroupByExternalId.size()
                    },
                    String.valueOf(functionalProcessId)
                );
                // #endregion
                Set<String> unresolvedDataGroupRefs = new Set<String>();
                List<cfp_Data_Movements__c> rowsToInsert =
                    buildRows(payload, functionalProcessId, implementationTypeMap, dataGroupByExternalId, unresolvedDataGroupRefs, systemContextToken);

                Boolean replaceExisting = req.replaceExistingForProcess == true;
                if (replaceExisting) {
                    List<cfp_Data_Movements__c> existing = [
                        SELECT Id
                        FROM cfp_Data_Movements__c
                        WHERE cfp_FunctionalProcess__c = :functionalProcessId
                    ];
                    if (!existing.isEmpty()) {
                        delete existing;
                    }
                }

                if (!rowsToInsert.isEmpty()) {
                    insert rowsToInsert;
                }

                res.success = true;
                res.insertedCount = rowsToInsert.size();
                if (!unresolvedDataGroupRefs.isEmpty()) {
                    List<String> unresolvedSorted = new List<String>(unresolvedDataGroupRefs);
                    unresolvedSorted.sort();
                    res.errorMessage = 'Unresolved dataGroupRef values (non-blocking): ' + String.join(unresolvedSorted, ', ');
                }
            } catch (Exception ex) {
                res.errorMessage = ex.getMessage();
            }

            responses.add(res);
        }

        return responses;
    }

    private static void validateRequest(Request req) {
        if (req == null) {
            throw new AuraHandledException('Request cannot be null.');
        }
        if (String.isBlank(req.functionalProcessId)) {
            throw new AuraHandledException('functionalProcessId is required.');
        }
        if (!Id.valueOf(req.functionalProcessId).getSObjectType().getDescribe().getName().equals('cfp_FunctionalProcess__c')) {
            throw new AuraHandledException('functionalProcessId must be a cfp_FunctionalProcess__c Id.');
        }
        if (String.isBlank(req.jsonPayload)) {
            throw new AuraHandledException('jsonPayload is required.');
        }
    }

    private static PayloadRoot parsePayload(String jsonPayload) {
        Object deserialized = JSON.deserializeUntyped(jsonPayload);
        if (!(deserialized instanceof Map<String, Object>)) {
            throw new AuraHandledException('JSON root must be an object.');
        }

        Map<String, Object> rootMap = (Map<String, Object>) deserialized;
        Object dataMovementsObj = rootMap.get('dataMovements');
        if (dataMovementsObj == null || !(dataMovementsObj instanceof List<Object>)) {
            throw new AuraHandledException('JSON must contain a dataMovements array.');
        }

        PayloadRoot root = new PayloadRoot();
        root.dataMovements = new List<Map<String, Object>>();
        for (Object movementObj : (List<Object>) dataMovementsObj) {
            if (movementObj instanceof Map<String, Object>) {
                root.dataMovements.add((Map<String, Object>) movementObj);
            }
        }
        return root;
    }

    private static List<cfp_Data_Movements__c> buildRows(
        PayloadRoot payload,
        Id functionalProcessId,
        Map<String, String> implementationTypeMap,
        Map<String, Id> dataGroupByExternalId,
        Set<String> unresolvedDataGroupRefs,
        String systemContextToken
    ) {
        List<cfp_Data_Movements__c> rows = new List<cfp_Data_Movements__c>();
        for (Map<String, Object> movement : payload.dataMovements) {
            cfp_Data_Movements__c row = new cfp_Data_Movements__c();
            row.cfp_FunctionalProcess__c = functionalProcessId;
            row.Name = asString(movement.get('name'));
            row.cfp_order__c = asDecimal(movement.get('order'));
            row.cfp_movementtype__c = asString(movement.get('movementType'));
            row.cfp_artifactName__c = asString(movement.get('artifactName'));

            String implTypeRaw = asString(movement.get('implementationType'));
            row.cfp_implementationtype__c = normalizeImplementationType(implTypeRaw, implementationTypeMap);

            String dataGroupRef = asString(movement.get('dataGroupRef'));
            String externalId = cfp_DataGroupExternalIdUtil.buildExternalIdFromDataGroupRef(systemContextToken, dataGroupRef);
            if (!String.isBlank(externalId) && dataGroupByExternalId.containsKey(externalId)) {
                row.cfp_DataGroups__c = dataGroupByExternalId.get(externalId);
            } else if (!String.isBlank(dataGroupRef)) {
                unresolvedDataGroupRefs.add(dataGroupRef);
            }
            // #region agent log
            debugLog(
                'H3',
                'cfp_DataMovementsImporter.buildRows',
                'Data movement dataGroupRef resolution decision',
                new Map<String, Object>{
                'movementName' => row.Name,
                'artifactName' => row.cfp_artifactName__c,
                'dataGroupRef' => dataGroupRef,
                    'computedExternalId' => externalId,
                    'wasResolved' => !String.isBlank(externalId) && dataGroupByExternalId.containsKey(externalId),
                    'assignedDataGroupId' => row.cfp_DataGroups__c
                },
                String.valueOf(functionalProcessId)
            );
            // #endregion

            row.cfp_is_API_Call__c = asBoolean(movement.get('isApiCall'));
            rows.add(row);
        }
        return rows;
    }

    private static Map<String, Id> resolveDataGroupsByExternalId(PayloadRoot payload, String systemContextToken) {
        Set<String> keys = new Set<String>();
        for (Map<String, Object> movement : payload.dataMovements) {
            String dataGroupRef = asString(movement.get('dataGroupRef'));
            String key = cfp_DataGroupExternalIdUtil.buildExternalIdFromDataGroupRef(systemContextToken, dataGroupRef);
            if (!String.isBlank(key)) {
                keys.add(key);
            }
        }
        // #region agent log
        debugLog(
            'H4',
            'cfp_DataMovementsImporter.resolveDataGroupsByExternalId',
            'Computed lookup keys from payload dataGroupRef values',
            new Map<String, Object>{
                'systemContextToken' => systemContextToken,
                'lookupKeys' => new List<String>(keys)
            },
            systemContextToken
        );
        // #endregion
        if (keys.isEmpty()) {
            return new Map<String, Id>();
        }

        Map<String, Id> byExternalId = new Map<String, Id>();
        for (cfp_DataGroups__c dg : [
            SELECT Id, cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE cfp_External_Id__c IN :keys
        ]) {
            byExternalId.put(dg.cfp_External_Id__c, dg.Id);
        }
        return byExternalId;
    }

    private static String getFunctionalProcessSystemContextToken(Id functionalProcessId) {
        cfp_FunctionalProcess__c fp = [
            SELECT cfp_System_Context__c, cfp_System_Context__r.Name
            FROM cfp_FunctionalProcess__c
            WHERE Id = :functionalProcessId
            LIMIT 1
        ];
        return fp.cfp_System_Context__r != null ? fp.cfp_System_Context__r.Name : null;
    }

    private static Map<String, String> buildImplementationTypeMap() {
        Map<String, String> normalizedToActual = new Map<String, String>();
        Schema.DescribeFieldResult dfr = cfp_Data_Movements__c.cfp_implementationtype__c.getDescribe();
        for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
            String actual = entry.getValue();
            if (actual != null) {
                normalizedToActual.put(actual.trim().toLowerCase(), actual);
            }
        }
        return normalizedToActual;
    }

    private static String normalizeImplementationType(String raw, Map<String, String> implementationTypeMap) {
        if (String.isBlank(raw)) {
            return null;
        }
        String normalized = raw.trim().toLowerCase();
        if (implementationTypeMap.containsKey(normalized)) {
            return implementationTypeMap.get(normalized);
        }
        return raw;
    }

    private static String asString(Object value) {
        if (value == null) {
            return null;
        }
        return String.valueOf(value);
    }

    private static Decimal asDecimal(Object value) {
        if (value == null) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    private static Boolean asBoolean(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Boolean) {
            return (Boolean) value;
        }
        return String.valueOf(value).toLowerCase() == 'true';
    }

    private static void debugLog(
        String hypothesisId,
        String location,
        String message,
        Map<String, Object> data,
        String runId
    ) {
        Map<String, Object> payload = new Map<String, Object>{
            'sessionId' => 'e1c571',
            'runId' => runId,
            'hypothesisId' => hypothesisId,
            'location' => location,
            'message' => message,
            'data' => data,
            'timestamp' => DateTime.now().getTime()
        };
        System.debug('AGENT_DEBUG ' + JSON.serialize(payload));
    }
}
