/*
  Reference ESP32 firmware — matches the FastAPI contract in backend/app/routers/esp32.py

  Responsibilities:
    1. Connect to train Wi-Fi, get IP automatically (no hardcoding)
    2. Register with FastAPI backend (sends its own IP)
    3. Send heartbeat every 5s so backend/staff dashboard know it's alive
    4. Report magnetic marker detections (seat arrivals) -> backend
    5. Expose POST /unlock (called by backend after OTP success) -> open servo lock
    6. Read MPU6050 continuously; on abnormal motion while locked, POST a security alert

  Libraries needed: WiFi.h, HTTPClient.h, ArduinoJson, ESP32Servo, Adafruit_MPU6050 (+ Adafruit_Sensor)
*/

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <WebServer.h>

// ---------- CONFIG ----------
const char* WIFI_SSID     = "TRAIN_WIFI";
const char* WIFI_PASSWORD = "train_wifi_password";
const char* BACKEND_HOST  = "192.168.1.50";   // FastAPI machine's IP on the train LAN
const int   BACKEND_PORT  = 8000;
const char* ROBOT_ID      = "POD-01";

Servo lockServo;
Adafruit_MPU6050 mpu;
WebServer localServer(80);

bool compartmentLocked = true;
float baselineAccel = 0;

// ---------- HELPERS ----------
String backendUrl(const String& path) {
  return "http://" + String(BACKEND_HOST) + ":" + String(BACKEND_PORT) + path;
}

void postJson(const String& path, JsonDocument& doc) {
  HTTPClient http;
  http.begin(backendUrl(path));
  http.addHeader("Content-Type", "application/json");
  String body;
  serializeJson(doc, body);
  http.POST(body);
  http.end();
}

void connectWifi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(400);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected. IP: ");
  Serial.println(WiFi.localIP());
}

void registerWithBackend() {
  JsonDocument doc;
  doc["robotId"] = ROBOT_ID;
  doc["ipAddress"] = WiFi.localIP().toString();
  postJson("/esp32/register", doc);
  Serial.println("Registered with backend.");
}

void sendHeartbeat() {
  JsonDocument doc;
  doc["robotId"] = ROBOT_ID;
  doc["ipAddress"] = WiFi.localIP().toString();
  postJson("/esp32/heartbeat", doc);
}

// Call this when a Hall-effect / magnetic marker is detected at a seat.
void reportMarkerDetected(const String& coachNo, const String& seatNo,
                           const String& markerId, const String& orderId) {
  JsonDocument doc;
  doc["robotId"] = ROBOT_ID;
  doc["coachNo"] = coachNo;
  doc["seatNo"] = seatNo;
  doc["markerId"] = markerId;
  doc["orderId"] = orderId;
  postJson("/esp32/marker-detected", doc);
}

void raiseSecurityAlert() {
  JsonDocument doc;
  doc["robotId"] = ROBOT_ID;
  doc["coachNo"] = "UNKNOWN"; // fill with last known coach if available
  doc["alertType"] = "UNAUTHORIZED_MOVEMENT";
  postJson("/security/alert", doc);
  Serial.println("SECURITY ALERT sent to backend.");
}

// ---------- LOCAL HTTP SERVER (backend calls this after OTP success) ----------
void handleUnlock() {
  compartmentLocked = false;
  lockServo.write(90);   // rotate to open position
  Serial.println("UNLOCK command received -> compartment opened");
  localServer.send(200, "application/json", "{\"ok\":true}");
}

void setup() {
  Serial.begin(115200);
  connectWifi();
  registerWithBackend();

  lockServo.attach(13);
  lockServo.write(0);    // locked position

  if (!mpu.begin()) {
    Serial.println("MPU6050 not found!");
  } else {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    baselineAccel = sqrt(a.acceleration.x * a.acceleration.x +
                          a.acceleration.y * a.acceleration.y +
                          a.acceleration.z * a.acceleration.z);
  }

  localServer.on("/unlock", HTTP_POST, handleUnlock);
  localServer.begin();
}

unsigned long lastHeartbeat = 0;

void loop() {
  localServer.handleClient();

  if (millis() - lastHeartbeat > 5000) {
    sendHeartbeat();
    lastHeartbeat = millis();
  }

  if (mpu.begin()) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    float mag = sqrt(a.acceleration.x * a.acceleration.x +
                      a.acceleration.y * a.acceleration.y +
                      a.acceleration.z * a.acceleration.z);
    if (compartmentLocked && mag > baselineAccel * 1.5) {
      raiseSecurityAlert();
      delay(3000); // debounce, avoid alert spam
    }
  }

  // TODO: replace with real Hall-effect marker polling, calling
  // reportMarkerDetected(coach, seat, markerId, orderId) on detection.
}
