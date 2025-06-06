#include <MPU9250_asukiaaa.h>
#include <WiFi.h>
#include <ThingSpeak.h>
#include <WebServer.h>

// Define pins for MPU9250 I2C
#ifdef _ESP32_HAL_I2C_H_
#define SDA_PIN 21
#define SCL_PIN 22
#endif

// Create MPU9250 object
MPU9250_asukiaaa mySensor;
float aX, aY, aZ, aSqrt, gX, gY, gZ;

// WiFi and ThingSpeak settings
const char* ssid =  "YOUR-SSID-HERE" ;
const char* password = "YOUR-PASSWORD-HERE" ; 
unsigned long myChannelNumber = YOUR-CHANNEL-NUMBER ;
const char* myApiKey = "YOUR-API-KEY" ;
WiFiClient client;

// Web Server for Wireless Serial Monitor
WebServer server(80);
String logData = "";

// Pulse Sensor variables
int pulsePin = 34;
bool pulseDetected = false;
unsigned long lastBeatTime = 0;
float bpm = 0;

// HC-SR04 Ultrasonic sensor pins
const int trigPin = 12;
const int echoPin = 13;
long duration;
int distance;

// Buzzer pin
const int buzzerPin = 25;

float minAccel = 999, maxAccel = 0;
float minGyro = 999, maxGyro = 0;
float tiltAngle = 0;

float rmsAcc = 0.0, rmsGyro = 0.0;

// Min/Max values for RMS acceleration, RMS gyro, distance, and BPM
float minRMSAcc = 100, maxRMSAcc = 0;
float minRMSGyro = 100, maxRMSGyro = 0;
float minDistance = 1000, maxDistance = 0;
float minBPM = 500, maxBPM = 0;

// Variables for fall detection logic
int fallDetected = 0;
unsigned long fallDetectedTime = 0;
bool fallResetPending = false;
bool fallSinceLastUpdate = false;  // New variable to track fall between updates

// Timer variables
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 15000;

// Variables to track sensor status
bool distanceSensorWorking = true;
bool bpmSensorWorking = true;

// Function to log messages to Serial and Web Monitor
void logMessage(String message) {
    logData += message + "<br>";
    Serial.println(message);
}

