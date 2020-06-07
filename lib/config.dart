/* ----------------------------------------------------------------------------
 the app preference configuration which are stored in the phone
 
 There are three types of data need be stored locally.

 1. App configuration such as themes, name, bluetooth, remote server, password, etc.
    These informations are stored in shared_preference.

 2. Continual measurement data:
    High frequncey measurement, such as ECG, SPO₂, etc.
    Low frequncey measureent, such as blood pressure, body temperature, heart rate, 
    respiration rate and motion occurrence and intensity.
    These data are stored as JSON file.

 Pending:
    Need implement code for store large JSON data.

   Reference: 
   https://medium.com/flutter-community/a-deep-dive-into-flutter-textfields-f0e676aaab7a 
   https://medium.com/flutterdevs/using-sharedpreferences-in-flutter-251755f07127
   https://dev.to/thepythongeeks/step-by-step-to-store-data-locally-in-flutter-1mc9 
   https://medium.com/flutter/some-options-for-deserializing-json-with-flutter-7481325a4450

 * ----------------------------------------------------------------------------*/
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


String configName;
String configEmail;

/*
// bluetooth 
String bleId;

// remote server 
String serverDomain;
String serverUser;
String serverPassword;
*/
class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}


class _ConfigPageState extends State<ConfigPage> {
  @override
  void initState() {
    super.initState();
    // load config and refresh the page after completed
    configLoad();
  }

  Future configSave() async{
    SharedPreferences prefs =  await SharedPreferences.getInstance();
    print('config saved');
    await prefs.setString('name', configName);
    await prefs.setString('email', configEmail);
  }

  Future configLoad() async{
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('name')){
        configName = prefs.getString('name');
        configEmail = prefs.getString('email');
      }
      else{
        print('init settings');
        configName = 'x';
        configEmail = 'y';
      }
      print('load config and refresh page');
      if (this.mounted){
        setState(() {});
      }
      else
        print("error: update before mounted.");
  }

  void _saveButton() async {
    configSave();  //save the configuration 
    setState(() {
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.,
            children: <Widget>[
              Text('Your name:',),
              
              Expanded(child: TextField(
                //textAlign: TextAlign.center,
                decoration: InputDecoration(
                  helperText: "Please input above",
                  hintText: "$configName",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.input),
                  ),
                //expands: true,
                onChanged: (text) {
                  configName = text;
                  print('new name = $configName');
                }
              ),
              ),
              
              /*

              Text('Email:',),
              TextField(
                //textAlign: TextAlign.center,
                decoration: InputDecoration(
                  helperText: "Please input above",
                  hintText: "$configEmail",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.input),
                ),
                onChanged: (text) {
                  configEmail = text;
                  print('new email = $configEmail');
                }
              ),
              
*/
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  OutlineButton(
                    onPressed: () => _saveButton(), child: Text('Save')),
                ],
              ),
            ],
          ),
        ),
    );
  }
}