public with sharing class CustomMetadataService {



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

}