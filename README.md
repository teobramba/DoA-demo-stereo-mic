# 🎙️ Direction of Arrival (DoA) Estimator

## Introduction
This repository contains a MATLAB script that estimates the **Direction of Arrival (DoA)** of a sound source using a simple 2-microphone array. 

In simple terms, this code acts like a digital pair of ears. By feeding it a stereo audio file (recorded with two microphones placed a known distance apart), the script calculates the exact angle from which the sound is coming and visualizes this data in real-time alongside the audio playback. 

It is designed to be highly customizable, allowing you to tweak microphone distances, apply manual angle corrections, and smooth out the data for easier reading.

---

## 🧠 How It Works (The Core Concepts)

To understand what the code is doing under the hood, here is a breakdown of the technical concepts used, explained simply:

*   **DoA (Direction of Arrival):** This is the main goal of the script—figuring out the angle of the sound source relative to the microphones. Think of it as the digital equivalent of turning your head when someone calls your name. 
*   **Cross-correlation (`xcorr`):** To figure out the direction of a sound, the code needs to know which microphone heard it first. Cross-correlation is like sliding two identical pieces of tracing paper over each other until the squiggly lines perfectly line up. The code overlays the audio track from Microphone 1 and Microphone 2 to find exactly how much one track needs to be shifted to match the other.
*   **ITD (Interaural Time Difference):** This is the result of the cross-correlation. It is the tiny fraction of a second it takes for the sound wave to reach the second microphone after hitting the first one. Our brains use this exact same delay between our two ears to locate a sound in a room.
*   **The Math:** Once we have the time delay, the code uses basic trigonometry to find the angle. If you multiply the time delay ($\Delta t$) by the speed of sound ($c$), you get the extra physical distance the sound had to travel. Divide that by the distance between the two microphones ($d$), and you get the sine of the angle: 
    $$\sin(\theta) = \frac{\Delta t \cdot c}{d}$$
    The code then converts this ratio back into a readable angle in degrees.
*   **Moving Average Smoothing:** Raw audio data can be messy due to background noise or room echoes, causing the estimated angle to jump around wildly. The code applies a "moving average," which acts as a shock absorber. It takes a window of recent data points, averages them out, and creates a smooth, steady line that shows the true movement of the sound source.

---

## 📊 Visualizing the Output

When you run the script, it plays the audio file and generates two synchronized, dynamic plots to help you visualize the data in real-time.

### 1. The Polar Plot
This plot gives you a "radar" view of where the sound is currently coming from. 0° represents directly in front of the microphones, -90° is to the left, and +90° is to the right. 

![Current DoA Polar Plot](DoA%20Visual%20Angle.png)

### 2. The Time-Angle Plot
This graph tracks the sound's movement over the entire duration of the audio file. 
*   The **thin grey line** shows the raw, instantaneous calculations (which can be erratic).
*   The **bold red/blue line** shows the smoothed data using the moving average, making it much easier to follow the true path of the sound.

![Angle of Arrival over Time Plot](DoA%20plot%20Angle.png)

---

## ⚙️ Configuration

You can easily adapt this script to your own hardware by modifying the parameters at the top of the MATLAB file:

*   `DISTANCE`: Set this to the exact distance (in meters) between your two microphones.
*   `WINDOW_SIZE_SEC`: Controls how much audio is analyzed at once. 
*   `MOVING_AVERAGE_WINDOW`: Controls the "shock absorber." A value of `1` means no smoothing. Higher values (e.g., `10` or `20`) make the line smoother but slightly slower to react to sudden movements.
*   `ANGLE_OFFSET_DEG`: If your microphones are slightly off-center, you can apply a fixed correction angle here to re-calibrate 0° to the true front.
