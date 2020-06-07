
import 'package:flutter_blue/flutter_blue.dart';
//import 'bluetooth_widget.dart';

/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
            
/*
At Link layer: master - slave relationship
At GAP layer: central - peripheral relationship
At GATT layer: client - server relationship

GAP Central/Peripheral - has to do with establishing a link.  A Peripheral can advertise, to let other devices know that it's there, but it is only a Central that can actually send a connection request to estalish a connection. When a link has been established, the Central is sometimes called a Master, while the Peripheral could be called a Slave. In addition to the above roles, the Core Specification also defines the roles of an Observer and a Broadcaster. These are basically just non-connecting variants of the Central and Peripheral, in other words devices that just listens for advertisement packages (and possibly send scan responses) or just sends such packages, without ever entering a connection.

GATT Server and Client - the Server is the device that contains data, that the Client can read.

However, there is no connection between these roles. Even though it is most common for a Peripheral to be a Server and a Central to be a Client, it is perfectly possible to have a Peripheral that is only a Client, or a Central that is both a Server and a Client. 

Bluetooth specification mandates that all Bluetooth Smart devices shall have one and only one GATT server. Meaning that you cannot have no server, or many servers (if you act as a central connected to many peripherals). All GATT clients accessing the GATT Server are able to find the same services and characteristics.  

https://github.com/Polidea/FlutterBleLib
FlutterBleLib is obviously deprecated and unmaintained; you almost definitely don't want to use it. The team behind it has shifted gears into writing native libraries, though, so building a MethodChannel abstraction over their native libraries might be a reasonable option.

https://github.com/itavero/flutter-ble-uart
flutter-ble-uart is specific to UART services and is built on top of flutter_blue

https://github.com/pauldemarco/flutter_blue
*/
/* ----------------------------------------------------------------------------
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
var sensorDeviceName = 'iPhone11';

Future bleTest() async{

  if (bleInit == true) return;  

  print('BLE Init.');

  FlutterBlue flutterBlue = FlutterBlue.instance;

  // Start scanning
  print('BLE start scan.');
  await flutterBlue.startScan(timeout: Duration(seconds: 4));

  // Listen to scan results
  flutterBlue.scanResults.listen((results) {
      print('BLE get result.');
      // do something with scan results
      for (ScanResult r in results) {
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
    print('delay');
    await new Future.delayed(const Duration(milliseconds : 100));
  }
 
  if (bleDevice!=null){
    print('BLE connect to : ${bleDevice.name}.');
    
    // Connect to the device
    await bleDevice.connect();

    // Discover services
    List <BluetoothService> services = await bleDevice.discoverServices();
    services.forEach((service) {
      // do something with service
      //print('service uuid: ${service.uuid} ');
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