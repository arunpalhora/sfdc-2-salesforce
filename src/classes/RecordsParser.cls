public with sharing class RecordsParser {

  public static RecordDetails parseJSONResponse(String jsonResponse) {
    System.debug('###jsonResponse: '+jsonResponse);
    RecordDetails rdWrap = (RecordDetails)JSON.deserialize(jsonResponse, RecordDetails.class);
    System.debug('###rdWrap: '+rdWrap);

    return rdWrap;
  }
}