import getVehiclesWithDefinitions from '@salesforce/apex/ElectraVehicleController.getVehiclesWithDefinitions';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {LightningElement, track, wire} from 'lwc';

// ── Color theme per Fuel Source picklist value ────────────────
const FUEL_THEME = {
  'Electric': {
    body: 'fill:#0F2520',
    roof: 'fill:#142D28',
    wheelHub: 'fill:#059669',
    wheelStr: 'stroke:#065F46',
    headlight: 'fill:#6EE7B7',
    taillight: 'fill:#065F46',
    imgBg:
        'background:radial-gradient(ellipse at 50% 65%,rgba(5,150,105,0.2) 0%,transparent 70%);background-color:#2A1B60',
    badgeCls: 'trim-badge b-electric'
  },
  'Hybrid': {
    body: 'fill:#1E2D60',
    roof: 'fill:#243570',
    wheelHub: 'fill:#2563EB',
    wheelStr: 'stroke:#1E3A8A',
    headlight: 'fill:#93C5FD',
    taillight: 'fill:#1E3A8A',
    imgBg:
        'background:radial-gradient(ellipse at 50% 65%,rgba(37,99,235,0.18) 0%,transparent 70%);background-color:#2A1B60',
    badgeCls: 'trim-badge b-hybrid'
  },
  'Petrol': {
    body: 'fill:#2D1515',
    roof: 'fill:#381818',
    wheelHub: 'fill:#DC2626',
    wheelStr: 'stroke:#7F1D1D',
    headlight: 'fill:#FCA5A5',
    taillight: 'fill:#7F1D1D',
    imgBg:
        'background:radial-gradient(ellipse at 50% 65%,rgba(185,28,28,0.18) 0%,transparent 70%);background-color:#2A1B60',
    badgeCls: 'trim-badge b-petrol'
  },
  'Diesel': {
    body: 'fill:#1E1535',
    roof: 'fill:#261B40',
    wheelHub: 'fill:#7C3AED',
    wheelStr: 'stroke:#4C1D95',
    headlight: 'fill:#C4B5FD',
    taillight: 'fill:#4C1D95',
    imgBg:
        'background:radial-gradient(ellipse at 50% 65%,rgba(124,58,237,0.22) 0%,transparent 70%);background-color:#2A1B60',
    badgeCls: 'trim-badge b-diesel'
  }
};

const DEFAULT_THEME = FUEL_THEME['Electric'];

// Max range used to calculate the range-bar percentage
const MAX_RANGE_KM = 600;
export default class ElectraIndiaPortal extends LightningElement {
  // ── State ───────────────────────────────────────────────
  @track _vehicles = [];
  @track _hoveredId = null;
  @track _activeFilter = 'All';
  @track isLoading = true;
  @track errorMessage = null;

  // ── Wire: fetch Vehicle__c + VehicleDefinition__c ───────
  @wire(getVehiclesWithDefinitions)
  wiredVehicles({data, error}) {
    console.log('Inside Wire Method top');
    if (data) {
      console.log('Inside Wire Method');
      this._vehicles = data;
      console.log('Vehicles Data :: ' + JSON.stringify(this._vehicles));
      this.isLoading = false;
      this.errorMessage = null;
    } else if (error) {
      this.isLoading = false;
      this.errorMessage =
          error?.body?.message || 'Unable to load vehicle data.';
    }
  }

  // ── Computed: loading / error / content guards ───────────
  get hasError() {
    return !!this.errorMessage;
  }
  get showContent() {
    return !this.isLoading && !this.hasError;
  }
  get noResults() {
    return this.showContent && this.displayedVehicles.length === 0;
  }
  get currentYear() {
    return new Date().getFullYear();
  }