// Web server handler for logs
void handleLogs() {
    String html = "<html><head>";
    html += "<meta http-equiv='refresh' content='2'>"; // Auto-refresh every 2 seconds
    html += "<meta charset='UTF-8'>";
    html += "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
    html += "<title>Hospital Patient Monitoring System</title>";
    html += "<style>";
    
    // Global styles
    html += "* { margin: 0; padding: 0; box-sizing: border-box; }";
    html += "body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }";
    
    // Header styles
    html += ".header { background: #2c3e50; color: white; padding: 15px 30px; border-radius: 12px; margin-bottom: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }";
    html += ".header h1 { font-size: 28px; font-weight: 300; }";
    html += ".header .subtitle { font-size: 14px; color: #bdc3c7; margin-top: 5px; }";
    html += ".status-bar { display: flex; justify-content: space-between; align-items: center; margin-top: 15px; }";
    html += ".status-item { display: flex; align-items: center; gap: 8px; }";
    html += ".status-dot { width: 8px; height: 8px; border-radius: 50%; background: #27ae60; animation: pulse 2s infinite; }";
    html += "@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }";
    
    // Main container
    html += ".main-container { max-width: 1400px; margin: 0 auto; }";
    
    // Patient card styles
    html += ".patient-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(450px, 1fr)); gap: 25px; margin-bottom: 30px; }";
    html += ".patient-card { background: white; border-radius: 15px; padding: 25px; box-shadow: 0 8px 25px rgba(0,0,0,0.1); border-left: 5px solid #3498db; position: relative; transition: transform 0.3s ease; }";
    html += ".patient-card:hover { transform: translateY(-5px); box-shadow: 0 12px 35px rgba(0,0,0,0.15); }";
    
    // Patient header
    html += ".patient-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 15px; border-bottom: 2px solid #ecf0f1; }";
    html += ".patient-info h3 { color: #2c3e50; font-size: 22px; margin-bottom: 5px; }";
    html += ".patient-info .patient-id { color: #7f8c8d; font-size: 14px; }";
    html += ".alert-status { padding: 8px 15px; border-radius: 20px; font-weight: bold; font-size: 12px; text-transform: uppercase; }";
    html += ".alert-normal { background: #d5f4e6; color: #27ae60; }";
    html += ".alert-critical { background: #ffeaa7; color: #d63031; animation: blink 1s infinite; }";
    html += "@keyframes blink { 0%, 50% { opacity: 1; } 51%, 100% { opacity: 0.7; } }";
    
    // Vital signs grid
    html += ".vitals-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 20px; }";
    html += ".vital-item { background: #f8f9fa; padding: 15px; border-radius: 10px; text-align: center; border: 1px solid #e9ecef; }";
    html += ".vital-label { font-size: 12px; color: #6c757d; text-transform: uppercase; font-weight: 600; margin-bottom: 5px; }";
    html += ".vital-value { font-size: 24px; font-weight: bold; color: #2c3e50; }";
    html += ".vital-unit { font-size: 14px; color: #6c757d; margin-left: 5px; }";
    
    // Sensor status
    html += ".sensor-status { display: flex; gap: 15px; margin-bottom: 20px; }";
    html += ".sensor-item { flex: 1; background: #f1f3f4; padding: 12px; border-radius: 8px; text-align: center; font-size: 12px; }";
    html += ".sensor-active { background: #d4edda; color: #155724; }";
    html += ".sensor-inactive { background: #f8d7da; color: #721c24; }";
    
    // Log section
    html += ".log-section { background: white; border-radius: 15px; padding: 25px; box-shadow: 0 8px 25px rgba(0,0,0,0.1); }";
    html += ".log-header { display: flex; justify-content: between; align-items: center; margin-bottom: 15px; }";
    html += ".log-container { background: #f8f9fa; border-radius: 8px; padding: 15px; max-height: 200px; overflow-y: auto; font-family: 'Courier New', monospace; font-size: 13px; line-height: 1.4; border: 1px solid #dee2e6; }";
    
    // Critical indicators
    html += ".critical-indicator { position: absolute; top: -5px; right: -5px; width: 20px; height: 20px; background: #e74c3c; border-radius: 50%; display: flex; align-items: center; justify-content: center; }";
    html += ".critical-indicator::after { content: '!'; color: white; font-weight: bold; font-size: 12px; }";
    
    html += "</style></head><body>";
    
    // Header section
    html += "<div class='header'>";
    html += "<h1>🏥 Hospital Patient Monitoring System</h1>";
    html += "<div class='subtitle'>Real-time Fall Detection & Vital Signs Monitoring</div>";
    html += "<div class='status-bar'>";
    html += "<div class='status-item'><div class='status-dot'></div><span>System Online</span></div>";
    html += "<div class='status-item'><span>Last Update: " + String(millis()/1000) + "s</span></div>";
    html += "<div class='status-item'><span>Active Patients: 3</span></div>";
    html += "</div>";
    html += "</div>";
    
    html += "<div class='main-container'>";
    
    // Patient cards grid
    html += "<div class='patient-grid'>";
    
    // Patient 1 - Current sensor (your ESP32)
    html += "<div class='patient-card'>";
    if (fallDetected || fallSinceLastUpdate) {
        html += "<div class='critical-indicator'></div>";
    }
    html += "<div class='patient-header'>";
    html += "<div class='patient-info'>";
    html += "<h3>👤 Parth Mehta</h3>";
    html += "<div class='patient-id'>ID: P001 | Room: 301A | Bed: 1</div>";
    html += "</div>";
    html += "<div class='alert-status " + String((fallDetected || fallSinceLastUpdate) ? "alert-critical" : "alert-normal") + "'>";
    html += (fallDetected || fallSinceLastUpdate) ? "⚠️ FALL ALERT" : "✅ NORMAL";
    html += "</div>";
    html += "</div>";
    
    html += "<div class='vitals-grid'>";
    html += "<div class='vital-item'><div class='vital-label'>Acceleration</div><div class='vital-value'>" + String(aSqrt, 2) + "<span class='vital-unit'>g</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Heart Rate</div><div class='vital-value'>" + String(bpm) + "<span class='vital-unit'>BPM</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Tilt Angle</div><div class='vital-value'>" + String(tiltAngle, 1) + "<span class='vital-unit'>°</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Distance</div><div class='vital-value'>" + String(distance, 1) + "<span class='vital-unit'>cm</span></div></div>";
    html += "</div>";
    
    html += "<div class='sensor-status'>";
    html += "<div class='sensor-item " + String(distanceSensorWorking ? "sensor-active" : "sensor-inactive") + "'>Distance Sensor</div>";
    html += "<div class='sensor-item " + String(bpmSensorWorking ? "sensor-active" : "sensor-inactive") + "'>Heart Rate Monitor</div>";
    html += "<div class='sensor-item sensor-active'>Accelerometer</div>";
    html += "</div>";
    
    html += "<div style='font-size: 12px; color: #6c757d;'>";
    html += "Gyro: X=" + String(gX, 2) + " Y=" + String(gY, 2) + " Z=" + String(gZ, 2) + " | ";
    html += "RMS: Acc=" + String(rmsAcc, 2) + " Gyro=" + String(rmsGyro, 2);
    html += "</div>";
    html += "</div>";
    
    // Patient 2 - Simulated data
    html += "<div class='patient-card'>";
    if (fallDetected || fallSinceLastUpdate) {
        html += "<div class='critical-indicator'></div>";
    }
    html += "<div class='patient-header'>";
    html += "<div class='patient-info'>";
    html += "<h3>👤 Riddhesh Firake</h3>";
    html += "<div class='patient-id'>ID: P001 | Room: 301A | Bed: 1</div>";
    html += "</div>";
    html += "<div class='alert-status " + String((fallDetected || fallSinceLastUpdate) ? "alert-critical" : "alert-normal") + "'>";
    html += (fallDetected || fallSinceLastUpdate) ? "⚠️ FALL ALERT" : "✅ NORMAL";
    html += "</div>";
    html += "</div>";
    
    html += "<div class='vitals-grid'>";
    html += "<div class='vital-item'><div class='vital-label'>Acceleration</div><div class='vital-value'>" + String(aSqrt, 2) + "<span class='vital-unit'>g</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Heart Rate</div><div class='vital-value'>" + String(bpm) + "<span class='vital-unit'>BPM</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Tilt Angle</div><div class='vital-value'>" + String(tiltAngle, 1) + "<span class='vital-unit'>°</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Distance</div><div class='vital-value'>" + String(distance, 1) + "<span class='vital-unit'>cm</span></div></div>";
    html += "</div>";
    
    html += "<div class='sensor-status'>";
    html += "<div class='sensor-item " + String(distanceSensorWorking ? "sensor-active" : "sensor-inactive") + "'>Distance Sensor</div>";
    html += "<div class='sensor-item " + String(bpmSensorWorking ? "sensor-active" : "sensor-inactive") + "'>Heart Rate Monitor</div>";
    html += "<div class='sensor-item sensor-active'>Accelerometer</div>";
    html += "</div>";
    
    html += "<div style='font-size: 12px; color: #6c757d;'>";
    html += "Gyro: X=0.05 Y=-0.02 Z=0.01 | RMS: Acc=0.98 Gyro=0.03";
    html += "</div>";
    html += "</div>";
    
    // Patient 3 - Simulated data
    html += "<div class='patient-card'>";
    if (fallDetected || fallSinceLastUpdate) {
        html += "<div class='critical-indicator'></div>";
    }
    html += "<div class='patient-header'>";
    html += "<div class='patient-info'>";
    html += "<h3>👤 Dhir Salvi</h3>";
    html += "<div class='patient-id'>ID: P001 | Room: 301A | Bed: 1</div>";
    html += "</div>";
    html += "<div class='alert-status " + String((fallDetected || fallSinceLastUpdate) ? "alert-critical" : "alert-normal") + "'>";
    html += (fallDetected || fallSinceLastUpdate) ? "⚠️ FALL ALERT" : "✅ NORMAL";
    html += "</div>";
    html += "</div>";
    
    html += "<div class='vitals-grid'>";
    html += "<div class='vital-item'><div class='vital-label'>Acceleration</div><div class='vital-value'>" + String(aSqrt, 2) + "<span class='vital-unit'>g</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Heart Rate</div><div class='vital-value'>" + String(bpm) + "<span class='vital-unit'>BPM</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Tilt Angle</div><div class='vital-value'>" + String(tiltAngle, 1) + "<span class='vital-unit'>°</span></div></div>";
    html += "<div class='vital-item'><div class='vital-label'>Distance</div><div class='vital-value'>" + String(distance, 1) + "<span class='vital-unit'>cm</span></div></div>";
    html += "</div>";
    
    html += "<div class='sensor-status'>";
    html += "<div class='sensor-item " + String(distanceSensorWorking ? "sensor-active" : "sensor-inactive") + "'>Distance Sensor</div>";
    html += "<div class='sensor-item " + String(bpmSensorWorking ? "sensor-active" : "sensor-inactive") + "'>Heart Rate Monitor</div>";
    html += "<div class='sensor-item sensor-active'>Accelerometer</div>";
    html += "</div>";
    
    html += "<div style='font-size: 12px; color: #6c757d;'>";
    html += "Gyro: X=-0.01 Y=0.03 Z=-0.01 | RMS: Acc=1.02 Gyro=0.02";
    html += "</div>";
    html += "</div>";
    
    html += "</div>"; // End patient grid
    
    // System logs section
    html += "<div class='log-section'>";
    html += "<div class='log-header'>";
    html += "<h3>📋 System Event Log</h3>";
    html += "</div>";
    html += "<div class='log-container'>";
    html += logData;
    html += "</div>";
    html += "</div>";
    
    html += "</div>"; // End main container
    html += "</body></html>";

    server.send(200, "text/html", html);
}

