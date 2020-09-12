import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'dart:convert'; //utf8.encode
import 'package:flutter/foundation.dart'; //listEquals
import '../home.dart';
//import 'dart:io'; //stdout.write();
import 'dart:typed_data'; //for data formatting
import '../main.dart';


/* ----------------------------------------------------------------------------
 * Credit:   
 * 
 * The code here is learned from the link below.
 * Based on Neil Kolban example: 
 * https://github.com/nkolban/ESP32_BLE_Arduino
 * 
 * https://medium.com/flutter-community/flutter-for-bluetooth-devices-5594f105b146
 * Author's site: https://github.com/MDSADABWASIM  
 *
 * Other Reference Websites:
 * 
 * https://github.com/pauldemarco/flutter_blue
 * https://github.com/Polidea/FlutterBleLib
 * https://github.com/itavero/flutter-ble-uart (UART on top of flutter_blue)
 * 
 * Andriod:
 * 
 * https://blog.kuzzle.io/communicate-through-ble-using-flutter  (change for Android)
 * https://juejin.im/post/5b46a6ffe51d45198a2eb221   (Android 蓝牙BLE开发详解)
 * https://www.jianshu.com/p/3a372af38103 (Android BLE 蓝牙开发入门)
 * ----------------------------------------------------------------------------*/

/* ----------------------------------------------------------------------------
 * UUID Define  
 * Alert: These definition value must be same as "ble.dart" in the Flutter project 
 * name below Ser = Service, Chr = Characteristic 
 * 
 * example uuid
 * characteristicUuid: 00002a6e-0000-1000-8000-00805f9b34fb 
          serviceUuid: 00001809-0000-1000-8000-00805f9b34fb
             remoteId: 6DF7B035-9A74-F291-67A9-CF8113AA482E 
 * ----------------------------------------------------------------------------*/
var deviceName = 'HomeICU';

var endUUID = '-0000-1000-8000-00805f9b34fb';

var heartRateSerUUID = Guid('0000180D' + endUUID);
var heartRateChrUUID = Guid('00002A37' + endUUID);

var sPO2SerUUID = Guid('00001822' + endUUID);
var sPO2ChrUUID = Guid('00002A5E' + endUUID);

var dataStreamSerUUID = Guid('00001122' + endUUID);
var ecgStreamChrUUID = Guid('00001424' + endUUID);
var ppgStreamChrUUID = Guid('00001425' + endUUID);

var tempSerUUID = Guid('00001809' + endUUID);
var tempChrUUID = Guid('00002a6e' + endUUID);

var batterySerUUID = Guid('0000180F' + endUUID);
var batteryChrUUID = Guid('00002a19' + endUUID);

var hrvSerUUID = Guid("cd5c7491-4448-7db8-ae4c-d1da8cba36d0");
var hrvChrUUID = Guid("01bfa86f-970f-8d96-d44d-9023c47faddc");
var histChrUUID = Guid("01bf1525-970f-8d96-d44d-9023c47faddc");

FlutterBlue flutterBlue; // mobile app
StreamSubscription<ScanResult> scanSubscription;
BluetoothDevice bleDevice; // esp32 board device

var heartRate2 = new List<int>();
var battery2 = new List<int>();
var spo2 = new List<int>();
var temp2 = new List<int>();
var hist2 = new List<int>();
var hrv2 = new List<int>();
var ecg2 = new List<int>();
var ppg2 = new List<int>();
VitalNumbers currentVital = VitalNumbers();

var characteristicsNumber;
BluetoothCharacteristic chrPPG;
/* ----------------------------------------------------------------------------
 *
 * Phase 1. initialisation and listen to device state
 * 
 * ----------------------------------------------------------------------------*/

void bleInitState() {
  flutterBlue = FlutterBlue.instance;
  flutterBlue.state.listen((state) {
    if (state == BluetoothState.off) {
      print("ble: power OFF, you must turn it on");
      fireEvent(MyEventId.bluetoothOff);

    } else if (state == BluetoothState.on) {
      print("ble: power ON");
      scanForDevices();
    }
  });
}

