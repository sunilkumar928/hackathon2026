public
with sharing class GeolocationDealerFinder {
  public
  GeolocationDealerFinder() {
  }
  @InvocableMethod(
      label = 'Find Nearest Dealer Via Geolocation API' description =
          'Uses Google Maps API to find nearest dealers by zip') public static List<Response> findNearestDealers(List<Request>
          requests) {
    List<Response> responses = new List<Response>();

    for (Request req : requests) {
      Response res = new Response();

      // Step 1: Get lat/lng for the customer zip code
      GeoPoint customerLocation = getLatLngFromZip(req.zipCode);

      if (customerLocation == null) {
        res.errorMessage = 'Could not resolve zip code: ' + req.zipCode;
        responses.add(res);
        continue;
      }

      // Step 2: Get all dealers from Salesforce
      List<Account> dealers = [
        SELECT Id,
        Name,
        Phone,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode FROM Account WHERE RecordType.DeveloperName =
            'Vehicle_Dealer' AND BillingPostalCode != null LIMIT 20
      ];

      // Step 3: Build dealer addresses for Distance Matrix call
      List<String> destinations = new List<String>();
      for (Account d : dealers) {
        destinations.add(EncodingUtil.urlEncode(
            d.BillingStreet + ',' + d.BillingCity + ',' + d.BillingState, 'UTF-8'));
      }

      // Step 4: Call Google Distance Matrix API
      String apiKey = Label.Google_Maps_API_Key;  // Store in Custom Label
      String origin = customerLocation.lat + ',' + customerLocation.lng;
      String destParam = String.join(destinations, '|');

      String endpoint = 'https://maps.googleapis.com/maps/api/distancematrix/json' + '?origins='
          + origin + '&destinations=' + destParam + '&units=imperial' + '&key=' + apiKey;

      HttpRequest httpReq = new HttpRequest();
      httpReq.setEndpoint(endpoint);
      httpReq.setMethod('GET');
      httpReq.setTimeout(10000);

      Http http = new Http();
      HttpResponse httpRes = http.send(httpReq);

      if (httpRes.getStatusCode() == 200) {
        res = parseDistanceMatrixResponse(httpRes.getBody(), dealers);
      } else {
        res.errorMessage = 'API Error: ' + httpRes.getStatus();
      }

      responses.add(res);
    }
    return responses;
  }

  // Geocode zip to lat/lng using Google Geocoding API
  private
  static GeoPoint getLatLngFromZip(String zipCode) {
    String apiKey = Label.Google_Maps_API_Key;
    String endpoint = 'https://maps.googleapis.com/maps/api/geocode/json' + '?address=' + zipCode
        + '&key=' + apiKey;

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');

    HttpResponse res = new Http().send(req);
 system.debug('Status code '+res.getStatusCode() );
    if (res.getStatusCode() == 200) {
      Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
      List<Object> results = (List<Object>) body.get('results');
        String status = (String) body.get('status');
        System.debug('Google API Error Status: ' + status); 
        System.debug('Google API Error Message: ' + body.get('error_message'));

      if (!results.isEmpty()) {
        Map<String, Object> geometry =
            (Map<String, Object>) ((Map<String, Object>) results[0]).get('geometry');
        Map<String, Object> location = (Map<String, Object>) geometry.get('location');

        GeoPoint point = new GeoPoint();
        point.lat = String.valueOf(location.get('lat'));
        point.lng = String.valueOf(location.get('lng'));
        return point;
      }
    } else {
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    String status = (String) body.get('status');
        System.debug('Google API Error Status: ' + status); 
        System.debug('Google API Error Message: ' + body.get('error_message'));
    }
    return null;
  }

  // Parse API response and pick nearest dealer
  private
  static Response parseDistanceMatrixResponse(String body, List<Account> dealers) {
    Response res = new Response();
    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
    List<Object> rows = (List<Object>) parsed.get('rows');

    if (rows == null || rows.isEmpty()) return res;
    List<Object> elements = (List<Object>) ((Map<String, Object>) rows[0]).get('elements');
    Integer nearestIndex = 0;
    Long shortestDistance = 1000;  // in meters

    for (Integer i = 0; i < elements.size(); i++) {
      Map<String, Object> el = (Map<String, Object>) elements[i];
      if (el.get('status') == 'OK') {
        Map<String, Object> distMap = (Map<String, Object>) el.get('distance');
        Long meters = Long.valueOf(String.valueOf(distMap.get('value')));
        if (meters < shortestDistance) {
          shortestDistance = meters;
          nearestIndex = i;
        }
      }
    }

    Account nearest = dealers[nearestIndex];
    Map<String, Object> nearestEl = (Map<String, Object>) elements[nearestIndex];
    Map<String, Object> distMap = (Map<String, Object>) nearestEl.get('distance');
    Map<String, Object> durMap = (Map<String, Object>) nearestEl.get('duration');

    res.dealerName = nearest.Name;
    res.dealerPhone = nearest.Phone;
    res.dealerCity = nearest.BillingCity + ', ' + nearest.BillingState;
    res.distanceText = (String) distMap.get('text');  // e.g. "12.3 mi"
    res.durationText = (String) durMap.get('text');   // e.g. "18 mins"
    res.dealerCount = 1;
    return res;
  }

  public
  class GeoPoint {
    public
    String lat;
    public
    String lng;
  }

  public class Request {
    @InvocableVariable(label = 'Customer Zip Code' required = true) public String zipCode;
  }

  public class Response {
    @InvocableVariable(label = 'Nearest Dealer Name') public String dealerName;
    @InvocableVariable(label = 'Dealer Phone') public String dealerPhone;
    @InvocableVariable(label = 'Dealer City') public String dealerCity;
    @InvocableVariable(label = 'Distance') public String distanceText;
    @InvocableVariable(label = 'Drive Time') public String durationText;
    @InvocableVariable(label = 'Dealer Count') public Integer dealerCount;
    @InvocableVariable(label = 'Error Message') public String errorMessage;
  }
}