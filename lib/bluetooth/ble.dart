import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';



/*
  FIXME:
  1. ble device could not be found when hot load again the app
  current fix: press the "reset" of the device, then "hot load" the appl.
  electrocardiography
  
  2. Stream<List<int>> ecgStream; 
  
  3. characteristicUuid: 00002a6e-0000-1000-8000-00805f9b34fb 
  serviceUuid: 00001809-0000-1000-8000-00805f9b34fb
  remoteId: 6DF7B035-9A74-F291-67A9-CF8113AA482E 
  how to change remoteId
*/

/* ----------------------------------------------------------------------------
 * Credit:   
 * 
 * The code here is learned from the link below.
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
 * ----------------------------------------------------------------------------*/
var deviceName          =  'HomeICU';  

var endUUID             = '-0000-1000-8000-00805f9b34fb';

var heartRateSerUUID    = Guid('0000180D'+endUUID);
var heartRateChrUUID    = Guid('00002A37'+endUUID);

var sPO2SerUUID         = Guid('00001822'+endUUID);
var sPO2ChrUUID         = Guid('00002A5E'+endUUID);

var dataStreamSerUUID   = Guid('00001122'+endUUID);
var dataStreamChrUUID   = Guid('00001424'+endUUID);

var tempSerUUID         = Guid('00001809'+endUUID);
var tempChrUUID         = Guid('00002a6e'+endUUID);

var batterySerUUID      = Guid('0000180F'+endUUID);
var batteryChrUUID      = Guid('00002a19'+endUUID);

var hrvSerUUID          = Guid("cd5c7491-4448-7db8-ae4c-d1da8cba36d0");
var hrvChrUUID          = Guid("01bfa86f-970f-8d96-d44d-9023c47faddc");
var histChrUUID         = Guid("01bf1525-970f-8d96-d44d-9023c47faddc");

FlutterBlue             flutterBlue;
BluetoothDevice         bleDevice;            // esp32 board device

int batteryPercent;
int heartRate;
int sPO2Percent;

int ecgStream;
int bodyTemperature;
int heartRateVariability;
int respirationRate;
/* ----------------------------------------------------------------------------
 *
 * Phase 1. initialisation and listen to device state
 * 
 * ----------------------------------------------------------------------------*/
void bleInitState() {
  flutterBlue = FlutterBlue.instance;
  flutterBlue.state.listen((state) {
    if (state == BluetoothState.off){
      print("ble power OFF, you must turn it on");  //Alert user to turn on bluetooth.
    } else if (state == BluetoothState.on) {
      print("ble power ON");
      scanForDevices(); 
    }
  });
}

// Scan and Stop Bluetooth
void scanForDevices() async {  
  StreamSubscription<ScanResult>   scanSubscription;

  scanSubscription = flutterBlue.scan(withServices:[batterySerUUID], timeout: Duration(seconds: 5))
  .listen((scanResult) async {
    if (scanResult.device.name == deviceName) {
      await flutterBlue.stopScan();         // stop scan
      await scanSubscription.cancel();

      print("found device");
      bleDevice = scanResult.device;        // assign bluetooth device
      await bleConnectToDevice();
      
      bleDevice.state.listen((event) async{ 
        if (event==BluetoothDeviceState.disconnected){
            print("Ble disconnect now!");
            bleConnectToDevice();           // re-connect device
        }
        else 
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
Future bleConnectToDevice() async {

  await bleDevice.connect(); 

  // discover, connect, and listen the characteristics
  await bleDiscoverServices("Battery",  batterySerUUID,   batteryChrUUID,     batteryData);
  await bleDiscoverServices("HeartRt",  heartRateSerUUID, heartRateChrUUID,   heartRateData);
  await bleDiscoverServices("SPO2Lev",  sPO2SerUUID,      sPO2ChrUUID,        sPO2chrData);
  await bleDiscoverServices("ECGData",  dataStreamSerUUID,dataStreamChrUUID,  dataStreamData);
  await bleDiscoverServices("BodyTem",  tempSerUUID,      tempChrUUID,        temperatureData);
  await bleDiscoverServices("HeartRV",  hrvSerUUID,       hrvChrUUID,         hrvData);
  await bleDiscoverServices("HistpRt",  hrvSerUUID,       histChrUUID,        histData);
}

Future bleDiscoverServices( String msg, Guid serviceUuid, 
                            Guid characteristicUuid, 
                            void Function (List<int>)dataProcessing
                          ) async 
{  
  BluetoothCharacteristic result;
  List<BluetoothService> services = await bleDevice.discoverServices();
  services.forEach((service) {
    if (service.uuid == serviceUuid) {
      service.characteristics.forEach((characteristic){
        if (characteristic.uuid == characteristicUuid){
          print("ble $msg connected");
          result = characteristic;
          result.setNotifyValue(true);
          result.value.listen(dataProcessing);
        } 
      });
    }
  });
  if (result==null) print("$msg: serverice/characteristic not Found!");
}
/* ----------------------------------------------------------------------------
 *
 * callback functions for data processing
 * 
 * ----------------------------------------------------------------------------*/
void batteryData    (List<int> data) {  
  print(data);  //batteryPercent  = data;
}

void heartRateData  (List<int> data) {  
  print(data);  //heartRate       = data;
}

void sPO2chrData    (List<int> data) {  
  print(data);  //sPO2Percent     = data;
}

void dataStreamData (List<int> data) {  
  print(data);  //batteryPercent  = data;
}

void temperatureData(List<int> data) {  
  print(data);  //bodyTemperature  = data;
}
void hrvData        (List<int> data) {  
  print(data);  //heartRateVariability = data;
}
void histData       (List<int> data) {  
  print(data);  //respirationRate  = data;
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
void sendTransparentData(String dataString) async {
  
  List<int> data = utf8.encode(dataString);     //Encoding the string
  
  if (bleDeviceState == BluetoothDeviceState.connected){
  await chr.write(data);
//await chr.write(_getRandomBytes(), withoutResponse: true);
//await chr.write([0x12, 0x34])
  }
}

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