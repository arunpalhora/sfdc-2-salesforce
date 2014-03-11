public with sharing class ObjectDefinition {
  public String name {get; set;}
  public String label {get; set;}
  public Boolean searchable {get; set;}
  public Boolean customSetting {get; set;}
  public Boolean undeletable {get; set;}
  public Boolean mergeable {get; set;}
  public Boolean replicateable {get; set;}
  public Boolean triggerable {get; set;}
  public Boolean feedEnabled {get; set;}
  public Boolean retrieveable {get; set;}
  public Boolean deprecatedAndHidden {get; set;}
  public Boolean activateable {get; set;}
  public String labelPlural {get; set;}
  public Boolean layoutable {get; set;}
  public String keyPrefix {get; set;}
  public Boolean createable {get; set;}
  public Boolean deletable {get; set;}
  public Boolean updateable {get; set;}
  public Boolean custom {get; set;}
  public Boolean queryable {get; set;}
  
  public List<FieldDefinition> fields {get; set;}
  public List<RecordTypeInfo> recordTypeInfos {get; set;}
  public List<ChildRelationship> childRelationships {get; set;}
}