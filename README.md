# Generic Manage Custom Metadata Type Package

## 📌 Description
Managing Custom Metadata records often requires manual deployment or complex scripts.
This package provides a simple Apex utility to create and update Custom Metadata records at runtime — dynamically, and asynchronously.

## 🌟 Why this package ? 
- Avoid manual deployments for simple metadata changes. 
- Checks if a date is a weekend or public holiday.  
- Update metadata directly from Apex (e.g., in setup wizards, admin tools, or automated processes).  
- Works in any org without depending on a specific metadata type.  

---

## 🚀 What can you do ?
- Create new Custom Metadata records.
- Update existing records by their label.
- Pass field values using a simple JSON string (field labels or API names both supported).  

## 📌 Quick Example
```java
// 1. Create a new record in Support_Tier__mdt
CustomMetadataService.GenericCreateRecord(
    'Support_Tier__mdt',    // Metadata type
    'Gold',                 // Record Name (DeveloperName)
    'Gold Tier',            // Label
    JSON.serialize(new Map<String, Object>{
        'Default_Discount__c' => 30,
        'Minimum_Spending__c' => 1000
    })
);

// 2. Update an existing record by label
CustomMetadataService.GenericUpdateRecordByLabel(
    'Support_Tier__mdt',
    'Gold Tier',
    JSON.serialize(new Map<String, Object>{
        'Default_Discount__c' => 40
    })
);
```

## ⚙️ Parameters
### `GenericCreateRecord(metadataTypeApiName, recordName, label, fieldsJson)`

| Parameter            | Required | Type   | Description                                                                 |
|----------------------|----------|--------|-----------------------------------------------------------------------------|
| `metadataTypeApiName` | ✅ Yes   | String | API name of the Custom Metadata Type (e.g., `Support_Tier__mdt`).           |
| `recordName`          | ✅ Yes   | String | `DeveloperName` of the new record (unique identifier, no spaces or special chars). |
| `label`               | ✅ Yes   | String | User-friendly name shown in Setup.                                          |
| `fieldsJson`          | Optional| String | JSON mapping field API names or labels to values. Example: `{"Default_Discount__c": 10}` |

---

### `GenericUpdateRecordByLabel(metadataTypeApiName, label, fieldsJson)`

| Parameter            | Required | Type   | Description                                                                 |
|----------------------|----------|--------|-----------------------------------------------------------------------------|
| `metadataTypeApiName` | ✅ Yes   | String | API name of the Custom Metadata Type (e.g., `Support_Tier__mdt`).           |
| `label`               | ✅ Yes   | String | Label of the record to update.                                              |
| `fieldsJson`          | ✅ Yes   | String | JSON mapping field API names or labels to **new values**. Example: `{"Minimum_Spending__c": 100}` |

---

### 🔧 Notes
- `recordName` must be unique in the org, just like any other Custom Metadata record.  
- If a field is omitted in `fieldsJson`, its existing value will remain unchanged.  
- JSON values are automatically cast to the correct Salesforce data type (Date, DateTime, Boolean, Currency, etc.).  

---

## 🔧 Installation Guide

### Install package in a **Scratch Org**

1. Enable DevHub in your main org. 
2. Clone the repository
```bash
git clone https://github.com/bbakaryb/Mangage-Metadata-Record.git
cd Mangage-Metadata-Record
```

3. Authenticate a Dev Hub
```bash
sf org login web --set-default-dev-hub --alias DevHub
```

4. Create a Scratch Org
```bash
sf org create scratch --definition-file config/project-scratch-def.json --duration-days 30 --alias MyScratchOrg --target-dev-hub DevHub
```

5. Install the package:
```bash
sf package install --wait 10 --publish-wait 10 --package managecmd@1.0.0-1 --installation-key test1234 --no-prompt --target-org MyScratchOrg
```

6. Open your Scratch Org:
```bash
sf org open --target-org MyScratchOrg
```

### Install package in a **Production or Sandbox Org**

1. Authenticate your target org:
```bash
sf org login web --alias MyOrg
```

2. Install the package:
```bash
sf package install --wait 10 --publish-wait 10 --package managecmd@1.0.0-1 --installation-key test1234 --no-prompt --target-org MyOrg
```









