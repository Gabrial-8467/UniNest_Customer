# Backend Connection Testing Example

This guide shows how to use the enhanced connection testing in your Flutter app.

## Basic Usage

```dart
// Test backend connection
final isConnected = await AppStateScope.of(context).testBackendConnection();

if (isConnected) {
  // Backend is connected - proceed with app functionality
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Connected to backend successfully')),
  );
} else {
  // Backend not connected - show error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Connection failed. Please check your internet connection.'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Advanced Usage with Status Monitoring

```dart
// Monitor connection status
AnimatedBuilder(
  animation: AppStateScope.of(context),
  builder: (context, appState) {
    return Column(
      children: [
        if (appState.hasConnectionError)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appState.errorMessage,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else if (!appState.isConnectionTested)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 8),
                Text('Testing connection...', style: TextStyle(color: Colors.white)),
              ],
            ),
          )
        else if (appState.isBackendConnected)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backend connected',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  },
)
```

## Connection Status Properties

The `AppState` now provides these getters for monitoring connection status:

- `isBackendConnected`: Returns `true` if backend is connected
- `hasConnectionError`: Returns `true` if there's a connection error
- `isConnectionTested`: Returns `true` if connection test has been performed
- `errorMessage`: Contains the current error message

## Automatic Connection Testing

The app automatically tests the connection on startup. You can also manually trigger tests:

```dart
// Manual connection test
await AppStateScope.of(context).testBackendConnection();

// Refresh connection status
AppStateScope.of(context).notifyListeners();
```

## Error Handling

The connection testing includes comprehensive error handling:

1. **Network Errors**: Shows user-friendly error messages
2. **Server Errors**: Handles API response failures
3. **Timeout**: Catches connection timeouts
4. **Offline Mode**: Graceful fallback when no internet

## Integration with Customer API

The connection testing uses these API endpoints:
- `GET /health` - Public health check
- `GET /api/customer/health` - Customer-specific health check

Both endpoints are tested to ensure full backend connectivity.
