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
                PayloadRoot payload = parsePayload(req.jsonPayload);
                List<cfp_Data_Movements__c> rowsToInsert = buildRows(payload, functionalProcessId, implementationTypeMap);

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
        Map<String, String> implementationTypeMap
    ) {
        List<cfp_Data_Movements__c> rows = new List<cfp_Data_Movements__c>();
        for (Map<String, Object> movement : payload.dataMovements) {
            cfp_Data_Movements__c row = new cfp_Data_Movements__c();
            row.cfp_FunctionalProcess__c = functionalProcessId;
            row.Name = asString(movement.get('name'));
            row.cfp_order__c = asDecimal(movement.get('order'));
            row.cfp_movementtype__c = asString(movement.get('movementType'));

            String implTypeRaw = asString(movement.get('implementationType'));
            row.cfp_implementationtype__c = normalizeImplementationType(implTypeRaw, implementationTypeMap);

            row.cfp_is_API_Call__c = asBoolean(movement.get('isApiCall'));
            rows.add(row);
        }
        return rows;
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
}
