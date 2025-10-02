@isTest
private class CustomMetadataServiceTEST {

    @IsTest
    static void testCastToCorrectType_DateTime() {
        Schema.DescribeFieldResult dfr = Account.CreatedDate.getDescribe();
        
        // DateTime
        DateTime dt1 = DateTime.now();
        Object result1 = CustomMetadataService.castToCorrectType(dfr, dt1);
        System.assertEquals(dt1, result1);

        // String to DateTime
        DateTime expected = DateTime.newInstance(2025, 1, 1, 0, 0, 0);
        Object result2 = CustomMetadataService.castToCorrectType(dfr, '2025-01-01 00:00:00');
        System.assertEquals(expected, result2);

        // String invalid
        Object result3 = CustomMetadataService.castToCorrectType(dfr, 'not_a_datetime');
        System.assertEquals(null, result3);
    }

    @IsTest
    static void testCastToCorrectType_Date() {
        Schema.DescribeFieldResult dfr = Opportunity.CloseDate.getDescribe();
        
        // Date
        Date dt1 = Date.newInstance(2025, 1, 1);
        Object result1 = CustomMetadataService.castToCorrectType(dfr, dt1);
        System.assertEquals(dt1, result1);

        // String to Date
        Date expected = Date.newInstance(2025, 1, 1);
        Object result2 = CustomMetadataService.castToCorrectType(dfr, '2025-01-01');
        System.assertEquals(expected, result2);

        // String invalid
        Object result3 = CustomMetadataService.castToCorrectType(dfr, 'not_a_date');
        System.assertEquals(null, result3);
    }


    @IsTest
    static void testCastToCorrectType_Boolean() {
        Schema.DescribeFieldResult dfr = Contact.HasOptedOutOfEmail.getDescribe();
        
        System.assertEquals(true, CustomMetadataService.castToCorrectType(dfr, true));
        System.assertEquals(false, CustomMetadataService.castToCorrectType(dfr, 'false'));
        System.assertEquals(true, CustomMetadataService.castToCorrectType(dfr, 'true'));
    }

    @IsTest
    static void testCastToCorrectType_Integer() {
        Schema.DescribeFieldResult dfr = Account.NumberOfEmployees.getDescribe();

        System.assertEquals(123, CustomMetadataService.castToCorrectType(dfr, 123));
        System.assertEquals(456, CustomMetadataService.castToCorrectType(dfr, '456'));
    }

    @IsTest
    static void testCastToCorrectType_Currency() {
        Schema.DescribeFieldResult dfr = Account.AnnualRevenue.getDescribe();

        Decimal val = 1000.50;
        System.assertEquals(val, CustomMetadataService.castToCorrectType(dfr, val));
        System.assertEquals(2000, CustomMetadataService.castToCorrectType(dfr, '2000'));
    }

    @IsTest
    static void testCastToCorrectType_StringAndPicklist() {
        Schema.DescribeFieldResult dfr = Account.Type.getDescribe();

        System.assertEquals('Prospect', CustomMetadataService.castToCorrectType(dfr, 'Prospect'));
        System.assertEquals('123', CustomMetadataService.castToCorrectType(dfr, 123));
    }

    @IsTest
    static void testCastToCorrectType_NullAndUnsupported() {
        Schema.DescribeFieldResult dfr = Account.Description.getDescribe(); // LongTextArea

        System.assertEquals(null, CustomMetadataService.castToCorrectType(dfr, null));
        // default value → String.valueOf()
        System.assertEquals('test', CustomMetadataService.castToCorrectType(dfr, 'test'));
    }

    @isTest
    static void testGenericUpdateWithRandomCMT() {
        MetadataSelection selection = getCustomMetadata();
        if (selection == null) {
            return; 
        }

        String chosenType = selection.typeName;
        SObject existing = selection.record;
        String existingLabel = (String) existing.get('Label');

        String updateJson = JSON.serialize(new Map<String, Object>{
            'Label' => 'Label MAJ ' + DateTime.now().getTime()
        });

        Test.startTest();
        CustomMetadataService.GenericUpdateRecordByLabel(chosenType, existingLabel, updateJson);
        Test.stopTest();
    }

    @isTest
    static void testGenericCreateWithRandomCMT() {
        MetadataSelection selection = getCustomMetadata();
        if (selection == null) {
            return; 
        }

        String chosenType = selection.typeName;
        SObject existing = selection.record;
        String existingLabel = (String) existing.get('Label');

        String updateJson = JSON.serialize(new Map<String, Object>{
            'Label' => 'Label MAJ ' + DateTime.now().getTime()
        });

        Test.startTest();
        CustomMetadataService.GenericCreateRecord(chosenType, 'record', existingLabel, updateJson);
        Test.stopTest();

    }

    private class MetadataSelection {
        String typeName;
        SObject record;
        MetadataSelection(String typeName, SObject record) {
            this.typeName = typeName;
            this.record = record;
        }
    }

    private static MetadataSelection getCustomMetadata() {
        String chosenType;
        for (String key : Schema.getGlobalDescribe().keySet()) {
            if (key.endsWith('__mdt')) {
                chosenType = key;
                break;
            }
        }

        if (String.isBlank(chosenType)) {
            System.debug('Any custom metadata type found, test ignored');
            return null;
        }

        List<SObject> records = Database.query(
            'SELECT DeveloperName, Label FROM ' + chosenType + ' LIMIT 1'
        );
        if (records.isEmpty()) {
            System.debug('Any record found in ' + chosenType + ', test ignored');
            return null;
        }

        return new MetadataSelection(chosenType, records[0]);
    }

}