  // ── Filter options built from loaded fuel source values ──
  get filterOptions() {
    const fuels =
        [...new Set(this._vehicles
                        .map(
                            v => v.FuelSource ||
                                v.VehicleDefinition?.FuelSource || 'Electric')
                        .filter(Boolean))];
    const opts = [
      {value: 'All', label: 'All Models', pillClass: this._pillClass('All')},
      {
        value: 'Electric',
        label: 'Electric',
        pillClass: this._pillClass('Electric')
      },
      {value: 'Hybrid', label: 'Hybrid', pillClass: this._pillClass('Hybrid')},
      {
        value: 'Available',
        label: 'Available',
        pillClass: this._pillClass('Available')
      },
      {
        value: 'TestDrive',
        label: 'Test Drive',
        pillClass: this._pillClass('TestDrive')
      },
    ];
    return opts;
  }

  _pillClass(val) {
    return val === this._activeFilter ? 'fpill active' : 'fpill';
  }

  // ── Filtered & mapped vehicle list ───────────────────────
  get displayedVehicles() {
    let list = [...this._vehicles];

    if (this._activeFilter === 'Electric') {
      list = list.filter(v => (v.FuelSource || '') === 'Electric');
    } else if (this._activeFilter === 'Hybrid') {
      list = list.filter(v => (v.FuelSource || '') === 'Hybrid');
    } else if (this._activeFilter === 'Available') {
      list = list.filter(v => v.Status === 'Available');
    } else if (this._activeFilter === 'TestDrive') {
      list = list.filter(v => v.Is_Test_Drive_Available__c === true);
    }

    return list.map(v => this._mapVehicle(v));
  }

  // ── Map a raw Vehicle__c record to display shape ─────────
  _mapVehicle(v) {
    const def = v.VehicleDefinition || {};  // VehicleDefinition__c
    const fuelSrc = v.FuelSource || def.FuelSource || 'Electric';
    const theme = FUEL_THEME[fuelSrc] || DEFAULT_THEME;
    const isHovered = v.Id === this._hoveredId;

    // Range bar
    const rawRange = def.MaximumBatteryRange || def.MinimumBatteryRange || '';
    const rangeNum = parseFloat(rawRange) || 0;
    const rangePct = Math.min(Math.round((rangeNum / MAX_RANGE_KM) * 100), 100);

    // Price — using MarketPrice from Vehicle__c; format as ₹ lakhs
    const priceNum = v.MarketPrice ?
        `₹${(v.MarketPrice / 100000).toFixed(2)} L` :
        'On request';

    // Feature chips derived from object fields
    const chips = [];
    if (def.TransmissionSystem) chips.push(def.TransmissionSystem);
    if (def.DrivetrainSystem) chips.push(def.DrivetrainSystem);
    if (def.EmissionStandard) chips.push(def.EmissionStandard);
    if (v.IsConnectedServiceActive) chips.push('Connected Car');
    if (v.IsTelematicsServiceActive) chips.push('Telematics');
    if (def.Test_Drive_Eligible__c) chips.push('Test Drive Eligible');
    if (v.ActiveWarrantyCount > 0) chips.push('Active Warranty');

    return {
      // IDs
      id: v.Id,
      // Tile classes
      tileClass: 'car-tile',
      frontClass: isHovered ? 'tile-front hidden' : 'tile-front',
      backClass: isHovered ? 'tile-back visible' : 'tile-back',
      // ── Vehicle__c fields ──────────────────────────
      modelName: v.ModelName || v.Name || 'Unnamed Model',
      modelYear: v.ModelYear || '—',
      exteriorColor: v.ExteriorColor || '—',
      status: v.Status || '—',
      showroomName: v.showroom_Name__c || '',
      licensePlate: v.LicensePlate__c || '',
      mileage: v.Mileage__c != null ? `${v.Mileage__c} km` : '—',
      ownershipType: v.Ownership_Type__c || '—',
      vin: v.VIN__c || v.VehicleIdentificationNumber || '—',
      fuelSource: fuelSrc,
      priceDisplay: priceNum,
      testDriveAvailable: !!v.Is_Test_Drive_Available__c,
      tagline:
          v.Classification || def.VehicleClass || 'Premium Electric Vehicle',
      // ── VehicleDefinition__c fields ────────────────
      variantName: def.VariantName || '',
      drivetrainSystem: def.DrivetrainSystem || '—',
      totalPower: def.TotalPower || '—',
      maxTorque: def.MaximumTorque || '—',
      topSpeed: def.TopSpeed || '—',
      batteryCapacity: def.BatteryCapacity || '—',
      batteryType: def.MainBatteryType || '—',
      rangeKm: rawRange ? `${rawRange} km` : '—',
      acceleration: def.AccelerationTime || '—',
      seats: def.Seats__c || '—',
      bodyStyle: def.Body_Style__c || def.BodyType || '—',
      imageUrl: def.Image_URL__c || '',
      hasImage: !!def.Image_URL__c,
      featureChips: chips.slice(0, 5),
      // Range bar
      rangeFillStyle: `width:${rangePct}%`,
      // SVG theme
      imgBg: theme.imgBg,
      badgeClass: theme.badgeCls,
      carBodyStyle: theme.body,
      carRoofStyle: theme.roof,
      wheelHubStyle: theme.wheelHub,
      wheelStrokeStyle: theme.wheelStr,
      headlightStyle: theme.headlight,
      taillightStyle: theme.taillight,
    };
  }

