/**
 * @functionality Docusign with REST API
 * @description This class is used to perform all the REST API callouts related to Docusign and gets
 * the desired responses.
 */
public
with sharing class DocusignRESTAPIService {
  private
  static DocusignRESTAPIService docusignRESTAPIServiceInstance;

  /**
   * @description Method checks for existing instance of handler and if not present
   * then creates one.
   * @return DocusignRESTAPIService type of object.
   */
  public
  static DocusignRESTAPIService getInstance() {
    if (docusignRESTAPIServiceInstance == null) {
      docusignRESTAPIServiceInstance = new DocusignRESTAPIService();
    }
    return docusignRESTAPIServiceInstance;
  }

  /**
   * @description Rest API callout to create an Envelope
   * @param email Email
   * @param userName User Name
   * @return String Envelope Id
   **/
  public static String createEnvelope( String email, String userName) {
    String settingValueJSON = getDocusignSettingValue('NDA_TestDrive_IN');
    // deserialize fetched string into settings variable.
    DocusignSettings settings =
        (DocusignSettings) JSON.deserialize(settingValueJSON, DocusignSettings.class);
    DocusignRESTAPIHelper.CreateEnvelopeRequest createEnvelopeRequestObj =
        new DocusignRESTAPIHelper.CreateEnvelopeRequest();
    createEnvelopeRequestObj.status = DocusignRESTAPIHelper.ENVELOPE_STATUS_SENT;
    createEnvelopeRequestObj.templateId = settings.templateId;
    createEnvelopeRequestObj.addTemplateRole(settings.templateRole, email, userName);
    DocusignRESTAPIHelper.CreateEnvelopeResponse createEnvelopeResponseObj =
        (DocusignRESTAPIHelper.CreateEnvelopeResponse)
            createEnvelopeRequestObj.sendDocusignRESTRequest();
    return createEnvelopeResponseObj.envelopeId;
  }

  /**
   * @description Rest API callout to generate the signing URL
   * @param email Email
   * @param userName User Name
   * @param envelopeId Envelope Id
   * @param returnUrl Return URL
   * @return String Signing URL
   **/
  public static String createEmbeddedSigningUrl(
      String email, String userName, String envelopeId, String returnUrl) {
    DocusignRESTAPIHelper.RecipientViewRequest recipientViewRequestObj =
        new DocusignRESTAPIHelper.RecipientViewRequest();
    recipientViewRequestObj.clientUserId = email;
    recipientViewRequestObj.email = email;
    recipientViewRequestObj.authenticationMethod = DocusignRESTAPIHelper.AUTHENTICATION_METHOD_NONE;
    recipientViewRequestObj.envelopeId = envelopeId;
    recipientViewRequestObj.userName = userName;
    recipientViewRequestObj.returnUrl = returnUrl;
    DocusignRESTAPIHelper.RecipientViewResponse recipientViewResponseObj =
        (DocusignRESTAPIHelper.RecipientViewResponse)
            recipientViewRequestObj.sendDocusignRESTRequest();
    return recipientViewResponseObj.url;
  }

  /**
   * @description Rest API callout to get the current Status of an Envelope and validate if its
   * Completed
   * @param envelopeId Envelope Id
   * @return Boolean Is Envelope Signing Status Completed
   **/
  public static Boolean getEnvelopeSigningStatus(String envelopeId) {
    DocusignRESTAPIHelper.GetEnvelopeRequest getEnvelopeRequestObj =
        new DocusignRESTAPIHelper.GetEnvelopeRequest();
    getEnvelopeRequestObj.envelopeId = envelopeId;
    DocusignRESTAPIHelper.GetEnvelopeResponse getEnvelopeResponseObj =
        (DocusignRESTAPIHelper.GetEnvelopeResponse) getEnvelopeRequestObj.sendDocusignRESTRequest();
    return getEnvelopeResponseObj.Status == DocusignRESTAPIHelper.ENVELOPE_STATUS_COMPLETED;
  }

  /**
   * @description Rest API callout to get a specified document of an Envelope
   * @param envelopeId Envelope Id
   * @param documentId Document Id
   * @return String Base 64 Encoded String
   **/
  public
  String getDocumentBody(String envelopeId, String documentId) {
    DocusignRESTAPIHelper.GetDocumentRequest getDocumentRequestObj =
        new DocusignRESTAPIHelper.GetDocumentRequest();
    getDocumentRequestObj.envelopeId = envelopeId;
    getDocumentRequestObj.documentId = documentId;
    DocusignRESTAPIHelper.GetDocumentsResponse getDocumentsResponseObj =
        (DocusignRESTAPIHelper.GetDocumentsResponse)
            getDocumentRequestObj.sendDocusignRESTRequest();
    return getDocumentsResponseObj.base64EncodedString;
  }

  /**
   * @description Rest API callout to get the list of documents in an Envelope
   * @param envelopeId Envelope Id
   * @return List<DocusignRESTAPIHelper.EnvelopeDocument> List of EnvelopeDocuments
   **/
  public
  List<DocusignRESTAPIHelper.EnvelopeDocument> getDocumentsList(String envelopeId) {
    DocusignRESTAPIHelper.ListDocumentsRequest listDocumentsRequestObj =
        new DocusignRESTAPIHelper.ListDocumentsRequest();
    listDocumentsRequestObj.envelopeId = envelopeId;
    DocusignRESTAPIHelper.ListDocumentsResponse listDocumentsResponseObj =
        (DocusignRESTAPIHelper.ListDocumentsResponse)
            listDocumentsRequestObj.sendDocusignRESTRequest();
    return listDocumentsResponseObj.envelopeDocuments;
  }
    
     /**
   * @description To get the value of metadata record
   * @param enpSettingName Developer name of metadata record
   * @return String Returns value of metadata record
   */
  public
  static String getDocusignSettingValue(String settingName) {
    return Docusign_Setting__mdt.getInstance(settingName) != null
        ? Docusign_Setting__mdt.getInstance(settingName).Value__c
        : null;
  }

  /**
   * @description Wrapper class to get the Template Id and Template Role
   */
  public
  class DocusignSettings {
    public
    String templateId;
    public
    String templateRole;
  }
}