Yes, it is possible to authenticate with Google's OAuth 2.0 without manually opening a browser, but it depends on the flow you use. The flow you're currently using is the **Authorization Code Flow**, which is designed for user interaction (browser-based). To automate this process, you would typically use **Service Accounts** or an automated OAuth flow designed for backend systems that don't require user interaction.

Here are a few approaches you can take:

### 1. **Using Service Accounts** (Recommended for Server-to-Server Communication)
If your application interacts with Google APIs on behalf of itself rather than individual users, you can use a **Service Account** instead of OAuth 2.0 Authorization Code Flow. Service accounts are ideal for server-to-server communication where no user authorization is needed.

#### Steps:
1. **Create a Service Account**:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/).
   - Create a new **Service Account** under your project.
   - Download the service account key (JSON file).

2. **Grant Permissions**:
   - Share the relevant Google Sheet with the service account's email address (found in the JSON file), giving it access to read or edit the sheet.

3. **Authenticate Using the Service Account**:
   Modify your authorization logic to use the service account credentials:

   ```ruby
   require 'googleauth'
   require 'googleauth/stores/file_token_store'
   require 'google/apis/sheets_v4'

   class GoogleSheetsApi
     SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

     def initialize
       @service = Google::Apis::SheetsV4::SheetsService.new
       @service.client_options.application_name = APPLICATION_NAME
       @service.authorization = authorize
     end

     def authorize
       # Load the service account credentials
       key_file = 'path/to/service-account-file.json' # Replace with the path to your service account key file
       authorizer = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.open(key_file), scope: SCOPE)
       authorizer.fetch_access_token!
       authorizer
     end
   end
   ```

In this method, no manual browser interaction is required, and your server will authenticate automatically using the service account credentials.

### 2. **Headless OAuth Authorization (Programmatic Authorization)**:
If you must continue using user-specific access, you can try setting up a headless authentication flow where you programmatically obtain the authorization code and exchange it for tokens. However, Google’s OAuth 2.0 flow is primarily designed for user interaction.

To simulate "headless" OAuth, you would need to:
- Programmatically open a browser session (e.g., using a library like `Selenium` or `Puppeteer`) and automatically retrieve the authorization code.
- This approach is generally discouraged and considered brittle.

### 3. **Using `gcloud` CLI for Programmatic Authentication**:
If you're running the application in a controlled environment (like CI/CD or a server where `gcloud` is available), you can authenticate via the Google Cloud SDK:

```bash
gcloud auth application-default login
```

This will authenticate your environment and allow you to interact with Google APIs without requiring browser-based OAuth flows in your application.

You can then modify your authorization logic like this:

```ruby
def authorize
  authorizer = Google::Auth.get_application_default([SCOPE])
  authorizer.fetch_access_token!
  authorizer
end
```

### Conclusion:
For most cases involving server-to-server communication (like interacting with Google Sheets from a backend application), using a **Service Account** is the best solution because it avoids the need for manual user interaction. It’s secure and streamlined for automated processes. 

If your application needs to act on behalf of specific users and cannot use service accounts, then browser-based OAuth flows are necessary, though they can be difficult to automate fully.
