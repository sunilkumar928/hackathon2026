import getVehicleModels from '@salesforce/apex/ElectraShowcaseController.getVehicleModels';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {LightningElement, track, wire} from 'lwc';

const CAR_SVG_MAP = {
  Electra_Apex: `
        <svg viewBox="0 0 200 70" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <ellipse cx="45" cy="58" rx="13" ry="13" fill="#1a1a1a" stroke="#C9A84C" stroke-width="1.5"/>
            <ellipse cx="155" cy="58" rx="13" ry="13" fill="#1a1a1a" stroke="#C9A84C" stroke-width="1.5"/>
            <ellipse cx="45" cy="58" rx="5" ry="5" fill="#C9A84C"/>
            <ellipse cx="155" cy="58" rx="5" ry="5" fill="#C9A84C"/>
            <rect x="22" y="38" width="156" height="22" rx="3" fill="#2a2620"/>
            <path d="M55 38 Q75 16 110 14 Q145 14 170 38" fill="#1f1c13" stroke="#C9A84C" stroke-width="0.7"/>
            <rect x="120" y="18" width="32" height="9" rx="1" fill="#2a5a9a" opacity="0.7"/>
            <rect x="82" y="17" width="33" height="10" rx="1" fill="#2a5a9a" opacity="0.7"/>
            <rect x="22" y="43" width="28" height="8" rx="2" fill="#333"/>
            <rect x="150" y="43" width="28" height="8" rx="2" fill="#C9A84C" opacity="0.8"/>
        </svg>`,
  Electra_Nova: `
        <svg viewBox="0 0 200 70" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <ellipse cx="42" cy="58" rx="12" ry="12" fill="#1a1a1a" stroke="#C9A84C" stroke-width="1.5"/>
            <ellipse cx="158" cy="58" rx="12" ry="12" fill="#1a1a1a" stroke="#C9A84C" stroke-width="1.5"/>
            <ellipse cx="42" cy="58" rx="4.5" ry="4.5" fill="#C9A84C"/>
            <ellipse cx="158" cy="58" rx="4.5" ry="4.5" fill="#C9A84C"/>
            <rect x="18" y="40" width="164" height="20" rx="3" fill="#252220"/>
            <path d="M48 40 Q68 20 105 18 Q140 18 162 40" fill="#1c1a14" stroke="#aaa" stroke-width="0.7"/>
            <rect x="118" y="22" width="30" height="8" rx="1" fill="#2a5a9a" opacity="0.6"/>
            <rect x="82" y="21" width="32" height="9" rx="1" fill="#2a5a9a" opacity="0.6"/>
        </svg>`,
  Electra_Zenith: `
        <svg viewBox="0 0 200 70" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <ellipse cx="42" cy="57" rx="14" ry="14" fill="#1a1a1a" stroke="#C9A84C" stroke-width="1.5"/>
            <ellipse cx="158" cy="57" rx="14" ry="14" fill="#1a1a1a" stroke="#C9A84C" stroke-width="1.5"/>
            <ellipse cx="42" cy="57" rx="5.5" ry="5.5" fill="#C9A84C"/>
            <ellipse cx="158" cy="57" rx="5.5" ry="5.5" fill="#C9A84C"/>
            <rect x="14" y="34" width="172" height="25" rx="4" fill="#232018"/>
            <path d="M38 34 Q62 10 100 8 Q138 8 164 34" fill="#1c1a10" stroke="#888" stroke-
width="0.7"/>
            <rect x="115" y="13" width="34" height="10" rx="1" fill="#2a5a9a" opacity="0.65"/>
            <rect x="74" y="12" width="37" height="11" rx="1" fill="#2a5a9a" opacity="0.65"/>
            <rect x="14" y="34" width="26" height="10" rx="2" fill="#2a2a2a"/>
            <rect x="160" y="34" width="26" height="10" rx="2" fill="#2a2a2a"/>
        </svg>`
};

export default class ElectraShowcase extends NavigationMixin
(LightningElement) {
  @track vehicles = [];
  @track selectedCar = null;
  @track isLoading = true;
  @track hasError = false;

  @wire(getVehicleModels)
  wiredModels({error, data}) {
    this.isLoading = false;
    console.log('DATA :: ' + JSON.stringify(data));
    if (data) {
      this.vehicles =
          data.map((car, index) => ({
                     ...car,
                     isSelected: index === 0,
                     cardClass: index === 0 ? 'ec-card selected' : 'ec-card'
                   }));
      if (this.vehicles.length > 0) {
        this.selectedCar = this.vehicles[0];
      }
      this._injectSvgs();
    } else if (error) {
      this.hasError = true;
      console.error('ElectraShowcase wire error:', JSON.stringify(error));
    }
  }

  get isReady() {
    return !this.isLoading && !this.hasError;
  }

  handleCardClick(event) {
    const devName = event.currentTarget.dataset.devname;
    this.vehicles = this.vehicles.map(
        car => ({
          ...car,
          isSelected: car.developerName === devName,
          cardClass: car.developerName === devName ? 'ec-card selected' :
                                                     'ec-card'
        }));
    this.selectedCar =
        this.vehicles.find(car => car.developerName === devName) || null;
  }

  handleBookTestDrive() {
    const modelName = this.selectedCar ? this.selectedCar.label : '';
    this.dispatchEvent(new CustomEvent(
        'booktestdrive', {detail: {modelName}, bubbles: true, composed: true}));
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {url: '/test-drive?model=' + encodeURIComponent(modelName)}
    });
  }

  handleFinanceOptions() {
    const modelName = this.selectedCar ? this.selectedCar.label : '';
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {url: '/finance?model=' + encodeURIComponent(modelName)}
    });
  }

  handleCallSupport() {
    this.dispatchEvent(new ShowToastEvent({
      title: 'Customer Support',
      message: 'Calling 1800 102 8800 — Mon–Sat, 8 AM to 8 PM IST',
      variant: 'info'
    }));
  }

  handleLiveChat() {
    this.dispatchEvent(
        new CustomEvent('openchat', {bubbles: true, composed: true}));
  }

  _injectSvgs() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    requestAnimationFrame(() => {
      this.template.querySelectorAll('[data-svg]').forEach(container => {
        const key = container.dataset.svg;
        if (CAR_SVG_MAP[key] && container.innerHTML === '') {
          container.innerHTML = CAR_SVG_MAP[key];
        }
      });
    });
  }

  renderedCallback() {
    this._injectSvgs();
  }
}