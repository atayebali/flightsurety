import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error, result);
            display('Operational Status', '', [{ label: 'Operational Status', error: error, value: result }]);
        });

        DOM.elid('register-airline').addEventListener('click', () => {
            let airline = DOM.elid('airline-address').value;
            if (airline) {
                contract.registerAirline(airline);
            }
        });

        DOM.elid('fund-airline').addEventListener('click', () => {
            let amount = DOM.elid('funding-amount').value;
            contract.fund(amount);
        });

        DOM.elid('register-flight').addEventListener('click', async () => {
            let flightNumber = DOM.elid('flight-number').value;
            let departureLocation = DOM.elid('departure-location').value;
            let arrivalLocation = DOM.elid('arrival-location').value;
            contract.registerFlight(flightNumber);
        });


        DOM.elid('pay').addEventListener('click', () => {
            contract.pay((error, result) => {
                if (error) {
                    console.log(error)
                } else {
                    console.log(result);
                }
            });
        });
    });
})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
        row.appendChild(DOM.div({ className: 'col-sm-8 field-value' }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







