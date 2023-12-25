#include <SoftwareSerial.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>

const int flexPin0 = A0; 
const int flexPin1 = A1; 
const int flexPin2 = A2; 
const int flexPin3 = A3; 
const int flexPin4 = A6; 

/* Assign a unique ID to this sensor at the same time */
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345); 
SoftwareSerial MyBlue(2, 3); // RX | TX 
int value0, value1, value2, value3, value4; //save analog value
char flag; 


void displaySensorDetails(void)
{
  sensor_t sensor;
  accel.getSensor(&sensor);
  Serial.println("------------------------------------");
  Serial.print  ("Sensor:       "); Serial.println(sensor.name);
  Serial.print  ("Driver Ver:   "); Serial.println(sensor.version);
  Serial.print  ("Unique ID:    "); Serial.println(sensor.sensor_id);
  Serial.print  ("Max Value:    "); Serial.print(sensor.max_value); Serial.println(" m/s^2");
  Serial.print  ("Min Value:    "); Serial.print(sensor.min_value); Serial.println(" m/s^2");
  Serial.print  ("Resolution:   "); Serial.print(sensor.resolution); Serial.println(" m/s^2");  
  Serial.println("------------------------------------");
  Serial.println("");
  delay(500);
}

void displayDataRate(void)
{
  Serial.print  ("Data Rate:    "); 
  
  switch(accel.getDataRate())
  {
    case ADXL345_DATARATE_3200_HZ:
      Serial.print  ("3200 "); 
      break;
    case ADXL345_DATARATE_1600_HZ:
      Serial.print  ("1600 "); 
      break;
    case ADXL345_DATARATE_800_HZ:
      Serial.print  ("800 "); 
      break;
    case ADXL345_DATARATE_400_HZ:
      Serial.print  ("400 "); 
      break;
    case ADXL345_DATARATE_200_HZ:
      Serial.print  ("200 "); 
      break;
    case ADXL345_DATARATE_100_HZ:
      Serial.print  ("100 "); 
      break;
    case ADXL345_DATARATE_50_HZ:
      Serial.print  ("50 "); 
      break;
    case ADXL345_DATARATE_25_HZ:
      Serial.print  ("25 "); 
      break;
    case ADXL345_DATARATE_12_5_HZ:
      Serial.print  ("12.5 "); 
      break;
    case ADXL345_DATARATE_6_25HZ:
      Serial.print  ("6.25 "); 
      break;
    case ADXL345_DATARATE_3_13_HZ:
      Serial.print  ("3.13 "); 
      break;
    case ADXL345_DATARATE_1_56_HZ:
      Serial.print  ("1.56 "); 
      break;
    case ADXL345_DATARATE_0_78_HZ:
      Serial.print  ("0.78 "); 
      break;
    case ADXL345_DATARATE_0_39_HZ:
      Serial.print  ("0.39 "); 
      break;
    case ADXL345_DATARATE_0_20_HZ:
      Serial.print  ("0.20 "); 
      break;
    case ADXL345_DATARATE_0_10_HZ:
      Serial.print  ("0.10 "); 
      break;
    default:
      Serial.print  ("???? "); 
      break;
  }  
  Serial.println(" Hz");  
}

void displayRange(void)
{
  Serial.print  ("Range:         +/- "); 
  
  switch(accel.getRange())
  {
    case ADXL345_RANGE_16_G:
      Serial.print  ("16 "); 
      break;
    case ADXL345_RANGE_8_G:
      Serial.print  ("8 "); 
      break;
    case ADXL345_RANGE_4_G:
      Serial.print  ("4 "); 
      break;
    case ADXL345_RANGE_2_G:
      Serial.print  ("2 "); 
      break;
    default:
      Serial.print  ("?? "); 
      break;
  }  
  Serial.println(" g");  
}

void writeFloat(float num){
  float num_bbuf;
  if (num < 0) {
    num_bbuf = -num;
    MyBlue.write(45);
    Serial.print("-");
  } else {
    num_bbuf = num;
  } 
  int number = num_bbuf * 100;
  
  int length = 0, power = 1;
  
  // Serial.println(number);
  if (number > 1000){
    for (int i = 0; i < 4; i++){
      if (number > power) {
        length++;
        power = power * 10;
      }else{
        break;
      }
    }
  } else {
    length = 3;
    power = 1000;
  }
  
  
  // Serial.println(length);
  // Serial.println(power);
  power = power / 10;
  
  for (int i = 0; i < length; i++){
    int num_buf = number / power + 48;
    MyBlue.write(num_buf);
    Serial.print(number / power);
    number = number - (number / power) * power;
    power = power / 10;
    if(power == 10) {
      MyBlue.write(46);
      Serial.print(".");
    }
  }
  Serial.println("");
}

