/**
 * @functionality Docusign with REST API
 * @description This class is used to get the Base End Point and other parameters of Docusign
 * related REST API Callouts.
 */
public
class DocusignRESTAPIHelper {
  public
  static final String AUTHENTICATION_METHOD_NONE = 'None';
  public
  static final String DOCUSIGN_BASE_END_POINT_URL = getDocusignSettingValue('Docusign_Base_End_Point_URL');
  public
  static final String DOCUMENTS = 'documents';
  public
  static final String ENVELOPE_STATUS_COMPLETED = 'completed';
  public
  static final String ENVELOPE_STATUS_SENT = 'sent';
  public
  static final String ENVELOPES = 'envelopes';
  public
  static final String NDA = 'NDA';
  public
  static final String RECIPIENT = 'recipient';
  public
  static final Integer STATUS_CODE_FOUR_HUNDRED = 400;
  public
  static final String VIEWS = 'views';

  /**
   * @description This class has abstract methods to make Rest API callouts and also to get the HTTP
   * responses in return
   */
  public
  abstract class DocusignRESTRequest {
    public
    abstract String getEndPointUrl();
    public
    abstract String getMethod();
    protected
    abstract DocusignRESTResponse getResponse(String responseBody);
    protected
    virtual DocusignRESTResponse getResponseObject(HttpResponse response) {
      return getResponse(response.getBody());
    }

    /**
     * @description Returns the Request body
     * @return String Request body
     */
    public
    String getBody() {
      return JSON.serialize(this);
    }

    /**
     * @description Method to make REST API callouts and retrieve respective response
     * @return DocusignRESTResponse Docusign REST response
     */
    public
    DocusignRESTResponse sendDocusignRESTRequest() {
      HttpResponse response = NULL;
      HttpRequestBuilder builder = new HttpRequestBuilder()
                                       .setEndpoint(DOCUSIGN_BASE_END_POINT_URL + getEndPointUrl())
                                       .setContentType(HttpRequestBuilder.DEFAULT_CONTENT_TYPE);
      switch
        on getMethod() {
          when 'POST' {
            builder.setBody(getBody());
            response = builder.sendPOSTRequest();
          }
          when 'GET' {
            response = builder.sendGETRequest();
          }
        }
      return getResponse(response);
    }

    /**
     * @description Method to extract the responses or otherwise throws the Exception
     * @param response Http response
     * @return DocusignRESTResponse Docusign REST response
     */
    private
    DocusignRESTResponse getResponse(HttpResponse response) {
      if (response.getStatusCode() == STATUS_CODE_FOUR_HUNDRED) {
        throw new AuraHandledException(response.getBody());
      } else {
        return getResponseObject(response);
      }
    }
  }

  /**
   * @description This abstract class is used to extract the body out of all the REST API Callouts
   * responses.
   */
  public abstract class DocusignRESTResponse {
  }

  /**
   * @description This class is used to form the request body for creating the Envelope and get the
   * Envelope Id from the response.
   */
  public class CreateEnvelopeRequest extends DocusignRESTRequest {
    public
    String templateId;
    public
    String status;
    public
    List<TemplateRole> templateRoles = new List<TemplateRole>();

    /**
     * @description Returns the End Point URL to create the Envelope
     * @return String End point URL
     */
    public
    override String getEndPointUrl() {
      return ENVELOPES;
    }

    /**
     * @description Returns the Type of Request
     * @return String Type of Request
     */
    public
    override String getMethod() {
      return HttpRequestBuilder.HTTP_POST;
    }

    /**
     * @description Returns the REST response
     * @param responseBody Response body
     * @return DocusignRESTResponse Docusign REST response
     */
    protected
    override DocusignRESTResponse getResponse(String responseBody) {
      return (DocusignRESTResponse) JSON.deserialize(responseBody, CreateEnvelopeResponse.Class);
    }

    /**
     * @description Assign Template Roles to Template Roles list
     * @param roleName Role name
     * @param email Email
     * @param userName Name of the User
     */
    public
    void addTemplateRole(String roleName, String email, String userName) {
      TemplateRole newTemplateRole = new TemplateRole();
      newTemplateRole.roleName = roleName;
      newTemplateRole.email = email;
      newTemplateRole.clientUserId = email;
      newTemplateRole.name = userName;
      templateRoles.add(newTemplateRole);
    }
  }

  /**
   * @description This class is used to extract the Envelope Id out of Envelope response.
   */
  public class CreateEnvelopeResponse extends DocusignRESTResponse {
    public
    String envelopeId;
  }

  /**
   * @description This class is used to form the request body for retreiving the Envelope document
   * from the response.
   */
  public class GetDocumentRequest extends DocusignRESTRequest {
    public
    String envelopeId;
    public
    String documentId;

    /**
     * @description Returns the End Point URL to get the Document based on Document Id
     * @return String End point URL
     */
    public
    override String getEndPointUrl() {
      return ENVELOPES + '/' + envelopeId + '/' + DOCUMENTS + '/' + documentId;
    }

