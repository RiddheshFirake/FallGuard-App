# FallGuard: IoT-Driven Fall Detection and Health Monitoring System

## 📖 Table of Contents
1.  [About The Project](#about-the-project)
2.  [Features](#features)
3.  [System Architecture](#system-architecture)
    * [Hardware Layer](#hardware-layer)
    * [Processing Layer](#processing-layer)
    * [Cloud Layer](#cloud-layer)
    * [Application Layer](#application-layer)
4.  [System Flow](#system-flow)
5.  [Fall Detection Logic](#fall-detection-logic)
6.  [Data Visualization](#data-visualization)
7.  [Experimental Results](#experimental-results)
8.  [Future Scope](#future-scope)
9.  [Contributors](#contributors)
10. [Acknowledgments](#acknowledgments)

## 🚀 About The Project

FallGuard is an IoT-driven system designed to enhance safety and healthcare for the elderly and individuals with mobility issues. It leverages modern IoT technologies, wearable sensors, and cloud platforms like ThingSpeak and Firebase to provide a robust fall detection and health monitoring solution. The system focuses on accurately differentiating between actual falls and normal daily activities, thereby reducing false positives, optimizing battery usage, and improving user interaction. The primary goal is to rapidly detect falls and promptly alert caregivers or healthcare personnel.

## ✨ Features

* **Real-Time Fall Detection:** Utilizes accelerometers, gyroscopes, and pulse sensors for immediate fall detection.
* **Machine Learning Enhanced Accuracy:** Employs machine learning algorithms on the ESP32 microcontroller to analyze movement patterns and enhance detection accuracy.
* **Reduced False Positives:** Implements free-fall and impact thresholds to minimize false alarms. Achieved an accuracy of 95% in simulated fall tests.
* **Comprehensive Health Monitoring:** Tracks heart rhythm and oxygen levels via a pulse sensor, providing insights into health events during falls.
* **Real-Time Alerts & Notifications:** Sends immediate alerts to caregivers or healthcare personnel upon fall detection.
* **Data Visualization:**
    * Real-time graphs and data visualization on the ThingSpeak platform.
    * Dedicated mobile application for monitoring vital signs and fall status.
    * LCD display on the wearable device for instant feedback.
* **Secure Cloud Data Storage:** Sensor data, including distance, acceleration, heart rate, and fall status, is securely stored and managed using Firebase, ensuring data confidentiality.
* **Personalized Detection:** Incorporates pre-classification based on age, gender, height, and weight to adjust detection thresholds for individual users.
* **Historical Data Analysis:** Stores historical data to recognize individual behavior patterns, allowing the system to learn and improve detection criteria over time.

## 🛠️ System Architecture

The system is structured in multiple layers:

### Hardware Layer (Sensors)
* **MPU-9250:** An accelerometer and gyroscope module to capture acceleration and angular velocity data.
* **Pulse Sensor (e.g., MAX30102):** Measures heart rhythm (BPM) and oxygen levels.
* **Ultrasonic Distance Sensor (e.g., HC-SR04 Mini):** Measures the distance to objects or surroundings.

### Processing Layer (Microprocessor)
* **ESP32 Microcontroller:** Processes data from sensors, runs the fall detection algorithm, and manages Wi-Fi communication for data transmission. Its low-power design ensures long-term use.

### Cloud Layer (Cloud Storage & Platform)
* **ThingSpeak:** An IoT analytics platform service used for real-time data streaming, visualization of health trends, and remote monitoring. Data logging intervals are optimized (e.g., every 5 seconds during fall detection, every second during normal monitoring).
* **Firebase:** A cloud-based backend platform used for secure data storage (distance, acceleration, heart rate, fall status), retrieval, and real-time data synchronization across devices.

### Application Layer (App)
* **Mobile Application:** (Developed using Flutter)
    * Provides an interactive user interface for monitoring essential parameters in real-time.
    * Displays:
        * Distance (proximity in motion).
        * Acceleration (g-forces recorded).
        * Heart Rate (BPM).
        * Fall Status (dynamic indication of fall detection).
        * Tilt Angle Overview.
    * Features color-coded status indicators (e.g., green for "No Fall Detected," red for "Fall Detected").
    * Includes a refresh button for manual data updates.
* **Hospital Dashboard:** A dashboard for analyzing fall detection logs.

## 🔄 System Flow

The system operates as follows:
1.  **Data Acquisition:** The wearable device continuously collects data from the MPU-9250 (accelerometer, gyroscope), pulse sensor, and distance sensor.
2.  **Data Processing:** The ESP32 microcontroller processes this raw sensor data. It analyzes values to recognize free-fall conditions and impacts against predefined thresholds.
3.  **Fall Verification & Alerting:** If a fall is confirmed by the algorithm, the system immediately sends out a warning/alert. The on-device LCD also displays the fall status.
4.  **Cloud Data Transmission & Storage:**
    * Simultaneously, all sensor data (resultant acceleration, fall status, pulse rate, distance) is uploaded to the ThingSpeak platform for real-time visualization and remote monitoring by caregivers.
    * Data is also stored in Firebase for logging, monitoring user activity, and ensuring data integrity.
5.  **Application Display:** The mobile application and hospital dashboard display the processed data and fall alerts, allowing for continuous monitoring and timely intervention.

## 🧠 Fall Detection Logic

The fall detection logic is based on a two-stage threshold-based approach using data from the MPU-9250 sensor:

1.  **Free Fall Detection:**
    * A potential fall is detected if the resultant acceleration (R) drops below a predefined free-fall threshold. The system uses a threshold of **0.8g**.
    * If R < freeFallThreshold (0.8g), then `fallDetected = true`.

## 📊 Data Visualization

The system provides multiple interfaces for data visualization and monitoring:
* **Wearable Device LCD:** Displays "Fall Detected!" or "No Fall Detected" messages instantaneously.
* **ThingSpeak Platform:** Offers real-time graphs for resultant acceleration, fall status, pulse rate, and distance, enabling remote observation.
* **Mobile Application:** A user-friendly interface on a smartphone app displays:
    * Vital Signs Overview (Distance, Acceleration, Heart Rate).
    * Fall Status (Live).
    * Tilt Angle Overview graph.
    * Acceleration Overview graph.
* **Hospital Dashboard:** Provides a log analysis view for fall detection events, showing acceleration, gyro data, tilt angle, RMS values, distance, BPM, and fall detected status.

## 📈 Experimental Results

* The system demonstrated a fall detection accuracy of **95%** during tests involving various simulated fall conditions and normal activities.
* Successful data transmission to ThingSpeak was confirmed with HTTP response codes in the 200 range, indicating accurate data logging.
* The device effectively uses thresholds (free-fall < 0.8g, impact > 2.0g) to distinguish falls.

## 🔭 Future Scope

* **Enhanced Personalization:** Further learn and adapt to different user requirements to improve reliability and user experience during everyday usage.
* **Preventive Care:** Transition towards preventive care by leveraging monitored activity and health data to forecast potential fall hazards and tailor preventive measures.
* **Advanced Analytics:** Continue exploring the potential of IoT and machine learning to transform healthcare, self-care, and fall prevention strategies.


## 🙏 Acknowledgments

* This project builds upon existing research in IoT-based fall detection systems and aims to address gaps such as real-time response, energy efficiency, and data privacy.
