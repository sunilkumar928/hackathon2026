/**
 * @functionality  Utility class
 * @description  HttpRequestBuilder is utility class which provide the callout
 * functionality.
 **/
public
without sharing class HttpRequestBuilder {
  public
  static final String AUTHORIZATION_HEADER = 'Authorization';
  public
  static final String BEARER_TOKEN_TYPE = 'Bearer';
  public
  static final String DEFAULT_CONTENT_TYPE = 'application/json;charset=UTF-8';
  public
  static final Integer DEFAULT_TIMEOUT = 10000;
  public
  static final String HEADER_CONTENT_TYPE = 'Content-Type';
  public
  static final String HTTP_DELETE = 'DELETE';
  public
  static final String HTTP_GET = 'GET';
  public
  static final String HTTP_POST = 'POST';
  public
  static final String HTTP_PATCH = 'PATCH';
  public
  static final String HTTP_PUT = 'PUT';
  public
  static final String INVALID_CONTENT_TYPE_MESSAGE = 'Http Request Content-Type should not be NULL';
  public
  static final String INVALID_ENDPOINT_MESSAGE = 'Http Request Endpoint is invalid';
  public
  static final String INVALID_HEADER_MESSAGE = 'Http Request Header is Invalid';
  public
  static final String INVALID_METHOD_MESSAGE = 'Http Request MethodType is invalid';
  public
  static final String INVALID_REQUEST_BODY_MESSAGE = 'Invalid Http Request Body';
  public
  static final String INVALID_TIMEOUT_MESSAGE = 'Http Reuest Timeout should not be NUll';
  private
  HttpRequest request;
  /**
   * @description  HttpRequestBuilder constructor to intialize Http request with default content
   * type and default timeout
   */
  public
  HttpRequestBuilder() {
    request = new HttpRequest();
    request.setHeader(HEADER_CONTENT_TYPE, DEFAULT_CONTENT_TYPE);
    request.setTimeout(DEFAULT_TIMEOUT);
  }
  /**
   * @description  The method is to send DELETE request to perform the REST callout
   * @return HttpResponse REST Callout Response
   */
  public
  HttpResponse sendDeleteRequest() {
    return sendRequest(HTTP_DELETE);
  }
  /**
   * @description  The method is to send GET request to perform REST callout
   * @return HttpResponse REST Callout Response
   */
  public
  HttpResponse sendGetRequest() {
    return sendRequest(HTTP_GET);
  }

  /**
   * @description  The method is to send POST request to perform REST callout
   * @return HttpResponse REST Callout Response
   */
  public
  HttpResponse sendPostRequest() {
    return sendRequest(HTTP_POST);
  }
    
  /**
   * @description  The method validates and sets the body as blob for Http Request.
   * @param bodyAsBlob  request body to set
   * @return HttpRequestBuilder
   */
  public
  HttpRequestBuilder setBodyAsBlob(Blob bodyAsBlob) {
    if (bodyAsBlob == null) {
      throw new IllegalArgumentException(INVALID_REQUEST_BODY_MESSAGE);
    }
    request.setBodyAsBlob(bodyAsBlob);
    return this;
  }
  /**
   * @description  The method validates and sets the body for Http Request.
   * @param body  request body to set
   * @return HttpRequestBuilder
   */
  public
  HttpRequestBuilder setBody(String body) {
    if (body == null) {
      throw new IllegalArgumentException(INVALID_REQUEST_BODY_MESSAGE);
    }
    request.setBody(body);
    return this;
  }
  /**
   * @description  The method validates and sets the content type for Http Request Header.
   * @param contentType  request content type
   * @return HttpRequestBuilder
   */
  public
  HttpRequestBuilder setContentType(String contentType) {
    if (String.isBlank(contentType)) {
      throw new IllegalArgumentException(INVALID_CONTENT_TYPE_MESSAGE);
    }
    request.setHeader(HEADER_CONTENT_TYPE, contentType);
    return this;
  }
  /**
   * @description  The method validates and sets Endpoint for Http Request.
   * @param endpoint  request endpoint to set
   * @return HttpRequestBuilder
   */
  public
  HttpRequestBuilder setEndpoint(String endpoint) {
    if (String.isBlank(endpoint)) {
      throw new IllegalArgumentException(INVALID_ENDPOINT_MESSAGE);
    }
    request.setEndpoint(endpoint);
    return this;
  }
  /**
   * @description  The method validates and sets the header for Http Request.
   * @param headerKey
   * @param headerValue
   * @return HttpRequestBuilder
   */
  public
  HttpRequestBuilder setHeader(String headerKey, String headerValue) {
    if (String.isBlank(headerKey) || String.isBlank(headerValue)) {
      throw new IllegalArgumentException(INVALID_HEADER_MESSAGE);
    }
    request.setHeader(headerKey, headerValue);
    return this;
  }
  /**
   * @description  The method validates and sets the timeout for Http Request.
   * @param timeout  request time out in milliseconds
   * @return HttpRequestBuilder
   */
  public
  HttpRequestBuilder setTimeout(Integer timeout) {
    if (timeout == null) {
      throw new IllegalArgumentException(INVALID_TIMEOUT_MESSAGE);
    }
    request.setTimeout(timeout);
    return this;
  }
  /**
   * @description  The method is to send Http request to perform REST Callout.
   * @param method  REST Callout method type
   * @return HttpResponse REST Callout Response
   */
  private
  HttpResponse sendRequest(String method) {
    if (String.isBlank(request.getEndpoint())) {
      throw new IllegalArgumentException(INVALID_ENDPOINT_MESSAGE);
    }
    request.setMethod(method);
    return new Http().send(request);
  }
}