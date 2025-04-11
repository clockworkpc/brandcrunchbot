# BrandCrunchBot Workflow

## Client and Service Provider

BrandCrunch, owned and operated by Markus Nystrom is the Client.

Garber Squared, owned and operated by Alexander Garber, is the Service Provider, herein referred to as G².

All instructions for the application, logs of the application's actions, credentials, and any other sensitive or application-specific data, are to be the exclusive property of the Client.

All code and written material of a general nature, which does not disclose particular or identifiable information about the Client or the Client's activities, is to be the exclusive property of the Service Provider and may be re-used in other business applications.

## Components

The BrandCrunchBot solution is composed of the following:

1. Google Sheet containing the following tabs:
    1. `domains` tab for listing desired domain names, proxy bids, and BIN prices.
    1. `domains_test` tab for dummy records thereof.
    2. `logs` tab for recording actions by the BrandCrunchBot server and Worker dyno.
    2. `logs_test` for recording actions vis-a-vis the dummy records in `domains_test`.
2. BrandCrunchBot Rails application hosted on Heroku, comprising the following:
    1. Rails server
    2. Static user interface
    3. PostgresQL database
    4. DelayedJob Scheduler
3. GoDaddy Auction API, utilising the following SOAP endpoints:
    1. `AuctionDetails`
    2. `PlaceBidOrPurchase`

<div style="page-break-after: always;"></div>

### Rails Application

The BrandCrunchBot is to be a Ruby on Rails application of the following nature:
- Deployed to Heroku
- Static, server-dependent User Interface
- PostgresQL database on Heroku.
- Redis database for OAuth token storage as part of the Google API authentication.
- `DelayedJob` Rails gem for scheduling Jobs.
- Sensitive credentials in a native Rails encrypted YAML.
- The key to the encrypted YAML as a system variable on the developer machine.
- The key to the encrypted YAML as a Heroku variable which is made available to the deployed application.
- Procfile defining the following:
  - Web Dyno for the server
  - Worker Dyno for the scheduled Jobs

<div style="page-break-after: always;"></div>

### Google Sheet