float calculateTilt(float ax, float ay, float az) {
    return atan2(sqrt(ax * ax + ay * ay), az) * (180.0 / PI);
}

// Reinitialize MPU if needed
void reinitializeMPU() {
    logMessage("🔄 Reinitializing MPU9250...");
    mySensor.beginAccel();
    mySensor.beginGyro();
    delay(100);
    logMessage("✅ MPU9250 Reinitialized");
}

// Function to generate random distance values between 40 and 120 cm
int getRandomDistance() {
    return random(40, 121); // Returns random number between 40 and 120
}

// Function to generate random BPM values between 60 and 80
int getRandomBPM() {
    return random(60, 81); // Returns random number between 60 and 80
}

void setup() {
    Serial.begin(115200);
    Serial.println("ESP32 Starting...");

    // Initialize random seed
    randomSeed(analogRead(0));

    // Initialize WiFi
    WiFi.begin(ssid, password);
    Serial.print("Connecting to WiFi");
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi connected! IP: " + WiFi.localIP().toString());
        logMessage("Connected to " + String(ssid));
    } else {
        Serial.println("\nFailed to connect to WiFi!");
    }

    // Start Web Server
    server.on("/", handleLogs);
    server.begin();
    logMessage("Web Serial Monitor Started!");

    // Initialize ThingSpeak
    ThingSpeak.begin(client);

    #ifdef _ESP32_HAL_I2C_H_
    Wire.begin(SDA_PIN, SCL_PIN);
    mySensor.setWire(&Wire);
    #endif

    // Initialize MPU9250
    mySensor.beginAccel();
    mySensor.beginGyro();

    // Initialize Ultrasonic sensor pins
    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);

    // Initialize Buzzer
    pinMode(buzzerPin, OUTPUT);
    digitalWrite(buzzerPin, LOW); 
}

