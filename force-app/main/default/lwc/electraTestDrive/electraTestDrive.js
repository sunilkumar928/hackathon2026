import { LightningElement } from 'lwc';

export default class ElectraTestDrive extends LightningElement {
    // These are direct links to high-quality car images
   carModels = [
        {
            id: '1',
            name: 'ELECTRA PHANTOM',
            image: 'https://images.pexels.com/photos/3729464/pexels-photo-3729464.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            tagline: 'The silent predator.'
        },
        {
            id: '2',
            name: 'ELECTRA NEON',
            image: 'https://images.pexels.com/photos/3311574/pexels-photo-3311574.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
            tagline: 'Electric energy, refined.'
        }
    ];

    handleAgentOpen() {
        // Custom event for Agentforce/Messaging
        window.dispatchEvent(new CustomEvent('onOpenChat'));
    }
}