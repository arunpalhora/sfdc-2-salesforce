public with sharing class FieldDefinition {

  public Boolean isSelected {get; set;}

  public String name {get; set;}
  public String type {get; set;}
  public String length {get; set;}
  public String defaultValue {get; set;}
  public String autoNumber {get; set;}
  public String nillable {get; set;}
  public String unique {get; set;}
  public String externalId {get; set;}
  public String idLookup {get; set;}
  public String inlineHelpText {get; set;}
  public String writeRequiresMasterRead {get; set;}
  public String nameField {get; set;}
  public String sortable {get; set;}
  public String filterable {get; set;}
  public String caseSensitive {get; set;}
  public String restrictedPicklist {get; set;}
  public String calculated {get; set;}
  public String scale {get; set;}
  public String deprecatedAndHidden {get; set;}
  public String relationshipName {get; set;}
  public String createable {get; set;}
  public String updateable {get; set;}
  public String controllerName {get; set;}
  public String displayLocationInDecimal {get; set;}
  public String cascadeDelete {get; set;}
  public String restrictedDelete {get; set;}
  public String namePointing {get; set;}
  public String htmlFormatted {get; set;}
  public String dependentPicklist {get; set;}
  public String custom {get; set;}
  public String byteLength {get; set;}
  public String label {get; set;}
  public String precision {get; set;}
  public String relationshipOrder {get; set;}
  public String soapType {get; set;}
  public String active {get; set;}
  public String defaultValueFormula {get; set;}
  public String defaultedOnCreate {get; set;}
  public String groupable {get; set;}
  public String permissionable {get; set;}
  public String validFor {get; set;}
  
  public List<String> referenceTo {get; set;}
  public List<PickListValue> picklistValues {get; set;} 
}