// Scan and Stop Bluetooth
void scanForDevices() async {
  List<BluetoothDevice> devices = await FlutterBlue.instance.connectedDevices;
  if (devices.length > 0) {
    if (devices[0].name == deviceName) {
      print("ble: device already connected! disconnecting now ...");
      await devices[0].disconnect();
    }
  }

  //just incase ren-entry
  if (scanSubscription == null) {
    print("ble: search homeicu device");
    scanSubscription = flutterBlue.scan(
        withServices: [batterySerUUID],
        timeout: Duration(seconds: 5)).listen((scanResult) async {
      if (scanResult.device.name == deviceName) {
        await flutterBlue.stopScan(); // stop scan
        await scanSubscription.cancel();

        print("ble: found device");

        bleDevice = scanResult.device; // assign bluetooth device

        await bleConnectToDevice();

        bleDevice.state.listen((event) async {
          if (event == BluetoothDeviceState.disconnected) {
            print("ble: device disconnected");
            bleConnectToDevice(); // re-connect device
          } else
            print(event);
        });
      }
    });
  }
}

// when screen is off or switch to non-chart screen, stop ble
void bleStopScan() async {
  print("ble: stop scan");
  if (flutterBlue != null) {
    await flutterBlue.stopScan();
    flutterBlue = null;
  }

  print("ble: cancel subscription");
  if (scanSubscription != null) {
    await scanSubscription.cancel();
    scanSubscription = null;
  }
}

/* ----------------------------------------------------------------------------
 *
 * Phanse 2. connect to device
 * 
 * ----------------------------------------------------------------------------*/
Future bleConnectToDevice() async {
  await bleDevice.connect();

  print("ble: clear cache");
  battery2.clear();
  heartRate2.clear();
  spo2.clear();
  temp2.clear();
  hrv2.clear();
  hist2.clear();
  ecg2.clear();
  ppg2.clear();
  currentVital.clear();

  // discover, connect, and listen the characteristics
  characteristicsNumber = 0;

  await bleDiscoverServices(
      "Battery", batterySerUUID, batteryChrUUID, batteryDataHandler);
  await bleDiscoverServices(
      "HeartRt", heartRateSerUUID, heartRateChrUUID, heartRateDataHandler);
  await bleDiscoverServices(
      "SPO2Lev", sPO2SerUUID, sPO2ChrUUID, sPO2chrDataHandler);
  await bleDiscoverServices(
      "BodyTem", tempSerUUID, tempChrUUID, temperatureDataHandler);
  await bleDiscoverServices("HeartRV", hrvSerUUID, hrvChrUUID, hrvDataHandler);
  await bleDiscoverServices(
      "HistpRt", hrvSerUUID, histChrUUID, histDataHandler);
  await bleDiscoverServices(
      "EcgData", dataStreamSerUUID, ecgStreamChrUUID, ecgStreamDataHandler);
  await bleDiscoverServices(
      "PpgData", dataStreamSerUUID, ppgStreamChrUUID, ppgStreamDataHandler);

  while (true) {
    await Future.delayed(Duration(seconds: 1));
    if (characteristicsNumber == 8) {
      List<int> data = utf8.encode("OK");
      print("ble: found all characteristics");
      chrPPG.write(data);
      break;
    }
  }
}

Future bleDiscoverServices(String msg, Guid serviceUuid,
    Guid characteristicUuid, void Function(List<int>) dataProcessing) async {
  List<BluetoothService> services = await bleDevice.discoverServices();
  BluetoothCharacteristic resultCharacteristic;
  services.forEach((service) {
    //locate service id
    if (service.uuid == serviceUuid) {
      service.characteristics.forEach((characteristic) {
        //locate characteristic id
        if (characteristic.uuid == characteristicUuid) {
          print("ble $msg connected");
          resultCharacteristic = characteristic;
          resultCharacteristic.setNotifyValue(true);
          resultCharacteristic.value.listen(dataProcessing);
          characteristicsNumber++;

          if (characteristic.uuid == ppgStreamChrUUID) chrPPG = characteristic;
        }
      });
    }
  });
  if (resultCharacteristic == null) print("ble: error! $msg: not Found.");
}
/* ----------------------------------------------------------------------------
 *
 * callback functions for data processing
 * 
 * ----------------------------------------------------------------------------*/