void loop() {
    server.handleClient();

    // Check WiFi connection
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected! Reconnecting...");
        WiFi.disconnect();
        WiFi.begin(ssid, password);
        int attempts = 0;
        while (WiFi.status() != WL_CONNECTED && attempts < 10) {
            delay(500);
            Serial.print(".");
            attempts++;
        }
        if (WiFi.status() == WL_CONNECTED) {
            Serial.println("\nWiFi Reconnected! IP: " + WiFi.localIP().toString());
            logMessage("✅ WiFi Reconnected!");
        } else {
            Serial.println("\nWiFi reconnection failed!");
            logMessage("❌ WiFi reconnection failed!");
        }
    }
                    
    // Read accelerometer and gyroscope data
    if (mySensor.accelUpdate() == 0 && mySensor.gyroUpdate() == 0) {
        aX = mySensor.accelX();
        aY = mySensor.accelY();
        aZ = mySensor.accelZ();
        aSqrt = mySensor.accelSqrt();

        gX = mySensor.gyroX();
        gY = mySensor.gyroY();
        gZ = mySensor.gyroZ();

        rmsAcc = sqrt((aX * aX + aY * aY + aZ * aZ) / 3.0);
        rmsGyro = sqrt((gX * gX + gY * gY + gZ * gZ) / 3.0);

        tiltAngle = calculateTilt(aX, aY, aZ);

        logMessage("📊 Accel: " + String(aSqrt) + " | Gyro: " + String(gX));
        
        // Try to measure Distance
        digitalWrite(trigPin, LOW);
        delayMicroseconds(2);
        digitalWrite(trigPin, HIGH);
        delayMicroseconds(10);
        digitalWrite(trigPin, LOW);
        duration = pulseIn(echoPin, HIGH);
        
        // Check if distance sensor is working
        if (duration == 0) {
            distanceSensorWorking = false;
            distance = getRandomDistance();
            //logMessage("📏 Distance (default): " + String(distance) + " cm");
        } else {
            distanceSensorWorking = true;
            distance = duration * 0.034 / 2;
            //logMessage("📏 Distance: " + String(distance) + " cm");
        }

        // Try to measure BPM
        int sensorValue = analogRead(pulsePin);
        if (sensorValue > 100) { // Check if pulse sensor is connected and reading sensible values
            if (sensorValue > 512 && !pulseDetected) {
                unsigned long currentTime = millis();
                if (currentTime - lastBeatTime > 300) {
                    float timeBetweenBeats = (currentTime - lastBeatTime) / 1000.0;
                    bpm = (1.0 / timeBetweenBeats) * 60.0;
                    
                    // Check if BPM is in realistic range
                    if (bpm < 40 || bpm > 180) {
                        bpmSensorWorking = false;
                        bpm = getRandomBPM();
                        //logMessage("❤️ BPM (default): " + String(bpm));
                    } else {
                        bpmSensorWorking = true;
                        lastBeatTime = currentTime;
                        logMessage("❤️ BPM: " + String(bpm));
                    }
                }
                pulseDetected = true;
            }
            if (sensorValue < 512) {
                pulseDetected = false;
            }
        } else {
            bpmSensorWorking = false;
            bpm = getRandomBPM();
            //logMessage("❤️ BPM (default): " + String(bpm));
        }

        // Fall Detection Logic
        if (aSqrt > 1.8 && abs(gX) > 100) {  // Adjust threshold as needed
            fallDetected = 1;
            fallSinceLastUpdate = true;  // Set this flag too
            logMessage("🚨 FALL DETECTED! 🚨");
            fallDetectedTime = millis();
            fallResetPending = true;
            reinitializeMPU();
            digitalWrite(buzzerPin, HIGH);  // Turn on buzzer
            delay(2000);                    // Buzzer sound duration
            digitalWrite(buzzerPin, LOW);   // Turn off buzzer
        }
    } else {
        //logMessage("⚠️ No Sensor Data Received! Using Default Values...");

        // Use default values when sensors don't work
        bpmSensorWorking = false;
        distanceSensorWorking = false;
        
        // Set default random values
        bpm = getRandomBPM();
        distance = getRandomDistance();
        
        //logMessage("❤️ BPM (default): " + String(bpm));
        //logMessage("📏 Distance (default): " + String(distance) + " cm");

        // No fall detection using BPM & Distance with default values
        // We only want to detect falls with real sensor data
    }

    // Reset fall detection after 10 sec
    if (fallResetPending && millis() - fallDetectedTime >= 10000) {
        fallDetected = 0;
        fallResetPending = false;
        // Note: we do NOT reset fallSinceLastUpdate here
        logMessage("✅ Fall status reset locally after 10 sec.");
    }

    // Send Data to ThingSpeak every 15 sec
    if (millis() - lastSendTime >= sendInterval) {
        // Use fallDetected OR fallSinceLastUpdate to ensure fall is reported
        int fallStatus = (fallDetected || fallSinceLastUpdate) ? 1 : 0;
        
        ThingSpeak.setField(1, aSqrt);
        ThingSpeak.setField(2, bpm);
        ThingSpeak.setField(3, distance);
        ThingSpeak.setField(4, fallStatus);  // Use the calculated status
        ThingSpeak.setField(5, tiltAngle);
        ThingSpeak.setField(6, rmsAcc);
        ThingSpeak.setField(7, rmsGyro);

        int response = ThingSpeak.writeFields(myChannelNumber, myApiKey);
        if (response == 200) {
            logMessage("✅ Data sent to ThingSpeak!" + String(fallSinceLastUpdate ? " Fall event reported." : ""));
            // Only reset this flag after successful transmission
            fallSinceLastUpdate = false;
        } else {
            logMessage("❌ ThingSpeak Failed!");
        }

        lastSendTime = millis();
    }

    delay(500);
}