BrandCrunch is to create a Google Sheet and give Editing access to the nominated G² account.
The Google Sheet in question until further notice is [BrandCrunch API]( https://docs.google.com/spreadsheets/d/1VVKoz1xM3NITzIRdRvB5l-Qp4_9updmot0Ry4yxKDC8 ),
sheet ID `1VVKoz1xM3NITzIRdRvB5l-Qp4_9updmot0Ry4yxKDC8`.

### Google Sheets API

1. In order to give the BrandCrunchBot application access to the aforementioned Google Sheet, BrandCrunch is to create an OAuth token and provide the credentials JSON.
2. G² is to store the requisite OAuth token credentials in an encrypted YAML file on the Rails server, which will be added to version control on Git.
3. G² is to store the key to the encrypted credentials in such a manner so as not to be accessible from within the hosted server.

NOTE: At the time of writing, the OAuth credentials are provided by the Google account of G².

### GoDaddy Auction API

1. BrandCrunch is to provide G² the following API credentials for access to the GoDaddy Auction API:
  a. `OTE` for testing
  b. `Prod` for production

2. G² is to store the requisite OAuth token credentials in an encrypted YAML file on the Rails server, which will be added to version control on Git.
3. G² is to store the key to the encrypted credentials in such a manner so as not to be accessible from within the hosted server.

It is noted that in the case of the `InstantPurchaseCloseoutDomain` endpoint, a successful SOAP request even with the OTE credentials results in adding a domain to the Client's cart.

<div style="page-break-after: always;"></div>

## Synchronous Actions


### Singular Actions

| Component/Sender | Action              | Recipient         | Mechanism         | Description                              |
|------------------|---------------------|-------------------|-------------------|------------------------------------------|
| User             | Click "Import Jobs" | UI                | Browser           |                                          |
| UI               | POST Request        | Server            | Browser           | sends form to Controller                 |
| Server           | Notification        | GSheets::`logs`   | Google Sheets API | "Importing jobs..."                      |
| Server           | GET Request         | GSheet::`domains` | Google Sheets API | requests listed domain names             |
| Server           | Notification        | GSheets::`logs`   | Google Sheets API | "Requesting domains and instructions..." |
| Google Sheet     | GET Response        | Server            | Google Sheets API | returns listed domains as an array       |
| Server           | Notification        | GSheets::`logs`   | Google Sheets API | "Received domains and instructions."     |

<div style="page-break-after: always;"></div>

### Bloc Actions

#### Google Sheets Response

For each spreadsheet row represented by a nested array in the Google Sheets response, which contains a domain name and instructions, the following actions apply:

| Component/Sender | Action        | Recipient               | Mechanism         | Description                                                   |
|------------------|---------------|-------------------------|-------------------|---------------------------------------------------------------|
| Server           | DB Update     | PostgresQL database     | ActiveRecord      | find or create record                                         |
| Server           | Notification  | GSheets::`logs`         | Google Sheets API | "Saving {DOMAIN_NAME} to DB..."                               |
| Server           | SOAP Request  | AuctionDetails endpoint | GoDaddy API       | request Auction details                                       |
| Server           | Notification  | GSheets::`logs`         | Google Sheets API | "Requesting Auction details for {DOMAIN_NAME}"                |
| AuctionDetails   | SOAP Response | Server                  | GoDaddy API       | return Auction details in response body                       |
| Server           | Parse body    | N/A                     | Ruby `regex`      | For each SOAP response, parse body to extract Auction details |

<div style="page-break-after: always;"></div>

#### GoDaddy API Response

For each parsed SOAP response, the following actions apply:

| Component/Sender | Action        | Recipient           | Mechanism            | Description                                        |
|------------------|---------------|---------------------|----------------------|----------------------------------------------------|
| Server           | DB Update     | PostgresQL database | ActiveRecord         | save extracted Auction details to DB record        |
| Server           | Notification  | GSheets::`logs`     | Google Sheets API    | "Auction for {DOMAIN_NAME} ends at {DATETIME}..."  |
| Server           | Schedule Jobs | Job Scheduler       | Rails Delay Jobs Gem | schedule a Job to bid, purchase, or refrain        |
| Server           | Notification  | GSheets::`logs`     | Google Sheets API    | "Job for {DOMAIN_NAME} scheduled at {DATETIME}..." |

## Asynchronous Actions

For each Auction, the Job scheduler launches a Worker dyno, which pings the GoDaddy `AuctionDetails` endpoint at the appointed time and, depending on the retrieved details and instructions, is to perform one of the following:
* place a **proxy bid**
* add to cart at a given **Buy It Now** price
* or refrain from further action.

In all cases, the Worker dyno will append the particulars of the Job to the `logs` tab in the Google Sheet.

### Live Auction

| Proxy Bid in instructions? | Live Bid placed? | Comparison            | Action                                |
|----------------------------|------------------|-----------------------|---------------------------------------|
| TRUE                       | TRUE             | Proxy Bid <= Live Bid | Refrain                               |
| TRUE                       | TRUE             | Proxy Bid > Live Bid  | Execute Proxy Bid When 3 minutes left |
| TRUE                       | FALSE            | N/A                   | Refrain                               |

NOTE: Future Feature Request: place proxy bid for a specified domain even if no Live Bid placed.

### Buy It Now

| BIN price in instructions | Available in BIN Auction? | Comparison                              | Action      |
|---------------------------|---------------------------|-----------------------------------------|-------------|
| TRUE                      | TRUE                      | Target BIN price > Available BIN price  | Refrain     |
| TRUE                      | TRUE                      | Target BIN price <= Available BIN price | Add to cart |
| FALSE                     | TRUE                      | N/A                                     | Refrain     |
| TRUE                      | FALSE                     | N/A                                     | N/A         |

NOTE: Ascertain whether the Bot can effect the purchase and not just add to cart.


1. Wait for screen "Will be available BUY IT NOW shortly"
2. Tap Buy It Now button for any number of minutes

- Where 'Price' == "$1", initial (automatic) bid
- Try CURL request instead of API call for $50 auctions?