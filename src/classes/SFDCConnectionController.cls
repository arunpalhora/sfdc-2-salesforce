public with sharing class SFDCConnectionController {

  public Boolean isRemoteConnected {get; set;}
  public Boolean showReferences {get; set;}

  public String username {get; set;}
  public String password {get; set;}
  public String securityToken {get; set;}
  public String localServerUrl {get; set;}
  public String unauthorisedUrl {get; set;}
  public String orderByFieldSelected {get; set;}
  public String orderBySelected {get; set;}
  public String noOfRecordsToQuerySelected {get; set;}
  public String referencesLabel {get; set;}
  public String selectedOrgType {get; set;}
  public String selectedObject {get; set;}
  public String selectedObjectType {get; set;}

  public sObject sObjectRecord {get; set;}

  public ObjectDefinition selectedObjectDefinition {get; set;}
  public RecordDetails recordsForSelectedObject {get; set;} 

  public List<String> fieldsToBeInserted {get; set;}
  public List<String> referenceFields {get; set;}

  public List<Selectoption> availableObjects {get; set;}
  public List<SelectOption> noOfRecordsToQuery {get; set;}
  public List<Selectoption> objectTypes {get; set;}
  public List<SelectOption> orgTypes {get; set;}
  public List<SelectOption> orderBy {get; set;}
  public List<SelectOption> orderByField {get; set;}
  public List<Filter> filters {get; set;}

  private AllObjectDescribe aod;
  private RemoteSFDC remoteSf;
  private static final String NONE = '--None--';

  public SFDCConnectionController() {
    remoteSf = new RemoteSFDC(); 
    orgTypes = new List<Selectoption>();
    localServerUrl = URL.getSalesforceBaseUrl().toExternalForm();
    orgTypes.add(new Selectoption(remoteSf.ORG_SANDBOX, remoteSf.ORG_SANDBOX));
    orgTypes.add(new Selectoption('Production/Developer', 'Production/Developer'));
    selectedOrgType = remoteSf.ORG_SANDBOX;
    isRemoteConnected = false;
  }
  
  public Pagereference selectObjectType() {
  	if (String.isNotBlank(selectedObjectType)) {
  	  selectedObject = NONE;
  	  selectedObjectDefinition = null;
      recordsForSelectedObject = null;
  	  loadObjects();
  	}
    return null;
  }

  public Pagereference getObjectDetails() {
    selectedObjectDefinition = null;
    recordsForSelectedObject = null;
    if (String.isNotBlank(selectedObject) && selectedObject != NONE) {
      selectedObjectDefinition = remoteSf.getSobjectsDetailsFor(selectedObject);
    }
    
    if (selectedObjectDefinition != null) {
      filters = new List<Filter>();
      List<String> fieldNames = new List<String>();
      for (FieldDefinition fd : selectedObjectDefinition.fields) {
        fieldNames.add(fd.name);
        fd.isSelected = true;
      }
      
      fieldNames.sort();
      fieldNames.add(0, NONE);
      
      List<Selectoption> fields = new List<Selectoption>();
      for (String fd : fieldNames) {
        fields.add(new Selectoption(fd, fd));
      }
      
      for (Integer i = 0; i < 5; i++) {
        filters.add(new Filter(fields));
      }

      if (orderBy == null) {
        orderBy = new List<Selectoption>();
        orderBy.add(new Selectoption('ASC', 'Ascending'));
        orderBy.add(new Selectoption('DESC', 'Descending'));

        orderBySelected = 'DESC';
      }
      
      if (noOfRecordsToQuery == null) {
        noOfRecordsToQuery = new List<Selectoption>();
        noOfRecordsToQuery.add(new Selectoption('10', '10'));
        noOfRecordsToQuery.add(new Selectoption('25', '25'));
        noOfRecordsToQuery.add(new Selectoption('50', '50'));
        noOfRecordsToQuery.add(new Selectoption('100', '100'));
        noOfRecordsToQuery.add(new Selectoption('200', '200'));
        noOfRecordsToQuery.add(new Selectoption('500', '500'));
        noOfRecordsToQuery.add(new Selectoption('1000', '1000'));
        noOfRecordsToQuery.add(new Selectoption('10000', 'All (Upto 10000 records)'));

        noOfRecordsToQuerySelected = '200';
      }
      
      orderByField = new List<Selectoption>(fields);
      orderByField.remove(0);
      orderByFieldSelected = 'LastModifiedDate';
    }
    
    return null;
  }

  public Pagereference queryRemote() {
    String whereCondition = '';
    for (Filter f : filters) {
      if (f.selectedField != NONE && f.selectedOperator != NONE) {
        whereCondition += f.selectedField + f.selectedOperator + f.values+' AND ';
      }
    }
    
    if (String.isNotBlank(whereCondition)) {
      whereCondition = 'where ' + whereCondition.removeEnd(' AND ');
    }

    whereCondition += ' order by ' +orderByFieldSelected+ ' ' + orderBySelected + ' limit ' + noOfRecordsToQuerySelected;

    recordsForSelectedObject = remoteSf.getRecordsFor(selectedObjectDefinition, whereCondition);
    if (recordsForSelectedObject != null && recordsForSelectedObject.totalSize > 0) {
      referenceFields();
    }
    
    return null;
  }
  
  public Pagereference showHideRefernceFields() {
  	if (!showReferences) {
      referencesLabel = 'Hide reference fields and use the same values from remote Org';
  	  showReferences = true;
  	} else {
      referencesLabel = 'View and map reference fields';
      showReferences = false;
  	}
  	return null;
  }

  public Pagereference insertRecords() {
    if (String.isBlank(selectedObject) || selectedObject == NONE || 
      selectedObjectDefinition == null || recordsForSelectedObject == null || !(recordsForSelectedObject.totalSize > 0)) {

      return null;
    }

    List<sObject> sobjects = recordsForSelectedObject.records.deepClone(false, false, false);

    if (showReferences) {
      for (sObject s : sobjects) {
        for (String ref : referenceFields) {
          s.put(ref, sObjectRecord.get(ref));
        }
      }
    }

    Integer noOfRecordsInserted = 0;
    try {
      Database.SaveResult[] srList = Database.insert(sobjects, false);
      for (Database.Saveresult sr : srList) {
        if (sr.isSuccess()) {
          noOfRecordsInserted++;
        } else {
          for (Database.Error er : sr.getErrors()) {
            Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, er.getMessage()));
          }
        }
      }
    } catch(Exception e) {
      Apexpages.addMessages(e);
      return null;
    }
    if (noOfRecordsInserted > 0) {
      Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.INFO, '"' + noOfRecordsInserted +'" records have been successfully inserted to Local Organization!'));
    }
    return null;
  }
  
  public class Filter {
    public List<Selectoption> fieldNames {get; set;}
    public List<Selectoption> operators {get; set;}
    public String selectedField {get; set;}
    public String selectedOperator {get; set;}
    public String values {get; set;}

    public Filter(List<Selectoption> fNames) {
      fieldNames = fNames;
      operators = new List<Selectoption> {new Selectoption(NONE, NONE),
        new Selectoption('=', 'equals'),
        new Selectoption('!=', 'not equals to')};
    }
  }

  public Pagereference loginNow() {
/*
  	username = 'apalhora1@gmail.com';
  	password = '';
  	securityToken = 'G4dDuXP9q8Eu5Apx6km3p9BqT';
  	selectedOrgType = 'Production/Developer';
*/  	
    if (String.isBlank(username) || String.isBlank(password)) {
      Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR,
        'Please enter valid username and password before clicking Submit!'));
      return null;
    }

    remoteSf.setOrgType(selectedOrgType);
    remoteSf.loginToRemoteInstance(username, password);

    if (String.isNotBlank(remoteSf.unautorisedEndPointURL)) {
      unauthorisedUrl = remoteSf.unautorisedEndPointURL;
      isRemoteConnected = false;
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
        'Session ID was not generated'));
    } else if (String.isBlank(remoteSf.sessionId)) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
        'Invalid Environment/Username/Password combination! Please make sure you enter the valid values.'));
      password = null;
      isRemoteConnected = false;    
    } else {
      unauthorisedUrl = null;
      isRemoteConnected = true;
      loadObjectTypes();
    }
    
    selectedObjectType = null;
    return null;
  }
  
  private void loadObjectTypes() {
  	if (objectTypes == null) {
      objectTypes = new List<Selectoption>();
      objectTypes.add(new Selectoption('Standard Object', 'Standard Objects'));
      objectTypes.add(new Selectoption('Custom Object', 'Custom Objects'));
      objectTypes.add(new Selectoption('Custom Setting', 'Custom Settings'));
  	}
  }

  private void referenceFields() {
  	sObjectRecord = recordsForSelectedObject.records.get(0).clone(false, true, false, false);
  	referenceFields = new List<String>();
  	fieldsToBeInserted = new List<String>();
    for (FieldDefinition fd : selectedObjectDefinition.fields) {
      if (fd.isSelected && sObjectRecord.get(fd.Name) != null) {
        if (fd.Type == 'reference') {
          referenceFields.add(fd.Name);
        }
        fieldsToBeInserted.add(fd.Name);
      }
    }
    referenceFields.sort();
    referencesLabel = 'Click here to view and map reference fields!';
    showReferences = false;
  }
  
  private void loadObjects() {
    availableObjects = new List<Selectoption>();
    if (aod == null) {
      aod = remoteSf.getAllSobjects();
  	}
    if (String.isNotBlank(remoteSf.unautorisedEndPointURL)) {
      unauthorisedUrl = remoteSf.unautorisedEndPointURL;
      isRemoteConnected = false;
      return;
    } else {
      unauthorisedUrl = null;
      isRemoteConnected = true;
    }
    
    if (String.isNotBlank(selectedObjectType) && aod != null) {
      Integer i = 0;
      for (ObjectDefinition od : aod.sobjects) {
        if (i < 1000 && !(od.name.endsWith('Tag') || od.name.endsWith('History') || 
          od.name.endsWith('Share'))) {
      
          if (od.customSetting && selectedObjectType == 'Custom Setting') {
            availableObjects.add(new SelectOption(od.name, od.label));
          } else if (od.custom && !od.customSetting && selectedObjectType == 'Custom Object') {
            availableObjects.add(new SelectOption(od.name, od.label));
          } else if(selectedObjectType == 'Standard Object') {
            availableObjects.add(new SelectOption(od.name, od.label));
          }
          i++;
        }
      }
    }
    availableObjects.sort();
    availableObjects.add(0, new Selectoption(NONE, NONE));
    selectedObject = NONE;
  }
}