    /**
     * @description Returns the Type of Request
     * @return String Type of Request
     */
    public
    override String getMethod() {
      return HttpRequestBuilder.HTTP_GET;
    }

    /**
     * @description Returns the REST response
     * @param responseBody Response body
     * @return DocusignRESTResponse Docusign REST response
     */
    protected
    override DocusignRESTResponse getResponse(String responseBody) {
      return new GetDocumentsResponse();
    }

    /**
     * @description Returns the REST response
     * @param response Http response
     * @return DocusignRESTResponse Docusign REST response
     */
    protected
    override DocusignRESTResponse getResponseObject(HttpResponse response) {
      GetDocumentsResponse getDocumentsResponseObj = new GetDocumentsResponse();
      getDocumentsResponseObj.base64EncodedString =
          EncodingUtil.base64Encode(response.getBodyAsBlob());
      return (DocusignRESTResponse) getDocumentsResponseObj;
    }
  }

  /**
   * @description This class is used to extract the Base 64 encoded String of document out of the
   * Document request response.
   */
  public class GetDocumentsResponse extends DocusignRESTResponse {
    public
    String base64EncodedString;
  }

  /**
   * @description This class is used to form the request body and gets the Envelope Status from the
   * response.
   */
  public class GetEnvelopeRequest extends DocusignRESTRequest {
    public
    String envelopeId;

    /**
     * @description Returns the End Point URL to get the Envelope Status
     * @return String End point URL
     */
    public
    override String getEndPointUrl() {
      return ENVELOPES + '/' + envelopeId;
    }

    /**
     * @description Returns the Type of Request
     * @return String Type of Request
     */
    public
    override String getMethod() {
      return HttpRequestBuilder.HTTP_GET;
    }

    /**
     * @description Returns the REST response
     * @param responseBody Response body
     * @return DocusignRESTResponse Docusign REST response
     */
    protected
    override DocusignRESTResponse getResponse(String responseBody) {
      return (DocusignRESTResponse) JSON.deserialize(responseBody, GetEnvelopeResponse.Class);
    }
  }

  /**
   * @description This class is used to extract the status out of Envelope response.
   */
  public class GetEnvelopeResponse extends DocusignRESTResponse {
    public
    String status;
  }

  /**
   * @description This class is used to form the request body for retreiving the Envelope documents
   * list from the response.
   */
  public class ListDocumentsRequest extends DocusignRESTRequest {
    public
    String envelopeId;

    /**
     * @description Returns the End Point URL to get the List of Documents based on Envelope Id
     * @return String End point URL
     */
    public
    override String getEndPointUrl() {
      return ENVELOPES + '/' + envelopeId + '/' + DOCUMENTS;
    }

    /**
     * @description Returns the Type of Request
     * @return String Type of Request
     */
    public
    override String getMethod() {
      return HttpRequestBuilder.HTTP_GET;
    }

    /**
     * @description Returns the REST response
     * @param responseBody Response body
     * @return DocusignRESTResponse Docusign REST response
     */
    protected
    override DocusignRESTResponse getResponse(String responseBody) {
      return (DocusignRESTResponse) JSON.deserialize(responseBody, ListDocumentsResponse.Class);
    }
  }

  /**
   * @description This class is used to extract the List of Envelope documents out of Envelope
   * response.
   */
  public class ListDocumentsResponse extends DocusignRESTResponse {
    public
    List<EnvelopeDocument> envelopeDocuments;
  }

  /**
   * @description This class is used to form the request body and gets the signing URL from the
   * response.
   */
  public class RecipientViewRequest extends DocusignRESTRequest {
    public
    String authenticationMethod;
    public
    String clientUserId;
    public
    String email;
    public
    String envelopeId;
    public
    String returnUrl;
    public
    String userName;

    /**
     * @description Returns the End Point URL to get the signing URL based on envelope Id
     * @return String End point URL
     */
    public
    override String getEndPointUrl() {
      return ENVELOPES + '/' + envelopeId + '/' + VIEWS + '/' + RECIPIENT;
    }

    /**
     * @description Returns the Type of Request
     * @return String Type of Request
     */
    public
    override String getMethod() {
      return HttpRequestBuilder.HTTP_POST;
    }

    /**
     * @description Returns the REST response
     * @param responseBody Response body
     * @return DocusignRESTResponse Docusign REST response
     */
    protected
    override DocusignRESTResponse getResponse(String responseBody) {
      return (DocusignRESTResponse) JSON.deserialize(responseBody, RecipientViewResponse.Class);
    }
  }

  /**
   * @description This class is used to extract the signing URL out of the Recipient View Request
   * response.
   */
  public class RecipientViewResponse extends DocusignRESTResponse {
    public
    String url;
  }

  /**
   * @description Inner wrapper class of Envelope Document
   */
  public class EnvelopeDocument {
    public
    String documentId;
    public
    String name;
    public  // Not used for deserialization and instead used for internal purpose
    String base64EncodedString;
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
   * @description Inner wrapper class for Template Role
   */
  public class TemplateRole {
    public
    String roleName;
    public
    String email;
    public
    String name;
    public
    String clientUserId;
    public
    String recipientId;
  }
}