## [1.1.0] - 2025-06-17

### ⚙️ Added
- `.dockerignore` to exclude common build artifacts from Docker context.
- `entrypoint.sh` support in `Dockerfile.dev`.
- New development gems: `ruby-lsp`, `timecop`.

### 🔼 Changed
- Upgraded Ruby version from `3.3.5` to `3.4.4`.
- Upgraded Rails from `7.1.4` to `7.1.5.1`.
- Bumped numerous gem dependencies including `faker`, `dotenv`, `rspec`, `rubocop`, `redis`, and more.
- Refactored `Guardfile` with modular, DRY config blocks.
- Simplified `OauthSessionsController` method definitions.
- Improved `BuyItNowBot` retry logic with configurable attempt rate.
- Enhanced SOAP XML parsing logic across `BuyItNowBot` and `GodaddyApi`.

### 🧹 Removed
- Obsolete Slack integration methods from `ApplicationController`.
- `app/helpers/godaddy_helper.rb`.

### 🐛 Fixed
- Incorrect treatment of nil authorization status in `User#authorize_user`.
- Strong parameter handling in `GodaddyController`.

### 🧪 Dev & CI
- Disabled RuboCop auto-correction in `.rubocop.yml` for safety.
- Enabled `rubocop-rspec` and custom cops.
- Added validation logic for `entrypoint.sh` presence/executability.

