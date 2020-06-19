//import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';
//import 'bluetooth_widget.dart';

/* ----------------------------------------------------------------------------
 *  reference websites
 *  
 * ----------------------------------------------------------------------------
 * https://github.com/Polidea/FlutterBleLib
 * https://github.com/itavero/flutter-ble-uart
   specific to UART services and is built on top of flutter_blue
 * https://github.com/pauldemarco/flutter_blue
 * https://s0pub0dev.icopy.site/packages/flutter_blue#-example-tab-
 * https://github.com/Polidea/FlutterBleLib
 * https://github.com/pauldemarco/flutter_blue 
 * https://blog.kuzzle.io/communicate-through-ble-using-flutter  (change for Android)
 * https://juejin.im/post/5b46a6ffe51d45198a2eb221   (Android 蓝牙BLE开发详解)
 * https://www.jianshu.com/p/3a372af38103 (Android BLE 蓝牙开发入门)
 * ----------------------------------------------------------------------------*/

/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
bool bleInit = false;
BluetoothDevice bleDevice;
var sensorCharacteristicUUID = Guid('00002a2b-0000-1000-8000-00805f9b34fb');
var sensorServiceUUID = Guid('00001805-0000-1000-8000-00805f9b34fb');
var sensorDeviceName = 'HomeICU';

Future bleTest() async{

  if (bleInit == true) return;  

  print('BLE Init.');

  FlutterBlue flutterBlue = FlutterBlue.instance;

  // Start scanning
  print('BLE start scan.');
  await flutterBlue.startScan(timeout: Duration(seconds: 5));
 
  // Listen to scan results
  flutterBlue.scanResults.listen((results) {
      print('BLE get result.');
      // do something with scan results
      for (ScanResult r in results) {
          print('BLE ${r.device.id} name ${r.device.name}');
          if (r.device.name==sensorDeviceName){
            print('${r.device.name} found! rssi: ${r.rssi}');
            bleInit = true;
            // Stop scanning
            flutterBlue.stopScan();
            print('BLE stop scan.');
            bleDevice = r.device;
            break;
          }
      }
  });

  while (bleInit ==false){
    //stdout.write('*');  // print out one * witout change to the next line
    print('*');
    await new Future.delayed(const Duration(seconds : 1));
  }
 
  if (bleDevice!=null){
    print('BLE connect to : ${bleDevice.name}.');
    
    // Connect to the device
    await bleDevice.connect();

    // Discover services
    List <BluetoothService> services = await bleDevice.discoverServices();
    services.forEach((service) {
      // do something with service
      print('service uuid: ${service.uuid} ');
      
      if (service.uuid == sensorServiceUUID){
        print('2a2b service found!');

        // Reads all characteristics
        var characteristics = service.characteristics;
        for(BluetoothCharacteristic c in characteristics) {
          //print('characteristic uuid: ${c.uuid} ');
          if ( c.uuid == sensorCharacteristicUUID){
            print('0185 characteristics 0185 found!');

            //Set notifications and listen to changes 
            c.setNotifyValue(true);
            c.value.listen((value) {
            // do something with new value
            print('value = $value');
            });
          }
        }
      }
      //List <int> chs =  c.read();
      //print(value);
      // Writes to a characteristic
      //await c.write([0x12, 0x34])
    });
  }
  else 
    print('BLE null error.');
  // Disconnect from device
  //await bleDevice.disconnect();
}

/*
At Link layer: master - slave relationship
At GAP layer: central - peripheral relationship
At GATT layer: client - server relationship

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



Bluetooth 4.0, Bluetooth 4.1 and Bluetooth 4.2; What's the difference?

Bluetooth 4.0 has new hardware design and software design for low energy use.
The SIG creates two kinds of device at 4.0 including Bluetooth Smart Ready and Smart.
Smart Ready is used at most platform such as smart phone or laptop, could support traditional Bluetooth and Bluetooth 4.0 both.
Bluetooth Smart is only Bluetooth 4.0 device and could not connect with traditional Bluetooth device.

Bluetooth 4.0, its name Bluetooth low energy, means remove some hardware and software capability and redesign the system for low energy device compared to traditional Bluetooth.

Bluetooth 4.1 vs Bluetooth 4.0?
The job of Bluetooth 4.1 is to drive the ‘Internet of Things’ (Io, namely the thousands of smart, web connected devices – from fridges to toothbrushes – that are expected to enter our lives over the next decade.

1. Coexistence

Bluetooth 4.1 eliminates this by coordinating its radio with 4G automatically so there is no overlap and both can perform at their maximum potential. It's about phone Bluetooth spec.

2. Smart connectivity

Rather than carry a fixed timeout period, Bluetooth 4.1 will allow manufacturers to specify the reconnection timeout intervals for their devices. This means devices can better manage their power and that of the device they are paired to by automatically powering up and down based on a bespoke power plan.

3. Improved Data Transfer

Bluetooth 4.1 devices can act as both hub and end point simultaneously. This is hugely significant because it allows the host device to be cut out of the equation and for peripherals to communicate independently.

Bluetooth 4.2, what's new?
Why use BLE 4.2 instead of BLE 4.1? The Bluetooth SIG recommends implementing Bluetooth 4.2 in all new designs and requires the same qualification process as all other Bluetooth designs. Devices using Bluetooth Smart will be backward compatible with Bluetooth 4.0 or 4.1 devices that also implement the low energy features. Devices implementing the (BR/EDR) Core Configuration will be backward compatible to all adopted Bluetooth Core versions beginning with 1.1 that also implement Bluetooth BR/EDR.

It means the upgrade may not just F/W upgrade, hardware may also need to change.

The iPhone 5 is using Bluetooth 4.0 [1].

Using a device that has a newer version would not work unless it is backwards compatible; for instance, if a device you are trying to connect was using Bluetooth 4.2 and needed Data Length Extension (it may, not entirely sure) then it would not work with the iPhone because that is hardware not software limited [2].

IoT Capabilities:

Low-power IP (IPv6/6LoWPAN)
Bluetooth Smart Internet Gateways (GATT)
With BLE 4.2 Bluetooth Smart sensors can transmit data over the internet.

Security:

LE Privacy 1.2
LE Secure Connections
With new, more power efficient and highly secure features, BLE 4.2 provides additional benefits allowing only trusted owners to track device location and confidently pair devices.

Speed:

250% Faster
10x More Capacity
Compared to previous versions, BLE 4.2 enables 250% faster and more reliable over-the-air data transmission and 10x more packet capacity.




bluetoothctl
and enter
Code: Select all

discoverable on

*/