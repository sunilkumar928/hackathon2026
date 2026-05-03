@IsTest private class ElectraShowcaseControllerTest {
  @IsTest static void testGetVehicleModels_returnsRecords() {
    Test.startTest();
    List<ElectraShowcaseController.VehicleModelWrapper> models =
        ElectraShowcaseController.getVehicleModels();
    Test.stopTest();

    System.assertNotEquals(null, models, 'getVehicleModels() should never return null');
    System.assert(
        models.size() >= 3, 'Expected at least 3 Vehicle Model CMT records (Apex, Nova, Zenith)');
  }

  @IsTest static void testGetVehicleModels_sortOrderAscending() {
    Test.startTest();
    List<ElectraShowcaseController.VehicleModelWrapper> models =
        ElectraShowcaseController.getVehicleModels();
    Test.stopTest();

    if (models.size() < 2) {
      return;
    }

    for (Integer i = 1; i < models.size(); i++) {
      Decimal prev = models[i - 1].sortOrder;
      Decimal curr = models[i].sortOrder;
      if (prev != null && curr != null) {
        System.assert(prev <= curr, 'Records should be sorted by SortOrder__c ascending');
      }
    }
  }

  @IsTest static void testGetVehicleModels_wrapperFieldsPopulated() {
    Test.startTest();
    List<ElectraShowcaseController.VehicleModelWrapper> models =
        ElectraShowcaseController.getVehicleModels();
    Test.stopTest();

    for (ElectraShowcaseController.VehicleModelWrapper w : models) {
      System.assertNotEquals(null, w.label, 'label should be populated for: ' + w.developerName);
      System.assertNotEquals(null, w.badge, 'badge should be populated for: ' + w.developerName);
      System.assertNotEquals(
          null, w.rangeKm, 'rangeKm should be populated for: ' + w.developerName);
      System.assertNotEquals(
          null, w.peakPowerBhp, 'peakPowerBhp should be populated for: ' + w.developerName);
      System.assertNotEquals(
          null, w.description, 'description should be populated for: ' + w.developerName);
    }
  }
}