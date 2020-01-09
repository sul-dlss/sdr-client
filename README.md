[![Build Status](https://travis-ci.org/sul-dlss/repository-client.svg?branch=master)](https://travis-ci.org/sul-dlss/repository-client)
[![Maintainability](https://api.codeclimate.com/v1/badges/b5c93aeca1371e8fee2e/maintainability)](https://codeclimate.com/github/sul-dlss/repository-client/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/b5c93aeca1371e8fee2e/test_coverage)](https://codeclimate.com/github/sul-dlss/repository-client/test_coverage)
(TODO: gem version badge here)

# Repository::Client

This is a CLI for interacting with the Stanford digital repository API.
The code for the repository API server is at https://github.com/sul-dlss/repository-api

## Usage

Deposit a new object:
```
sdr --service-url http://repository-api-server:3000 deposit --label 'hey there' file1.png file2.png
```
