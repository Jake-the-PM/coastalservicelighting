import 'dart:async';
import 'package:flutter/foundation.dart';

/// Alexa Skill Service
/// 
/// This service provides integration with Amazon Alexa for voice control.
/// 
/// Implementation requires:
/// 1. AWS Lambda function to handle Alexa requests
/// 2. Alexa Skill definition in Amazon Developer Console
/// 3. Account linking (OAuth) for user authentication
/// 4. Smart Home Skill API implementation
/// 
/// The Alexa Smart Home API supports:
/// - Power control (on/off)
/// - Brightness control (percentage)
/// - Color control (HSB values)
/// - Scenes/presets (via Scene Controller)
class AlexaSkillService extends ChangeNotifier {
  bool _isLinked = false;
  String? _accessToken;
  
  bool get isLinked => _isLinked;

  /// Link Alexa account (OAuth flow)
  Future<bool> linkAccount(String authCode) async {
    try {
      // In production, exchange auth code for access token
      // This would call your backend OAuth endpoint
      await Future.delayed(const Duration(seconds: 1));
      _accessToken = 'mock_access_token';
      _isLinked = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Alexa account linking failed: $e');
      return false;
    }
  }

  /// Unlink Alexa account
  Future<void> unlinkAccount() async {
    _accessToken = null;
    _isLinked = false;
    notifyListeners();
  }

  /// Get Alexa skill invocation name
  String get invocationName => 'coastal lighting';

  /// Get example voice commands
  List<String> get exampleCommands => [
    'Alexa, turn on coastal lighting',
    'Alexa, set coastal lighting to 50 percent',
    'Alexa, set coastal lighting to blue',
    'Alexa, turn off coastal lighting',
    'Alexa, activate movie night on coastal lighting',
  ];
}

/// Alexa Lambda Handler Template
/// 
/// This is a template for the AWS Lambda function that handles Alexa requests.
/// Deploy this to AWS Lambda and configure as the endpoint for your Alexa skill.
class AlexaLambdaTemplate {
  /// Generate the Lambda function code (Node.js)
  static String generateLambdaCode() => '''
const https = require('https');

// Configuration - replace with your values
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    const namespace = event.directive.header.namespace;
    const name = event.directive.header.name;
    
    switch (namespace) {
        case 'Alexa.Discovery':
            return handleDiscovery(event);
        case 'Alexa.PowerController':
            return handlePowerControl(event);
        case 'Alexa.BrightnessController':
            return handleBrightness(event);
        case 'Alexa.ColorController':
            return handleColor(event);
        default:
            return createErrorResponse('INVALID_DIRECTIVE', 'Unsupported directive');
    }
};

async function handleDiscovery(event) {
    // Return list of WLED devices for this user
    const token = event.directive.payload.scope.token;
    const devices = await getDevicesForUser(token);
    
    return {
        "event": {
            "header": {
                "namespace": "Alexa.Discovery",
                "name": "Discover.Response",
                "payloadVersion": "3",
                "messageId": generateMessageId()
            },
            "payload": {
                "endpoints": devices.map(d => ({
                    "endpointId": d.id,
                    "manufacturerName": "Coastal Services",
                    "friendlyName": d.name,
                    "description": "Coastal Lighting WLED Controller",
                    "displayCategories": ["LIGHT"],
                    "capabilities": [
                        {
                            "type": "AlexaInterface",
                            "interface": "Alexa.PowerController",
                            "version": "3",
                            "properties": {
                                "supported": [{ "name": "powerState" }],
                                "retrievable": true
                            }
                        },
                        {
                            "type": "AlexaInterface",
                            "interface": "Alexa.BrightnessController",
                            "version": "3",
                            "properties": {
                                "supported": [{ "name": "brightness" }],
                                "retrievable": true
                            }
                        },
                        {
                            "type": "AlexaInterface",
                            "interface": "Alexa.ColorController",
                            "version": "3",
                            "properties": {
                                "supported": [{ "name": "color" }],
                                "retrievable": true
                            }
                        }
                    ]
                }))
            }
        }
    };
}

async function handlePowerControl(event) {
    const endpointId = event.directive.endpoint.endpointId;
    const name = event.directive.header.name;
    const powerState = name === 'TurnOn' ? 'ON' : 'OFF';
    
    // Send command via Supabase relay
    await sendRelayCommand(endpointId, 'setPower', powerState === 'ON');
    
    return createStateResponse(endpointId, 'Alexa.PowerController', 'powerState', powerState);
}

async function handleBrightness(event) {
    const endpointId = event.directive.endpoint.endpointId;
    const brightness = event.directive.payload.brightness;
    
    // Convert 0-100 to 0-255
    const wledBrightness = Math.round(brightness * 2.55);
    
    await sendRelayCommand(endpointId, 'setBrightness', wledBrightness);
    
    return createStateResponse(endpointId, 'Alexa.BrightnessController', 'brightness', brightness);
}

async function handleColor(event) {
    const endpointId = event.directive.endpoint.endpointId;
    const color = event.directive.payload.color;
    
    // Convert HSB to RGB
    const rgb = hsbToRgb(color.hue, color.saturation, color.brightness);
    
    await sendRelayCommand(endpointId, 'setColor', [rgb.r, rgb.g, rgb.b]);
    
    return createStateResponse(endpointId, 'Alexa.ColorController', 'color', color);
}

async function sendRelayCommand(installationId, commandType, value) {
    // Insert into Supabase relay_commands table
    const data = JSON.stringify({
        installation_id: installationId,
        command_type: commandType,
        payload: { value }
    });
    
    // Make request to Supabase
    return new Promise((resolve, reject) => {
        const url = new URL(SUPABASE_URL + '/rest/v1/relay_commands');
        const options = {
            hostname: url.hostname,
            path: url.pathname,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': SUPABASE_KEY,
                'Authorization': 'Bearer ' + SUPABASE_KEY
            }
        };
        
        const req = https.request(options, (res) => {
            res.on('data', () => {});
            res.on('end', resolve);
        });
        
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

function generateMessageId() {
    return 'msg-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
}

function createStateResponse(endpointId, namespace, name, value) {
    return {
        "event": {
            "header": {
                "namespace": "Alexa",
                "name": "Response",
                "messageId": generateMessageId(),
                "payloadVersion": "3"
            },
            "endpoint": { "endpointId": endpointId },
            "payload": {}
        },
        "context": {
            "properties": [{
                "namespace": namespace,
                "name": name,
                "value": value,
                "timeOfSample": new Date().toISOString(),
                "uncertaintyInMilliseconds": 500
            }]
        }
    };
}

function createErrorResponse(type, message) {
    return {
        "event": {
            "header": {
                "namespace": "Alexa",
                "name": "ErrorResponse",
                "messageId": generateMessageId(),
                "payloadVersion": "3"
            },
            "payload": {
                "type": type,
                "message": message
            }
        }
    };
}

function hsbToRgb(h, s, b) {
    const c = b * s;
    const x = c * (1 - Math.abs((h / 60) % 2 - 1));
    const m = b - c;
    
    let r, g, bl;
    if (h < 60) { r = c; g = x; bl = 0; }
    else if (h < 120) { r = x; g = c; bl = 0; }
    else if (h < 180) { r = 0; g = c; bl = x; }
    else if (h < 240) { r = 0; g = x; bl = c; }
    else if (h < 300) { r = x; g = 0; bl = c; }
    else { r = c; g = 0; bl = x; }
    
    return {
        r: Math.round((r + m) * 255),
        g: Math.round((g + m) * 255),
        b: Math.round((bl + m) * 255)
    };
}

async function getDevicesForUser(token) {
    // Fetch user's installations from Supabase
    // In production, validate token and get user ID
    return [
        { id: 'installation-1', name: 'Front Porch' },
        { id: 'installation-2', name: 'Backyard' }
    ];
}
''';

