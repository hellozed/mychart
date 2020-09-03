import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert'; //utf8.encode
//import 'dart:io'; //stdout.write();

import 'dart:typed_data'; //for data formatting
import '../google_chart/live_line_chart.dart';
/*
  FIXME:
  Stream<List<int>> ecgStream; 
*/

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
BluetoothDevice bleDevice; // esp32 board device

var heartRate2 = new List<int>();
var battery2 = new List<int>();
var spo2 = new List<int>();
var temp2 = new List<int>();
var hist2 = new List<int>();
var hrv2 = new List<int>();
var ecg2 = new List<int>();
var ppg2 = new List<int>();

/* ----------------------------------------------------------------------------
 *
 * Phase 1. initialisation and listen to device state
 * 
 * ----------------------------------------------------------------------------*/
void bleInitState() {
  flutterBlue = FlutterBlue.instance;
  flutterBlue.state.listen((state) {
    if (state == BluetoothState.off) {
      print(
          "ble: power OFF, you must turn it on"); // notice user to turn on bluetooth.
    } else if (state == BluetoothState.on) {
      print("ble: power ON");
      scanForDevices();
    }
  });
}

// Scan and Stop Bluetooth
void scanForDevices() async {
  StreamSubscription<ScanResult> scanSubscription;

  List<BluetoothDevice> devices = await FlutterBlue.instance.connectedDevices;
  if (devices.length > 0) {
    if (devices[0].name == deviceName) {
      print("ble: device already connected! disconnecting now ...");
      await devices[0].disconnect();
    }
  }

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

/* ----------------------------------------------------------------------------
 *
 * Phanse 2. connect to device
 * 
 * ----------------------------------------------------------------------------*/
var characteristicsNumber = 0;
BluetoothCharacteristic chrPPG;
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

  // discover, connect, and listen the characteristics

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

bool dataValid(List<int> data, List<int> previousData, String printInfo) {
  if (data.length == 0) return false; //received zero data

  bool isEqual = listEquals<int>(data, previousData);
  if (isEqual) return false; //receive same data again, ignore it

  previousData.clear();
  previousData.addAll(data);

  print(printInfo + ": $data");
  return true;
}

void batteryDataHandler(List<int> data) {
  if (dataValid(data, battery2, "battery")) {
    // process data here here
  }
}

void heartRateDataHandler(List<int> data) {
  if (dataValid(data, heartRate2, "heart rate")) {
    // process data here here
  }
}

void sPO2chrDataHandler(List<int> data) {
  if (dataValid(data, spo2, "spo2")) {
    // process data here here
  }
}

void temperatureDataHandler(List<int> data) {
  double bodyTemperature;

  // esp32 float is 32 bits, app float is 64-bit double

  if (dataValid(data, temp2, "temperature")) {
    //convert fout-byte list into double float
    ByteBuffer buffer = new Int8List.fromList(data).buffer;
    ByteData byteData = new ByteData.view(buffer);
    bodyTemperature = byteData.getFloat32(0, Endian.little);
    //print("body temperature = : ${bodyTemperature.toStringAsFixed(3)}");
  }
}

void hrvDataHandler(List<int> data) {
  if (dataValid(data, hrv2, "hrv")) {
    // process data here here
  }
}

void histDataHandler(List<int> data) {
  if (dataValid(data, hist2, "hist")) {
    // process data here here
  }
}

void updateGraph(List<int> data, List<int> data2, int len, String printInfo,
    List<ChartData> chartData) {
  if (data.length == 0) return; //received zero data

  if (data.length < len) {
    //data len = pack size + 1 serial number
    print("len=${data.length}, byte missing");
    return;
  }

  bool isEqual = listEquals<int>(data, data2);
  if (isEqual) return; //receive same data again, ignore it

  data2.clear();
  data2.addAll(data);

  //remove the last two bytes of serial number, and convert to int16
  var data8 = new Uint8List.fromList(data);
  var data16 = new List.from(data8.buffer.asInt16List(), growable: true);
  data16.removeLast();
  //print("ppg16+: $data16"); //with serial number

  data16.forEach((element) {
    // remove the first data point on the left
    chartData.removeAt(0);

    // each x decrese by 1 to shift the chart left
    chartData.forEach((element2) {
      element2.x--;
    });
    // add one time at the end of the right side
    chartData.add(ChartData(liveChartData.length, element));
  });
  return;
}

//these must be same as firmware project
const ecg_tx_size = 10; //
const ppg_tx_size = 10; //

void ecgStreamDataHandler(List<int> data) {
  //updateGraph(data, ecg2, ecg_tx_size,"ecg", liveChartData);
}
void ppgStreamDataHandler(List<int> data) {
  updateGraph(data, ppg2, ppg_tx_size * 2 + 2, "ppg", liveChartData);
}
/* ----------------------------------------------------------------------------
 * Phase 3.
 * 
 * 
 * ----------------------------------------------------------------------------*/
/*
StreamBuilder<List<int>>(stream: listStream,  //here we're using our char's value
              initialData: [],
              builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
    if (snapshot.connectionState == ConnectionState.active) {
      //In this method we'll interpret received data
      interpretReceivedData(currentValue);
      return Center(child: Text('We are finding the data..'));
    } else {
        return SizedBox();
    }
  },
);

//Interpret received data from the device
//SEE WHAT TYPE OF COMMANDS YOUR DEVICE GIVES YOU & WHAT IT MEANS

void interpretReceivedData(String data) async {
  if (data == "abt_HANDS_SHAKE") {
    //Do something here or send next command to device
    sendTransparentData('Hello');
  } else {
    print("Determine what to do with $data");
  }
}
/* ----------------------------------------------------------------------------
 * Phase 4. 
 * 
 * Send commands to the device
 * ----------------------------------------------------------------------------*/


In Async Code
await Future.delayed(Duration(seconds: 1));

In Sync Code
import 'dart:io';
sleep(Duration(seconds:1));
*/

/*
BLE Relationship in different layers
Link layer:    master  - slave
GAP layer:     central - peripheral
GATT layer:    client  - server 

GAP Central/Peripheral - has to do with establishing a link.  A Peripheral can advertise, 
to let other devices know that it's there, but it is only a Central that can actually send 
a connection request to estalish a connection. When a link has been established, the Central
 is sometimes called a Master, while the Peripheral could be called a Slave. In addition to
the above roles, the Core Specification also defines the roles of an Observer and a Broadcaster. 
These are basically just non-connecting variants of the Central and Peripheral, in other 
words devices that just listens for advertisement packages (and possibly send scan responses) 
or just sends such packages, without ever entering a connection.

GATT Server and Client - the Server is the device that contains data, that the Client can read.

However, there is no connection between these roles. Even though it is most common for a Peripheral
to be a Server and a Central to be a Client, it is perfectly possible to have a Peripheral that 
is only a Client, or a Central that is both a Server and a Client. 

Bluetooth specification mandates that all Bluetooth Smart devices shall have one and only one GATT 
server. Meaning that you cannot have no server, or many servers (if you act as a central connected 
to many peripherals). All GATT clients accessing the GATT Server are able to find the same services
and characteristics.  

Bluetooth 4.0, Bluetooth 4.1 and Bluetooth 4.2

Bluetooth 4.0 has new hardware design and software design for low energy use. Bluetooth 4.1 is to drive the ‘Internet of Things’ (Io, namely the thousands of smart, web connected devices. Bluetooth 4.1 devices can act as both hub and end point simultaneously. This is hugely significant because it allows the host device to be cut out of the equation and for peripherals to communicate independently.

Using a device that has a newer version would not work unless it is backwards compatible; for instance, if a device you are trying to connect was using Bluetooth 4.2 and needed Data Length Extension (it may, not entirely sure) then it would not work with the iPhone because that is hardware not software limited [2].
The iPhone 5      : Bluetooth 4.0
Raspberry Pi 3B+  : Bluetooth 4.1


bluetoothctl
and enter
Code: Select all
discoverable on
*/
