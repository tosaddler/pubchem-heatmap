# -*- coding: utf-8 -*-
import scrapy

class PubChemSpider(scrapy.Spider):
    name = "pubchem"
    
    def start_requests(self):
        urls = [
            'https://pubchem.ncbi.nlm.nih.gov/compound/6618',
            ]
    
        for url in urls:
                yield scrapy.Request(url=url, callback=self.parse)
    
    
    def parse(self, response):
        page = response
        filename = 'pubchem-%s.html' % page
        with open(filename, 'wb') as f:
            f.write(response.body)
        self.log('Saved file %s' % filename)