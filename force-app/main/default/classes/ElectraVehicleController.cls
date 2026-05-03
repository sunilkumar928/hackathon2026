public
without sharing class ElectraVehicleController {
  public
  ElectraVehicleController() {
  }
  /**
   * Returns all active Vehicle records with their
   * related VehicleDefinition__c and CurrentOwner Account data.
   *
   * Called via @wire(getVehiclesWithDefinitions) in the LWC.
   */
  @AuraEnabled(cacheable = true) public static List<Vehicle> getVehiclesWithDefinitions() {
    return [
      SELECT
          /* ── Vehicle core ── */
          Id,
      Name,
      Status,
      FuelSource,
      ModelName,
      ModelYear,
      MakeName,
      TrimLevel,
      ExteriorColor,
      InteriorColor,
      UpholsteryColor,
      ConditionType,
      Classification,
      ChassisNumber,
      EngineNumber,
      VehicleIdentificationNumber,
      VIN__c,
      LicensePlate__c,
      Mileage__c,
      DrivetrainSystem,
      Ownership_Type__c,

      /* ── Pricing ── */
      MarketPrice,
      AverageMarketValue,
      HighestMarketValue,
      LowestMarketValue,
      LatestResidualValue,

      /* ── Service & Warranty ── */
      ActiveWarrantyCount,
      ActiveServiceContractCount,
      LastServiceDate,
      ManufacturerWarrantyEndDate,
      ManufacturerWarrantyStartDt,
      ManufacturedDate,

      /* ── Odometer ── */
      LastOdometerReading,
      OdometerReadingDate,
      OdometerState,

      /* ── Connected / Telematics ── */
      IsConnectedServiceActive,
      IsTelematicsServiceActive,
      Is_Test_Drive_Available__c,
      IsRecallOpen,

      /* ── Formula fields ── */
      showroom_Name__c,
      Showroom_Zip_Code__c,

      /* ── Registration ── */
      VehicleRegistrationNumber,
      RegistrationValidityDate,
      RegistrationRegionCode,

      /* ── Related: VehicleDefinition__c ── */
      VehicleDefinitionId,
      VehicleDefinition.Name,
      VehicleDefinition.VariantName,
      VehicleDefinition.ModelCode,
      VehicleDefinition.BodyType,
      VehicleDefinition.Body_Style__c,
      VehicleDefinition.DoorCount,
      VehicleDefinition.DoorStyle,
      VehicleDefinition.Seats__c,

      /* Powertrain */
      VehicleDefinition.FuelSource,
      VehicleDefinition.Fuel_Type__c,
      VehicleDefinition.DrivetrainSystem,
      VehicleDefinition.TransmissionSystem,
      VehicleDefinition.EngineName,
      VehicleDefinition.EngineCubicCapacity,
      VehicleDefinition.TotalPower,
      VehicleDefinition.MaximumTorque,
      VehicleDefinition.AccelerationTime,
      VehicleDefinition.TopSpeed,
      VehicleDefinition.CombinedFuelEconomy,

      /* Battery / EV */
      VehicleDefinition.MainBatteryType,
      VehicleDefinition.AuxiliaryBatteryType,
      VehicleDefinition.BatteryCapacity,
      VehicleDefinition.MaximumBatteryRange,
      VehicleDefinition.MinimumBatteryRange,

      /* Dimensions */
      VehicleDefinition.Height,
      VehicleDefinition.Width,
      VehicleDefinition.Length,
      VehicleDefinition.Wheelbase,
      VehicleDefinition.CurbWeight,
      VehicleDefinition.MaximumGrossWeight,
      VehicleDefinition.FuelTankCapacity,

      /* Emission & Classification */
      VehicleDefinition.EmissionStandard,
      VehicleDefinition.VehicleClass,

      /* Media & eligibility */
      VehicleDefinition.Image_URL__c,
      VehicleDefinition.Test_Drive_Eligible__c,

      /* ── Related: Account (Current Owner) ── */
      CurrentOwnerId,
      CurrentOwner.Name,
      CurrentOwner.Phone,
      CurrentOwner.PersonEmail,
      CurrentOwner.PersonMobilePhone,
      CurrentOwner.BillingAddress,
      CurrentOwner.ShippingAddress,
      CurrentOwner.Type,
      CurrentOwner.AccountSource,
      CurrentOwner.WhatsApp_Business_ID__c,
      CurrentOwner.Service_Area_Zips__c,
      CurrentOwner.IsActive__c

              FROM Vehicle WHERE Status
          != 'Decommissioned' AND Status != 'Scrapped' ORDER BY ModelName ASC,
      ModelYear DESC LIMIT 200
    ];
  }

  /**
   * Returns a single Vehicle record with full detail
   * for the record-detail / modal view.
   */
  @AuraEnabled(cacheable = true) public static Vehicle getVehicleDetail(Id vehicleId) {
    return [SELECT Id,
      Name,
      Status,
      FuelSource,
      ModelName,
      ModelYear,
      MakeName,
      TrimLevel,
      ExteriorColor,
      InteriorColor,
      ChassisNumber,
      EngineNumber,
      VehicleIdentificationNumber,
      VIN__c,
      LicensePlate__c,
      Mileage__c,
      DrivetrainSystem,
      Ownership_Type__c,
      MarketPrice,
      AverageMarketValue,
      ActiveWarrantyCount,
      ActiveServiceContractCount,
      LastServiceDate,
      ManufacturerWarrantyEndDate,
      IsConnectedServiceActive,
      IsTelematicsServiceActive,
      Is_Test_Drive_Available__c,
      IsRecallOpen,
      showroom_Name__c,
      Showroom_Zip_Code__c,
      VehicleRegistrationNumber,
      RegistrationValidityDate,
      VehicleDefinitionId,
      VehicleDefinition.Name,
      VehicleDefinition.VariantName,
      VehicleDefinition.TotalPower,
      VehicleDefinition.MaximumTorque,
      VehicleDefinition.TopSpeed,
      VehicleDefinition.BatteryCapacity,
      VehicleDefinition.MaximumBatteryRange,
      VehicleDefinition.AccelerationTime,
      VehicleDefinition.DrivetrainSystem,
      VehicleDefinition.TransmissionSystem,
      VehicleDefinition.MainBatteryType,
      VehicleDefinition.EmissionStandard,
      VehicleDefinition.Seats__c,
      VehicleDefinition.Image_URL__c,
      VehicleDefinition.Test_Drive_Eligible__c,
      VehicleDefinition.Height,
      VehicleDefinition.Width,
      VehicleDefinition.Length,
      VehicleDefinition.Wheelbase,
      CurrentOwnerId,
      CurrentOwner.Name,
      CurrentOwner.Phone,
      CurrentOwner.PersonEmail,
      CurrentOwner.PersonMobilePhone,
      CurrentOwner.BillingAddress,
      CurrentOwner.Type FROM Vehicle WHERE Id =:vehicleId LIMIT 1];
  }

  /**
   * Returns accounts of type 'Dealer' or 'Partner'
   * for the dealer locator / contact section.
   */
  @AuraEnabled(cacheable = true) public static List<Account> getDealerAccounts() {
    return [
      SELECT Id,
      Name,
      Phone,
      PersonMobilePhone,
      PersonEmail,
      BillingAddress,
      ShippingAddress,
      Website,
      Type,
      AccountSource,
      WhatsApp_Business_ID__c,
      Service_Area_Zips__c,
      IsActive__c,
      OperatingHoursId FROM Account WHERE Type IN('Dealer', 'Partner', 'Channel') AND IsActive__c =
          true ORDER BY Name ASC LIMIT 100
    ];
  }
}