  /// Generate the Alexa Skill manifest
  static Map<String, dynamic> generateSkillManifest() => {
    'manifest': {
      'publishingInformation': {
        'locales': {
          'en-US': {
            'name': 'Coastal Lighting',
            'summary': 'Control your Coastal permanent lighting installation',
            'description': 'Control your WLED-powered permanent lighting with voice commands. Turn lights on and off, adjust brightness, and change colors.',
            'examplePhrases': [
              'Alexa, turn on coastal lighting',
              'Alexa, set coastal lighting to blue',
              'Alexa, dim coastal lighting to 50 percent',
            ],
            'keywords': ['lighting', 'smart home', 'wled', 'permanent lighting'],
          }
        },
        'isAvailableWorldwide': true,
        'testingInstructions': 'Link your Coastal Lighting account and discover devices.',
        'category': 'SMART_HOME',
      },
      'apis': {
        'smartHome': {
          'endpoint': {
            'uri': 'arn:aws:lambda:us-east-1:ACCOUNT_ID:function:coastal-lighting-alexa',
          },
          'protocolVersion': '3',
        }
      },
      'permissions': [
        { 'name': 'alexa::async_event:write' }
      ],
    }
  };
}

/// Alexa Setup Guide
class AlexaSetupGuide {
  static const String title = 'Alexa Integration Guide';
  
  static const List<String> requirements = [
    'Amazon Developer Account',
    'AWS Account (for Lambda)',
    'Supabase project (for relay commands)',
    'WLED controllers configured',
  ];

  static const List<String> steps = [
    '1. Create Alexa Skill in Amazon Developer Console',
    '2. Select "Smart Home" skill type',
    '3. Create AWS Lambda function with provided code',
    '4. Configure Lambda as skill endpoint',
    '5. Set up account linking (OAuth)',
    '6. Deploy and test with Alexa app',
    '7. Submit for certification (optional)',
  ];

  static const String lambdaSetup = '''
**Lambda Configuration:**
- Runtime: Node.js 18.x
- Handler: index.handler
- Timeout: 10 seconds
- Memory: 256 MB

**Environment Variables:**
- SUPABASE_URL: Your Supabase project URL
- SUPABASE_KEY: Your Supabase service key

**Permissions:**
- Add Alexa Smart Home trigger
- Configure with your Skill ID
''';
}
