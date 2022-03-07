[![CircleCI](https://circleci.com/gh/sul-dlss/sdr-client.svg?style=svg)](https://circleci.com/gh/sul-dlss/sdr-client)
[![Maintainability](https://api.codeclimate.com/v1/badges/1210855d46d4f424bf30/maintainability)](https://codeclimate.com/github/sul-dlss/sdr-client/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1210855d46d4f424bf30/test_coverage)](https://codeclimate.com/github/sul-dlss/sdr-client/test_coverage)
[![Gem Version](https://badge.fury.io/rb/sdr-client.svg)](https://badge.fury.io/rb/sdr-client)

# Sdr::Client

This is a Ruby-based CLI for interacting with the Stanford Digital Repository API. The code for the SDR API server is at https://github.com/sul-dlss/sdr-api

This provides a way for consumers to easily and correctly deposit files to the SDR without requiring access to the `/dor` NFS mount or to use Hydrus.  A primary design goal was for this to have as few dependencies as possible so that it can be easily distributed by `gem install sdr-client` and then it can be used as a CLI.

## Install

We recommend using the latest 3.x release of Ruby.

`gem install sdr-client`

## Usage

Log in:
```
sdr --service-url https://sdr-api-server:3000 login
```

Register a new object:
```
sdr --service-url https://sdr-api-server:3000 register --label 'hey there' \
  --admin-policy 'druid:bk123gh4567' \
  --collection 'druid:gh456kw9876' \
  --source-id 'googlebooks:stanford_12345' file1.png file2.png
```

Deposit (register + accession) a new object:
```
sdr --service-url https://sdr-api-server:3000 deposit --label 'hey there' \
  --admin-policy 'druid:bk123gh4567' \
  --collection 'druid:gh456kw9876' \
  --source-id 'googlebooks:stanford_12345' file1.png file2.png
```

Deposit a new object, providing metadata for files:
```
sdr --service-url https://sdr-api-server:3000 deposit --label 'hey there' \
  --files-metadata '{"image42.jp2":{"mime_type":"image/jp2"},"ocr.html":{"use":"transcription"}}'
  --admin-policy 'druid:bk123gh4567' \
  --collection 'druid:gh456kw9876' \
  --source-id 'googlebooks:stanford_12345' image42.jp2 ocr.html
```

View the object:
```
sdr --service-url https://sdr-api-server:3000 get druid:bw581ng3176
{"type":"http://cocina.sul.stanford.edu/models/document.jsonld","externalIdentifier":"druid:bw581ng3176","label":"Something something better title","version":1,"access":{"access":"stanford","copyright":"This work is copyrighted by the creator.","download":"stanford","useAndReproductionStatement":"This document is available only to the Stanford faculty, staff and student community."},"administrative":{"hasAdminPolicy":"druid:zx485kb6348"},"description":{"title":[{"value":"Something something better title"}],"contributor":[{"name":[{"value":"Hodge, Amy"}],"type":"person","role":[{"value":"Author"},{"value":"author","uri":"http://id.loc.gov/vocabulary/relators/aut","source":{"code":"marcrelator","uri":"http://id.loc.gov/vocabulary/relators/"}},{"value":"Creator"}]}],"form":[{"structuredValue":[{"value":"Text","type":"type"},{"value":"Report","type":"subtype"}],"type":"resource type","source":{"value":"Stanford self-deposit resource types"}},{"value":"reports","type":"genre","uri":"http://vocab.getty.edu/aat/300027267","source":{"code":"aat"}},{"value":"text","type":"resource type","source":{"value":"MODS resource types"}}],"note":[{"value":";alkdfjlsadkjf;l","type":"summary"},{"value":"amyhodge@stanford.edu","type":"contact","displayLabel":"Contact"}],"subject":[{"value":"lkfj","type":"topic"},{"value":";kfj","type":"topic"},{"value":"fjwelkb","type":"topic"}]},"identification":{"sourceId":"hydrus:20"},"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/resources/file.jsonld","externalIdentifier":"bw581ng3176_1","label":"Test file","version":1,"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/file.jsonld","externalIdentifier":"druid:bw581ng3176/test.txt","label":"test.txt","filename":"test.txt","size":11,"version":1,"hasMimeType":"text/plain","hasMessageDigests":[{"type":"sha1","digest":"5d39343e4bb48abd97f759828282f5ebbac56c5e"},{"type":"md5","digest":"63b8812b0c05722a9d6c51cbd2bfb54b"}],"access":{"access":"world","download":"world"},"administrative":{"sdrPreserve":true,"shelve":true}}]}}]}}
```

Display version of sdr-client:
```
sdr version
```

## Testing

To test running sdr-client against the SDR API, which itself has dependencies on other SDR services, we tend to test against our running SDR QA environment. Make sure you are connected to VPN throughout your testing and provide `https://sdr-api-qa.stanford.edu` as the service URL when issuing CLI commands.