bool dataValid(List<int> data, List<int> data2, String printInfo) {
  if (data.length == 0) return false; //received zero data

  bool isEqual = listEquals<int>(data, data2);
  if (isEqual) {
    return false; //receive same data again, ignore it
  } else {
    data2.clear();
    data2.addAll(data);

    print(printInfo + ": $data");
    return true;
  }
}

void sendToScreen() {
  if (numStreamController != null) {
    if (numStreamController.hasListener)
      numStreamController.sink.add(currentVital);
  }
}

void batteryDataHandler(List<int> data) {
  if (dataValid(data, battery2, "battery")) {
    currentVital.battery = data.last.toInt();
    sendToScreen();
  }
}

/* ESP32 code
heart_rate_pack[0]  = (uint8_t) ecg_heart_rate; 
heart_rate_pack[1]  = ppg_heart_rate; 
heart_rate_pack[2]  = ecg_lead_off; 
*/
void heartRateDataHandler(List<int> data) {
  if (dataValid(data, heartRate2, "heart rate")) {
    currentVital.heartRate = data[0].toInt();
    sendToScreen();
  }
}

void sPO2chrDataHandler(List<int> data) {
  if (dataValid(data, spo2, "spo2")) {
    int t = data.last.toInt();
    if ((t < 0) && (t > 100)) t = 0;
    currentVital.sPo2 = t;

    sendToScreen();
  }
}

void temperatureDataHandler(List<int> data) {
  double t;

  // esp32 float is 32 bits, app float is 64-bit double
  if (dataValid(data, temp2, "temperature")) {
    //convert fout-byte list into double float
    ByteBuffer buffer = new Int8List.fromList(data).buffer;
    ByteData byteData = new ByteData.view(buffer);
    t = byteData.getInt16(0, Endian.little) / 10;

    print("body temperature = : ${t.toStringAsFixed(3)}");

    if ((t < 0) && (t > 50)) t = 0;
    currentVital.temperature = t;

    sendToScreen();
  }
}

void hrvDataHandler(List<int> data) {
  if (dataValid(data, hrv2, "hrv")) {
    // process data here here
    //FIXME
  }
}

void histDataHandler(List<int> data) {
  if (dataValid(data, hist2, "hist")) {
    // process data here here
    //FIXME
  }
}



//these defines must be same as firmware project
const ecg_tx_size = 10;
const ppg_tx_size = 5;

void ecgStreamDataHandler(List<int> data) {
  if ((data != null) && (ecgStreamController != null)) {
    if (ecgStreamController.hasListener) ecgStreamController.sink.add(data);
  }
}

void ppgStreamDataHandler(List<int> data) {
  if ((data != null) && (ppgStreamController != null)) {
    if (ppgStreamController.hasListener) ppgStreamController.sink.add(data);
  }
}
/*
BLE Relationship in different layers
Link layer:    master  - slave
GAP layer:     central - peripheral
GATT layer:    client  - server 

GAP Central/Peripheral - has to do with establishing a link.  A Peripheral can advertise, 
to let other devices know that it's there, but it is only a Central that can actually send 
a connection request to estalish a connection. When a link has been established, the Central 
is sometimes called a Master, while the Peripheral could be called a Slave. 

GATT Server and Client - the Server is the device that contains data, that the Client can read.

Bluetooth 4.0, Bluetooth 4.1 and Bluetooth 4.2

Bluetooth 4.0 - low energy use. 
Bluetooth 4.1 - IoT use (Internet of Things),devices can act as both hub and end point 
simultaneously. It allows the host device to be cut out of the equation and for 
peripherals to communicate independently.

The iPhone 5      : Bluetooth 4.0
Raspberry Pi 3B+  : Bluetooth 4.1
*/
