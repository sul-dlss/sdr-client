[![CircleCI](https://circleci.com/gh/sul-dlss/sdr-client.svg?style=svg)](https://circleci.com/gh/sul-dlss/sdr-client)
[![Maintainability](https://api.codeclimate.com/v1/badges/1210855d46d4f424bf30/maintainability)](https://codeclimate.com/github/sul-dlss/sdr-client/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1210855d46d4f424bf30/test_coverage)](https://codeclimate.com/github/sul-dlss/sdr-client/test_coverage)
[![Gem Version](https://badge.fury.io/rb/sdr-client.svg)](https://badge.fury.io/rb/sdr-client)

# Sdr::Client

This is a CLI for interacting with the Stanford Digital Repository API.
The code for the SDR API server is at https://github.com/sul-dlss/sdr-api

This provides a way for consumers to easily and correctly deposit files to the SDR without requiring access to the `/dor` NFS mount or to use Hydrus.  A primary design goal was for this to have as few dependencies as possible so that it can be easily distributed by `gem install sdr-client` and then it can be used as a CLI.

## Install

`gem install sdr-client`

## Usage

Log in:
```
sdr --service-url http://sdr-api-server:3000 login
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
