# Repository::Client

This is a CLI for interacting with the Stanford digital repository API.
The code for the repository API server is at https://github.com/sul-dlss/repository-api

## Usage

Deposit a new object:
```
sdr --service-url http://repository-api-server:3000 deposit --label 'hey there' file1.png file2.png
```
