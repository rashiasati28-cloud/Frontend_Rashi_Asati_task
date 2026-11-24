// Map of threat codes to human-readable threat names
const Map<String, String> threatNameMap = {
  'ROOT_DETECTED': 'Rooted device',
  'JAILBREAK_DETECTED': 'Jailbroken iPhone',
  'HOOKING_FRAMEWORK': 'Hooking tool (like Frida)',
  'SCREEN_OVERLAY': 'Screen overlay',
  'APP_TAMPERED': 'App was modified',
  'EMULATOR': 'Running on an emulator',
  'DEBUGGER_ATTACHED': 'Debugger attached',
};

// Helper function to get display name for a threat code
// If the code is not in the map, return the raw code as is
String threatName(String? code) {
  if (code == null || code.trim().isEmpty) {
    return 'Unknown threat';
  }
  return threatNameMap[code] ?? code;
}
