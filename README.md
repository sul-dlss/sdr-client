[![Build Status](https://travis-ci.org/sul-dlss/sdr-client.svg?branch=master)](https://travis-ci.org/sul-dlss/sdr-client)
[![Maintainability](https://api.codeclimate.com/v1/badges/1210855d46d4f424bf30/maintainability)](https://codeclimate.com/github/sul-dlss/sdr-client/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1210855d46d4f424bf30/test_coverage)](https://codeclimate.com/github/sul-dlss/sdr-client/test_coverage)
[![Gem Version](https://badge.fury.io/rb/sdr-client.svg)](https://badge.fury.io/rb/sdr-client)

# Sdr::Client

This is a CLI for interacting with the Stanford Digital Repository API.
The code for the SDR API server is at https://github.com/sul-dlss/sdr-api

## Install

`gem install sdr-client`

## Usage

Log in:
```
sdr --service-url http://sdr-api-server:3000 login
```


Deposit a new object:
```
sdr --service-url https://sdr-api-server:3000 deposit --label 'hey there' \
  --admin-policy 'druid:bk123gh4567' \
  --collection 'druid:gh456kw9876' \
  --source-id 'googlebooks:stanford_12345' file1.png file2.png
```
