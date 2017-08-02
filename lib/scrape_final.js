var webPage = require('webpage');
var page = webPage.create();

var fs = require('fs');
var path = 'temp/scrape.html'

page.open('https://www.pubchem.ncbi.nlm.nih.gov/compound/6618', function (status) {
  var content = page.content;
  fs.write(path,content,'w')
  phantom.exit();
});
