public with sharing class RemoteSFDC {
  public Map<String, String> typeToSrvrUrlMap = new Map<String, String> {
    'version' => '/services/data/v29.0/sobjects', 
    'sobjects' => '/services/data/v29.0/sobjects', 
    'licensing' => '/services/data/v29.0/licensing', 
    'connect' => '/services/data/v29.0/connect', 
    'search' => '/services/data/v29.0/search', 
    'query' => '/services/data/v29.0/query?q=', 
    'tooling' => '/services/data/v29.0/tooling', 
    'chatter' => '/services/data/v29.0/chatter', 
    'recent' => '/services/data/v29.0/recent' };

  public Boolean isSandbox = true;

  public String metaDataSrvrUrl;
  public String serverUrl;
  public String baseUrl;
  public String sessionId;
  public String versionNumber = '29.0';    
  public String unautorisedEndPointURL = '';    

  public final String ORG_SANDBOX = 'Sandbox';
  public final String ORG_PROD = 'Production';
  public final String resNamespace = 'urn:partner.soap.sforce.com';  
  public final String soapNamespace='http://schemas.xmlsoap.org/soap/envelope/';
  
  private final String OBJECT_OR_ALL_FIELDS_NOT_AVAILABLE =
    'The selected object and/or all the fields in it, does not exist in the Local Org. ' +
    'Please create the object and/or all the fields of same type as remote Org has, in your local Org!';
  
  private String endpointServerUrl;
  
  public RemoteSFDC() {
  }

  public void setOrgType(String orgType) {
    if (orgType == ORG_SANDBOX) {
      endpointServerUrl = 'https://test.salesforce.com/services/Soap/u/';
    } else {
      endpointServerUrl = 'https://login.salesforce.com/services/Soap/u/';
    }
    endpointServerUrl += versionNumber;
  }
  
  
  public void loginToRemoteInstance(String username, String password) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpointServerUrl);
    req.setMethod('POST');
    req.setTimeout(60000);
    req.setBody(getLoginRequestBody(username, password));
    req.setHeader('Content-Type', 'text/xml;charset=UTF-8');
    req.setHeader('SOAPAction', '""');
    unautorisedEndPointURL = '';

    Http http = new Http();
    Httpresponse res = null;
    try {
      res = http.send(req);
      if (res.getStatusCode() == 200 && res.getBody() != null) {
        parseResponse(res);
      }
    } catch (Exception e) {
      if (e.getMessage().contains('Unauthorized endpoint')) {
        unautorisedEndPointURL = endpointServerUrl.substring(0, 
          endpointServerUrl.indexOf('/', 8));
      }
      Apexpages.addMessages(e);
    }
  }
  
  public AllObjectDescribe getAllSobjects() {
    Http h = new Http();
    Httprequest req = getHttpRestRequest('sobjects/');
    unautorisedEndPointURL = '';
    AllObjectDescribe allObjects = null;
    
    try {
      Httpresponse res = h.send(req);
      allObjects = (AllObjectDescribe)JSON.deserialize(res.getBody(), 
        AllObjectDescribe.class);

    } catch (Exception e) {
      if (e.getMessage().contains('Unauthorized endpoint')) {
        unautorisedEndPointURL = endpointServerUrl.substring(0, 
          endpointServerUrl.indexOf('/', 8));
      }
      Apexpages.addMessages(e);
    }
    return allObjects; 
  }

  public ObjectDefinition getSobjectsDetailsFor(String objAPIName) {
    Http h = new Http();
    Httprequest req = getHttpRestRequest('sobjects/'+objAPIName+'/describe');
    ObjectDefinition objDetails = null;
    try {
      Httpresponse res = h.send(req);
    
      objDetails = (ObjectDefinition)JSON.deserialize(
        res.getBody(), ObjectDefinition.class);

    } catch (Exception e) {
      Apexpages.addMessages(e);
    }
    return objDetails;
  }

  public RecordDetails getRecordsFor(ObjectDefinition objDetails, String whereCondition) {
    Http h = new Http();
    Httprequest req = getHttpRestRequest('query/?q='+getQueryFromObject(objDetails, whereCondition));
    RecordDetails rd = null;
    
    try {
      Httpresponse res = h.send(req);
      System.debug(res.getBody());
      if (res.getStatusCode() == 200) {
        rd = (RecordDetails)JSON.deserialize(res.getBody(), RecordDetails.class);
      } else {
        Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, res.getBody()));
      }
    } catch (Exception e) {
      Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, OBJECT_OR_ALL_FIELDS_NOT_AVAILABLE));
      Apexpages.addMessages(e);
    }
    return rd;
  }
  
  private String getQueryFromObject(ObjectDefinition objDetails, String whereCondition) {
    String fieldsToQuery = '';
    Boolean isAnyFieldSelected = false;
    for (FieldDefinition fd : objDetails.fields) {
      if (fd.updateable == 'true' && fd.isSelected) {
        fieldsToQuery += fd.name + ', ';
        isAnyFieldSelected = true;
      }
    }
    if (!isAnyFieldSelected) {
      fieldsToQuery += 'Id, CreatedDate, LastModifiedDate';
    }
    
    fieldsToQuery = fieldsToQuery.removeEnd(', ');
    
    System.debug('@@ fieldsToQuery:  '+fieldsToQuery);

    String query = 'select '+fieldsToQuery+' from '+objDetails.name + ' ' + whereCondition; //+' order by LastModifiedDate desc limit 200'; 
    query = Encodingutil.urlEncode(query, 'UTF-8');   
    return query;
  }
  
  private Httprequest getHttpRestRequest(String endpointUrlSuffix) {
    Httprequest req = new Httprequest();
    req.setEndpoint(baseUrl + '/services/data/v' + versionNumber + '/' + endpointUrlSuffix);
    req.setMethod('GET');
    req.setHeader('Authorization', 'OAuth ' + sessionId);
    req.setHeader('Content-Type', 'application/json');
    req.setTimeout(60000);
    return req;
  }

  private void parseResponse(Httpresponse res) {
    Dom.Xmlnode rootNode = res.getBodyDocument().getRootElement();
    Dom.Xmlnode soapBodyNode = rootNode.getChildElement('Body', soapNamespace);
    Dom.Xmlnode resultNode = soapBodyNode.getChildElement('loginResponse',
      resNamespace).getChildElement('result', resNamespace);
    
    metaDataSrvrUrl =
      resultNode.getChildElement('metadataServerUrl', resNamespace).getText();
    isSandbox = Boolean.valueOf(
      resultNode.getChildElement('sandbox', resNamespace).getText());
    serverUrl = resultNode.getChildElement('serverUrl', resNamespace).getText();
    sessionId = resultNode.getChildElement('sessionId', resNamespace).getText();
    endpointServerUrl = serverUrl;

    List<String> splitedURL = serverUrl.split('/');

    baseUrl = splitedURL.get(0) + '//' + splitedURL.get(2);
    versionNumber = splitedURL.get(6);
  }
  
  private String getLoginRequestBody(String username, String password) {
    return '<?xml version="1.0" encoding="utf-8" ?>'
      + '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
      + ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
      + ' xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">'
      + '<env:Body>'
      + '<n1:login xmlns:n1="urn:partner.soap.sforce.com">'
      + '<n1:username>' + username + '</n1:username>'
      + '<n1:password>' + password + '</n1:password>'
      + '</n1:login>'
      + '</env:Body>'
      + '</env:Envelope>';  
  }
}