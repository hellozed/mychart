# mychart

A new Flutter project for HomeICU base station. 

1. It supports iPhone, iPad, and Android phone.
2. Communicate with HomeICU sensor through BLE (bluetooth low energy).
3. Display vital signs measurement and ECG chart.
4. Store data in cloud and enable doctor monitor Covid-19 patient's recover.

# Library

The customized code library/packages are listed in "pubspec.yaml" and can be installed from the command line "flutter packages get", and VSCode can install them automatically by extensions, no need run that command.


## fl_chart: ^0.9.4
## flutter_blue: ^0.7.2
FlutterBlue is a bluetooth plugin for Flutter, a mobile SDK to help developers build modern apps for iOS and Android. [Link](https://pub.dev/packages/flutter_blue)

## charts_flutter: ^0.9.0



# Getting Started with Flutter

## Flutter Install: [link](https://flutter.dev/docs/get-started/install/macos)


echo $SHELL
open $HOME/.zshrc
    add the line below:
        export PATH="$PATH:/Users/a123/Documents/flutter/bin"
source ~/.zshrc
flutter doctor

flutter create my_app
cd my_app 
flutter run

Notes: Do not delete .git from flutter installation folder.

# Tools
Install VS Code and extensions: "Awesome flutter Snippets", "Dart", and "Material Icon Theme".

Online tools for generating code for widget:
https://flutterstudio.app

## How to run the code
The program entry point is "lib/main.dart".
Connect a phone to computer by USB cable
In terminal, type "flutter run" to run the code.
type "hot reload" (press "r" in the console where you ran "flutter run",
Or, "Command+Shift+P"in the VS Code terminal.

## Flutter Help

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials, samples, guidance on mobile development, and a full API reference.
