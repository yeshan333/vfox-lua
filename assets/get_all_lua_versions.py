import json
import scrapy
from scrapy.crawler import CrawlerProcess
from packaging.version import parse, InvalidVersion

# fetch version: -> https://www.lua.org/ftp/
class LuaVersionSpider(scrapy.Spider):
    name = 'lua_site_spider'
    start_urls = ['https://www.lua.org/ftp/']

    def __init__(self, *args, **kwargs):
        super(LuaVersionSpider, self).__init__(*args, **kwargs)
        self.all_version = []

    def parse(self, response):
        headers = response.xpath('//table//th//text()').getall()
        for row in response.xpath('//table//tr')[1:]:
            item = {}
            for index, cell in enumerate(row.xpath('.//td//text()').getall()):
                if index < len(headers):
                    item[headers[index]] = cell.strip()
            self.all_version.append(item)
            yield item

    def closed(self, reason):
        with open("lua_versions.json", 'w', encoding="utf-8") as file:
            json.dump(self.all_version, file, indent=4)

def safe_version_parse(v):
    try:
        return parse(v)
    except InvalidVersion:
        return None

def get_all_version():
    version_set = set()
    with open("lua_versions.json", 'r', encoding="utf-8") as file:
        data = json.load(file)
        for item in data:
            if not item:
                continue
            if "lua-" not in item["filename"]:
                continue
            version = item["filename"].replace("lua-", "").replace(".tar.gz", "")
            version = version + "," + item["checksum (sha256)"]
            version_set.add(version)
    return version_set

if __name__ == "__main__":
    process = CrawlerProcess()
    process.crawl(LuaVersionSpider)
    process.start()
    versions = list(get_all_version())
    versions = sorted(versions, reverse=True)
    # versions = sorted((v for v in versions if safe_version_parse(v) is not None), key=safe_version_parse, reverse=True)
    print(versions)
    with open("versions.txt", 'w') as file:
        for v in versions:
            file.write(v + '\n')
    
