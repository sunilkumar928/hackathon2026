/**
 * @description Controller for Electra Cars Vehicle Showcase LWC.
 *              Fetches VehicleModel__mdt records ordered by SortOrder__c.
 * @author      Electra Cars Development Team
 * @apiVersion  61.0
 */
public
without sharing class ElectraShowcaseController {
  public
  class VehicleModelWrapper {
    @AuraEnabled public String displayUrl;
    @AuraEnabled public String developerName;
    @AuraEnabled public String label;
    @AuraEnabled public String badge;
    @AuraEnabled public String tagline;
    @AuraEnabled public Decimal startingPrice;
    @AuraEnabled public String batterySpec;
    @AuraEnabled public Decimal rangeKm;
    @AuraEnabled public Decimal zeroToHundred;
    @AuraEnabled public Decimal peakPowerBhp;
    @AuraEnabled public Decimal fastChargeMin;
    @AuraEnabled public String description;
    @AuraEnabled public String feature1Title;
    @AuraEnabled public String feature1Desc;
    @AuraEnabled public String feature2Title;
    @AuraEnabled public String feature2Desc;
    @AuraEnabled public String feature3Title;
    @AuraEnabled public String feature3Desc;
    @AuraEnabled public Decimal sortOrder;
    public
    VehicleModelWrapper(Product2 prod) {
      this.developerName = prod.ProductCode;
      this.label = prod.Name;
      this.badge = prod.Badge__c;
      this.developerName = prod.ProductCode;  // Mapping ProductCode to your developerName property
      this.label = prod.Name;                 // Mapping Name to your label property
      this.description = prod.Description;    // Standard Product2 Description field

      // Custom/Automotive Cloud Fields
      this.badge = prod.Badge__c;
      this.tagline = prod.Tagline__c;
      this.startingPrice = prod.StartingPrice__c;
      this.batterySpec = prod.BatterySpec__c;
      this.rangeKm = prod.RangeKm__c;
      this.zeroToHundred = prod.ZeroToHundred__c;
      this.peakPowerBhp = prod.PeakPowerBhp__c;
      this.fastChargeMin = prod.FastChargeMin__c;

      // Feature & UI Logic
      this.feature1Title = prod.Feature1Title__c;
      this.feature1Desc = prod.Feature1Desc__c;
      this.feature2Title = prod.Feature2Title__c;
      this.feature2Desc = prod.Feature2Desc__c;
      this.feature3Title = prod.Feature3Title__c;
      this.feature3Desc = prod.Feature3Desc__c;
      this.sortOrder = prod.SortOrder__c;
      this.displayUrl = prod.DisplayUrl;
    }
  }

  @AuraEnabled(cacheable = true) public static List<VehicleModelWrapper> getVehicleModels() {
    List<VehicleModelWrapper> results = new List<VehicleModelWrapper>();
      System.debug('Inside GetVehicles Method');

    for (Product2 record : [
           SELECT Name,
           ProductCode,
           Description,
           DisplayUrl,
        Feature2Title__c,
        Feature2Desc__c,
        Feature3Title__c,
        Feature3Desc__c,
           StockKeepingUnit,
           /* Custom Fields mapping to your MDT */
           Badge__c,
           Tagline__c,
           StartingPrice__c,
           BatterySpec__c,
           RangeKm__c,
           ZeroToHundred__c,
           PeakPowerBhp__c,
           FastChargeMin__c,
           Feature1Title__c,
           Feature1Desc__c,
           SortOrder__c FROM Product2 WHERE Family = 'EV Sedan' AND IsActive =
               true ORDER BY SortOrder__c ASC NULLS LAST
         ]) {
      // Assuming 'record' is now a Product2 sObject from your new query
      VehicleModelWrapper w = new VehicleModelWrapper(record);

      results.add(w);
    }
System.debug('results :: '+results);
    return results;
  }
}