void writeMultiple(int num){
  int number = num;
  if (num < 0){
    number = -num;
    MyBlue.write(45);
  }
  
  if (number >= 1000){
    int power = 1000;
    for (int i = 0; i < 4; i++){
      int num_buf = number / power + 48;
      MyBlue.write(num_buf);
      number = number - (number / power) * power;
      power = power / 10;
    }
  } else if (number >= 100){
    int power = 100;
    for (int i = 0; i < 3; i++){
      int num_buf = number / power + 48;
      MyBlue.write(num_buf);
      number = number - (number / power) * power;
      power = power / 10;
    }
  } else if (number >= 10) {
    int power = 10;
    for (int i = 0; i < 2; i++){
      int num_buf = number / power + 48;
      MyBlue.write(num_buf);
      number = number - (number / power) * power;
      power = power / 10;
    }
  } else {
    MyBlue.write(number + 48);
  }
  
}

void readFlex(){

  writeMultiple(value0);
  MyBlue.write(" ");
  writeMultiple(value1);
  MyBlue.write(" ");
  writeMultiple(value2);
  MyBlue.write(" ");
  writeMultiple(value3);
  MyBlue.write(" ");
  writeMultiple(value4);
  // MyBlue.write(" ");
  
}

void readGyro(sensors_event_t& event){
  float eventX = event.acceleration.x * 100;
  float eventY = event.acceleration.y * 100;
  float eventZ = event.acceleration.z * 100;
  // float eventX = 0.25 * 100;
  // float eventY = 0.55 * 100;
  // float eventZ = 0.58 * 100;

  int eventX_int = (int)eventX;
  int eventY_int = (int)eventY;
  int eventZ_int = (int)eventZ;

  // Serial.print("X: "); Serial.print(eventX); Serial.print("  ");
  // Serial.print("Y: "); Serial.print(eventY); Serial.print("  ");
  // Serial.print("Z: "); Serial.print(eventZ); Serial.print("  ");Serial.println("m/s^2 ");
  
  // Serial.println("===========");
  // Serial.println(eventX);
  // Serial.println(eventY);
  // Serial.println(eventZ);
  // Serial.println("===========");
  
  
  // MyBlue.write("X: ");
  writeMultiple(eventX_int);
  MyBlue.write(" ");
  
  // MyBlue.write("Y: ");
  writeMultiple(eventY_int);
  MyBlue.write(" ");

  // MyBlue.write("Z: ");
  writeMultiple(eventZ_int);
  // MyBlue.write(" ");

  // MyBlue.write("m/s^2 ");
}

void setup() 
{   
  Serial.begin(9600); 
  MyBlue.begin(115200); 
  Serial.println("Bluetooth connected.");
  /* Initialise the sensor */
  if(!accel.begin())
  {
    Serial.println("Gyro fail.");
    while(1);
  }
  Serial.println("Gyro connected.");
  

  /* Set the range to whatever is appropriate for your project */
  accel.setRange(ADXL345_RANGE_16_G);
  // accel.setRange(ADXL345_RANGE_8_G);
  // accel.setRange(ADXL345_RANGE_4_G);
  // accel.setRange(ADXL345_RANGE_2_G);
  
  /* Display some basic information on this sensor */
  displaySensorDetails();
  
  /* Display additional settings (outside the scope of sensor_t) */
  displayDataRate();
  displayRange();
  Serial.println(""); 
} 

void loop() 
{ 
  /* Get a new sensor event */ 
  sensors_event_t event; 
  accel.getEvent(&event);
  value0 = analogRead(flexPin0);
  value1 = analogRead(flexPin1);
  value2 = analogRead(flexPin2);
  value3 = analogRead(flexPin3);
  value4 = analogRead(flexPin4);
  
  if (MyBlue.available()){
    flag = MyBlue.read(); 
    Serial.println(flag);
    if (flag == '1') { 
      readGyro(event);
      MyBlue.write(" "); 
      readFlex();
      MyBlue.write("\n"); 
    } else {
      Serial.println("Unrecognized");
    }
  }
}