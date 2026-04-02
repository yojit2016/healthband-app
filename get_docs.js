const https = require('https');
const fs = require('fs');

https.get('https://health-band-server.vercel.app/api/docs/swagger-ui-init.js', (res) => {
    let data = '';
    res.on('data', chunk => { data += chunk; });
    res.on('end', () => {
        // extract the swaggerDoc object
        const match = data.match(/var options = ({.*});/s);
        if (match) {
            try {
                // Not standard JSON, might need eval
                const options = eval('(' + match[1] + ')');
                fs.writeFileSync('docs.json', JSON.stringify(options.swaggerDoc.paths, null, 2));
                console.log("Wrote docs.json");
            } catch (e) {
                console.log("Parse error doc", e);
            }
        } else {
            console.log("No match found");
        }
    });
}).on('error', err => {
    console.log('Error: ', err.message);
});
