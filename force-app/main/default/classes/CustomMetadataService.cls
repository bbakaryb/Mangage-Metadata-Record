public with sharing class CustomMetadataService {
    
    @future 
    public static void GenericCreateRecord(
        String metadataTypeApiName,
        String recordName,
        String label,
        String fieldsJson
    ) {
        Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(fieldsJson);

        recordName = recordName.replaceAll('[^A-Za-z0-9_]', '_');
        recordName = recordName.replaceAll('__', '_');

        // Prepare Custom Metadata
        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = metadataTypeApiName + '.' + recordName;
        cmd.label    = label;

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
            .get(metadataTypeApiName)
            .getDescribe()  
            .fields
            .getMap();

        // mapping Label -> API
        Map<String, String> labelToApiName = new Map<String, String>();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            labelToApiName.put(dfr.getLabel(), fieldName);
        }

        // Add value to cmd
        for (String key : fields.keySet()) {
            String fieldApi;
            Object rawValue = fields.get(key);

            if (fieldMap.containsKey(key)) {
                fieldApi = key; 
            } else if (labelToApiName.containsKey(key)) {
                fieldApi = labelToApiName.get(key);
            } else {
                System.debug('Any field found for : ' + key);
                continue;
            }

            Schema.DescribeFieldResult dfr = fieldMap.get(fieldApi).getDescribe();
            Object safeValue = castToCorrectType(dfr, rawValue);

            if (safeValue != null) {
                Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
                v.field = fieldApi;
                v.value = safeValue;
                cmd.values.add(v);
            } else {
                System.debug('Value ignored for the fied ' + fieldApi + ' (key=' + key + ')');
            }
        }

        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        dc.addMetadata(cmd);

        if (!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(dc, new CustomMetadataCallback());
            System.debug('Deployment jobId: ' + jobId);
        }
    }

    @future 
    public static void GenericUpdateRecordByLabel(
        String metadataTypeApiName,
        String label,
        String fieldsJson
    ) {
        // Parse JSON
        Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(fieldsJson);

        SObject existingRecord = getCustomMetadataRecord(metadataTypeApiName, label);
        if (existingRecord == null) {
            System.debug('Any record found with Label = ' + label);
            return;
        }

        String recordName = (String) existingRecord.get('DeveloperName');

        // cmd
        Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
        cmd.fullName = metadataTypeApiName + '.' + recordName;
        cmd.label    = (String) existingRecord.get('Label');

        // Get the description of type for cast correctly
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(metadataTypeApiName);
        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        // mapping Label -> API
        Map<String, String> labelToApiName = new Map<String, String>();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            labelToApiName.put(dfr.getLabel(), fieldName);
        }

        // map for not have doublon
        Map<String, Metadata.CustomMetadataValue> valuesMap = new Map<String, Metadata.CustomMetadataValue>();

        // copy actual values
        for (String fieldApi : fieldMap.keySet()) {
            if (!fieldApi.endsWith('__c')) continue;
            Object existingValue = existingRecord.get(fieldApi);
            if (existingValue != null) {
                Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
                v.field = fieldApi;
                v.value = existingValue;
                valuesMap.put(fieldApi, v);
            }
        }

        // set new values
        for (String key : fields.keySet()) {
            String fieldApi;
            Object rawValue = fields.get(key);

            if (fieldMap.containsKey(key)) {
                fieldApi = key;
            } else if (labelToApiName.containsKey(key)) {
                fieldApi = labelToApiName.get(key);
            } else {
                System.debug('Any field found for : ' + key);
                continue;
            }

            if (!fieldApi.endsWith('__c')) continue;

            Schema.DescribeFieldResult dfr = fieldMap.get(fieldApi).getDescribe();
            Object safeValue = castToCorrectType(dfr, rawValue);

            if (safeValue != null) {
                Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
                v.field = fieldApi;
                v.value = safeValue;
                valuesMap.put(fieldApi, v); // new value replace old value
            }
        }

        // assign map to cmd
        cmd.values.addAll(valuesMap.values());

        //System.debug('CustomMetadata ready to update : ' + cmd);

        Metadata.DeployContainer dc = new Metadata.DeployContainer();
        dc.addMetadata(cmd);

        if (!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(dc, new CustomMetadataCallback());
            System.debug('Deployment jobId (update by label): ' + jobId);
        }
    }



    public class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('Custom Metadata create/update');
            } else {
                System.debug('Error: ' + result.errorMessage);
            }
        }
    }


    public static Object castToCorrectType(Schema.DescribeFieldResult dfr, Object rawValue) {
        if (rawValue == null) return null;

        try {
            Schema.DisplayType type = dfr.getType();
            switch on type {
                when DateTime {
                    if (rawValue instanceof DateTime) return rawValue;
                    if (rawValue instanceof String) return DateTime.valueOf((String)rawValue);
                }
                when Date {
                    if (rawValue instanceof Date) return rawValue;
                    if (rawValue instanceof String) return Date.valueOf((String)rawValue);
                }
                when Boolean {
                    if (rawValue instanceof Boolean) return rawValue;
                    if (rawValue instanceof String) return Boolean.valueOf((String)rawValue);
                }
                when Integer {
                    if (rawValue instanceof Integer) return rawValue;
                    if (rawValue instanceof String) return Integer.valueOf(rawValue);
                }
                when Double {
                    if (rawValue instanceof Decimal) return rawValue;
                    if (rawValue instanceof String) return Decimal.valueOf((String)rawValue);
                }
                when Currency, Percent {
                    if (rawValue instanceof Decimal) return rawValue;
                    if (rawValue instanceof String) return Decimal.valueOf((String)rawValue);
                }
                when String, Picklist, Reference {
                    return String.valueOf(rawValue);
                }
                when else {
                    // Special type (Time, LongTextArea, etc.)
                    return String.valueOf(rawValue);
                }
            }
        } catch (Exception e) {
            System.debug('Conversion error for field :  ' + dfr.getName() + ' : ' + e.getMessage());
        }
        return null;
    }

    public static SObject getCustomMetadataRecord(String metadataTypeApiName, String label) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType objType = gd.get(metadataTypeApiName); 
        Schema.DescribeSObjectResult describe = objType.getDescribe();
        
        List<String> fieldNames = new List<String>();

        for (Schema.SObjectField f : describe.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            
            // only custom fields
            if (dfr.getName().endsWith('__c')) {
                fieldNames.add(dfr.getName());
            }
        }

        fieldNames.add('DeveloperName');
        fieldNames.add('Label');
        
        String soql = 'SELECT ' + String.join(fieldNames, ', ') +
                    ' FROM ' + metadataTypeApiName +
                    ' WHERE Label = :label LIMIT 1';
        
        return Database.query(soql);
    }




}