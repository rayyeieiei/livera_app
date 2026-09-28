#define BLYNK_TEMPLATE_ID "TMPL6iqtBzUNm"
#define BLYNK_TEMPLATE_NAME "AlgaLife"
#define BLYNK_AUTH_TOKEN "YOUR_BLYNK_AUTH_TOKEN"

#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>
#include <LiquidCrystal_I2C.h>

#define POT_CO2 34
#define POT_TEMP 35
#define POT_LIGHT 32 
#define LED_GROW 2
#define FAN_PIN 4
#define POT_PH 33
#define POT_O2 25

const int freq = 5000;
const int resolution = 8; 

char auth[] = BLYNK_AUTH_TOKEN;
char ssid[] = "Wokwi-GUEST";
char pass[] = "";

LiquidCrystal_I2C lcd(0x27, 16, 2);
BlynkTimer timer;

void processSystem() {
  // 1. BACA SENSOR (Pastiin Pin 36 di Wokwi ya jir)
  int rawCO2  = analogRead(34);
  int rawTemp = analogRead(35);
  int rawLght = analogRead(32);
  int rawPH   = analogRead(33);
  int rawO2   = analogRead(36); 

  int co2 = map(rawCO2, 0, 4095, 400, 2000);
  float temp = map(rawTemp, 0, 4095, 20, 50);
  float phVal = map(rawPH, 0, 4095, 0, 1400) / 100.0;
  int o2Val = map(rawO2, 0, 4095, 0, 100);
  int lightIntensity = map(rawLght, 0, 4095, 0, 1000); 

  // 2. LOGIKA KIPAS
  int fanSpeed = (co2 > 800) ? map(co2, 800, 2000, 100, 255) : 0;
  ledcWrite(FAN_PIN, fanSpeed);
  int fanPercent = map(fanSpeed, 0, 255, 0, 100);
  
  // 3. LOGIKA LAMPU
  int lightStatus = (temp > 35.0) ? 0 : 1;
  digitalWrite(LED_GROW, lightStatus ? HIGH : LOW);

  // 4. KIRIM DATA KE BLYNK
  Blynk.virtualWrite(V0, co2);
  Blynk.virtualWrite(V1, temp);
  Blynk.virtualWrite(V2, lightStatus);
  Blynk.virtualWrite(V3, fanPercent);
  Blynk.virtualWrite(V4, lightIntensity); 
  Blynk.virtualWrite(V5, phVal); 
  Blynk.virtualWrite(V6, o2Val);

  // 5. UPDATE LCD (PAS 16 KARAKTER JIR)
  char line1[17]; 
  char line2[17];

  // Baris 1: C (4 digit), L (3 digit), O (2 digit) -> Total 16 char
  // Format: "C:1200 L:850 O:95"
  sprintf(line1, "C:%-4d L:%-3d O:%-2d", co2, lightIntensity, o2Val);

  // Baris 2: T (2 digit), P (3 digit), F (3 digit) -> Total 16 char
  // Format: "T:28 P:7.4 F:100%"
  sprintf(line2, "T:%-2d P:%-3.1f F:%-3d%%", (int)temp, phVal, fanPercent);

  lcd.setCursor(0, 0);
  lcd.print(line1); 
  lcd.setCursor(0, 1);
  lcd.print(line2);

  // 6. DEBUG SERIAL
  Serial.printf("C:%d|T:%.1f|L:%d|F:%d%%|PH:%.2f|O2:%d%%\n", 
                co2, temp, lightIntensity, fanPercent, phVal, o2Val);
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_GROW, OUTPUT);
  ledcAttach(FAN_PIN, freq, resolution); 

  lcd.init();
  lcd.backlight();
  lcd.print("LIVERA STARTING");

  Blynk.begin(auth, ssid, pass); 
  timer.setInterval(2000L, processSystem); 
  lcd.clear();
}

void loop() {
  Blynk.run();
  timer.run();
}