public with sharing class RecordDetails {

  public Integer totalSize {get; set;}
  public Boolean done {get; set;}
  public List<sObject> records {get; set;}


  public Boolean isSelected {get; set;}
  public List<ColumnNameValue> cNameValues {get; set;}

  public RecordDetails() {
  }
  public RecordDetails(Map<String, Object> columnNameValueMap) {
  	cNameValues = new List<ColumnNameValue>();
    for (String s : columnNameValueMap.keySet()){
      cNameValues.add(new ColumnNameValue(s, columnNameValueMap.get(s)));
    } 
  }
  
  public class ColumnNameValue {
    public String fieldName {get; set;}
    public Object fieldValue {get; set;}
    
    public ColumnNameValue(String name, Object value) {
      fieldName = name;
      fieldValue = value;
    }
  }
	
 
}