  // ── Stats bar ────────────────────────────────────────────
  get totalVehicles() {
    return this._vehicles.length;
  }

  get portalStats() {
    const available =
        this._vehicles.filter(v => v.Status === 'Available').length;
    const electric =
        this._vehicles.filter(v => v.FuelSource === 'Electric').length;
    const testDrive =
        this._vehicles.filter(v => v.Is_Test_Drive_Available__c).length;
    return [
      {value: String(this._vehicles.length), label: 'Total vehicles'},
      {value: String(available), label: 'Available now'},
      {value: String(electric), label: 'Electric models'},
      {value: String(testDrive), label: 'Test drive ready'},
    ];
  }

  // ── Event handlers ───────────────────────────────────────
  handleFilterChange(event) {
    this._activeFilter = event.target.dataset.value;
  }

  handleHoverIn(event) {
    this._hoveredId = event.currentTarget.dataset.id;
  }

  handleHoverOut() {
    this._hoveredId = null;
  }

  handleBookNow(event) {
    const {id, model} = event.target.dataset;
    this.dispatchEvent(new ShowToastEvent({
      title: 'Booking Initiated',
      message: `Your booking request for ${model} has been received.`,
      variant: 'success'
    }));
    // Navigate to a Case / Opportunity creation page
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {objectApiName: 'Case', actionName: 'new'},
      state: {
        defaultFieldValues:
            `Vehicle__c=${id},Subject=Booking Request - ${model}`
      }
    });
  }

  handleTestDrive(event) {
    const {id, model} = event.target.dataset;
    this.dispatchEvent(new ShowToastEvent({
      title: 'Test Drive Requested',
      message: `Test drive request for ${model} submitted!`,
      variant: 'success'
    }));
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {objectApiName: 'Case', actionName: 'new'},
      state: {
        defaultFieldValues:
            `Vehicle__c=${id},Subject=Test Drive Request - ${model}`
      }
    });
  }

  handleViewDetails(event) {
    const id = event.target.dataset.id;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes:
          {recordId: id, objectApiName: 'Vehicle__c', actionName: 'view'}
    });
  }

  handleImageError(event) {
    // Hide broken image; SVG illustration will show instead
    event.target.style.display = 'none';
    const id = event.target.dataset.id;
    const idx = this._vehicles.findIndex(v => v.Id === id);
    if (idx !== -1) {
      this._vehicles = [
        ...this._vehicles.slice(0, idx),
        {...this._vehicles[idx], Image_URL__c: null},
        ...this._vehicles.slice(idx + 1)
      ];
    }
  }
}