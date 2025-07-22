# CI Testing with WAHA Integration

This document explains how the test suite handles WAHA (WhatsApp HTTP API) integration in CI environments where WAHA is not available.

## Overview

WAHA requires a real phone with WhatsApp to function, which is not possible in CI environments like GitHub Actions. Therefore, all tests that interact with WAHA must be properly stubbed to simulate the API responses.

## Test Strategy

### 1. WebMock Stubbing

All WAHA API calls are stubbed using WebMock to prevent real HTTP requests:

```ruby
# Example: Stubbing WAHA session creation
stub_request(:post, "http://waha:3000/api/sessions")
  .to_return(status: 200, body: {}.to_json)

# Example: Stubbing message sending
stub_request(:post, "http://waha:3000/api/sendText")
  .to_return(status: 200, body: { success: true }.to_json)
```

### 2. Error Handling Tests

Tests verify that the application handles WAHA unavailability gracefully:

- Network timeouts
- Service unavailability (503 errors)
- Malformed responses
- Connection failures

### 3. Single Session Constraint

The application enforces that only one WAHA session is allowed, named "default":

```ruby
# Model validation
validates :name, presence: true, uniqueness: true, inclusion: { in: ["default"] }
```

## Test Files

### Core WAHA Tests

- `test/lib/waha_client_test.rb` - Tests the WAHA client library
- `test/lib/waha_client_ci_test.rb` - Tests CI-specific scenarios
- `test/controllers/waha_sessions_controller_test.rb` - Tests session management
- `test/controllers/messages_controller_test.rb` - Tests message sending
- `test/controllers/waha_webhooks_controller_test.rb` - Tests webhook handling

### Integration Tests

- `test/integration/waha_integration_ci_test.rb` - Tests application behavior when WAHA is unavailable
- `test/models/chat_test.rb` - Tests chat synchronization with WAHA

## CI Environment Configuration

### Test Environment Settings

```ruby
# config/environments/test.rb
config.assets.unknown_asset_fallback = true
config.assets.compile = true
```

### WebMock Configuration

All tests that make HTTP requests include:

```ruby
require "webmock/minitest"
```

## Running Tests

### Local Development

```bash
# Run all tests
docker compose exec store bin/rails test

# Run specific test file
docker compose exec store bin/rails test test/controllers/waha_sessions_controller_test.rb

# Run with verbose output
docker compose exec store bin/rails test -v
```

### CI Environment

The same test commands work in CI, but WAHA will be unavailable, so all tests must use stubs.

## Common Issues

### 1. Real HTTP Requests in Tests

If you see `WebMock::NetConnectNotAllowedError`, it means a test is trying to make a real HTTP request. Add appropriate stubs:

```ruby
stub_request(:any, /http:\/\/waha:3000\/.*/)
  .to_return(status: 200, body: {}.to_json)
```

### 2. Asset Pipeline Warnings

If you see deprecation warnings about missing assets, ensure the test environment has:

```ruby
config.assets.unknown_asset_fallback = true
config.assets.compile = true
```

### 3. Session Name Conflicts

All tests must use "default" as the session name to comply with the single session constraint.

## Best Practices

1. **Always stub WAHA calls** - Never let tests make real HTTP requests
2. **Test error scenarios** - Verify graceful handling of WAHA failures
3. **Use unique test data** - Avoid conflicts between tests
4. **Clean up test data** - Use `setup` blocks to ensure clean state
5. **Test both success and failure paths** - Ensure robust error handling

## Adding New WAHA Tests

When adding new tests that interact with WAHA:

1. Include `require "webmock/minitest"`
2. Add appropriate stubs in the `setup` block
3. Test both success and failure scenarios
4. Use "default" as the session name
5. Clean up test data in `setup`
