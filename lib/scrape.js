var page = require('webpage').create();
        page.open('https://pubchem.ncbi.nlm.nih.gov/compound/6618', function () {
            console.log(page.content);
            phantom.exit();
        });
