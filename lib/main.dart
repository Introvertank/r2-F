import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Removed unused cardText list from here.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Passing cardText to MyHomePage
      home: MyHomePage(title: 'Kalkulator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  // Removed `static` from cardText and made it final.
  final List<String> cardText = [
    "C",
    "()",
    "%",
    "/",
    "7",
    "8",
    "9",
    "*",
    "4",
    "5",
    "6",
    "-",
    "1",
    "2",
    "3",
    "+",
    "+/-",
    "0",
    ".",
    "="
  ];

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //variables for input and output
  String _input = '';
  String _output = '0';
  List<String> history = []; //history list

  // To track button animation states
  List<bool> buttonPressed = List<bool>.filled(20, false);

  void _onButtonPressed(String value, int index) {
    //button handling logic
    setState(() {
      if (value == 'C') {
        //clear everything
        _input = '';
        _output = '0';
      } else if (value == "=") {
        //evaluate expression
        try {
          final String expression =
              _input.replaceAll('x', '*'); //replacing * with x
          _evaluateExpression();
          history.add('$_input=$_output');
          _input = '';
        } catch (e) {
          _output = "error";
        }
      } else if (value == "()") {
        // Handle parentheses (toggle opening/closing parenthesis)
        if (_input.endsWith('(') ||
            _input.isEmpty ||
            _input.endsWith('+') ||
            _input.endsWith('-') ||
            _input.endsWith('*') ||
            _input.endsWith('/')) {
          _input += '('; //opening parenthesis
        } else {
          _input += ')'; //closing parenthesis
        }
      } else if (value == "%") {
        //append percentage symbol
        _input += '%';
      } else if (value == "+/-") {
        if (_input.isNotEmpty) {
          // Use regex to find the last number in the input string
          RegExp lastNumberRegex = RegExp(r'(-?\d+\.?\d*)$');
          Match? match = lastNumberRegex.firstMatch(_input);

          if (match != null) {
            String lastNumber = match.group(0)!;

            // Check if the last number starts with "-"
            if (lastNumber.startsWith("-")) {
              // Remove the "-" from the last number
              _input =
                  _input.substring(0, match.start) + lastNumber.substring(1);
            } else if (lastNumber == '0') {
              _input = '0';
            } else {
              // Add "-" to the last number
              _input = _input.substring(0, match.start) + "-" + lastNumber;
            }
          }
        } else if (_output != '0') {
          // If there's no input, toggle the sign of the last result
          if (_output.startsWith('-')) {
            _output = _output.substring(1); // Remove the negative sign
          } else {
            _output = '-$_output'; // Add the negative sign
          }
        }
      } else {
        //append button value to input
        _input += value;
      }

      // Trigger animation for the pressed button
      buttonPressed[index] = true;
    });

    // Reset the button animation state after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        buttonPressed[index] = false;
      });
    });
  }

  void _evaluateExpression() {
    try {
      // Replace "x" with "*" for multiplication
      String expression = _input.replaceAll('x', '*');

      // Use regex to handle contextual percentage cases
      final regex = RegExp(r'(\d+(\.\d+)?)\s*\+\s*(\d+(\.\d+)?)%');
      expression = expression.replaceAllMapped(regex, (match) {
        // Extract the base number and percentage value
        final base = match.group(1)!;
        final percentage = match.group(3)!;
        return '$base + ($base * $percentage / 100)';
      });

      // Handle standalone percentages like "20%"
      final standaloneRegex = RegExp(r'(\d+(\.\d+)?)%');
      expression = expression.replaceAllMapped(standaloneRegex, (match) {
        final value = match.group(1)!; // Capture the number before '%'
        return '($value / 100)'; // Convert to a fraction
      });

      // Similarly handle cases for -, *, /
      expression = expression.replaceAllMapped(
          RegExp(r'(\d+(\.\d+)?)\s*-\s*(\d+(\.\d+)?)%'), (match) {
        final base = match.group(1)!;
        final percentage = match.group(3)!;
        return '$base - ($base * $percentage / 100)';
      });

      expression = expression.replaceAllMapped(
          RegExp(r'(\d+(\.\d+)?)\s*\*\s*(\d+(\.\d+)?)%'), (match) {
        final base = match.group(1)!;
        final percentage = match.group(3)!;
        return '$base * ($percentage / 100)';
      });

      expression = expression.replaceAllMapped(
          RegExp(r'(\d+(\.\d+)?)\s*\/\s*(\d+(\.\d+)?)%'), (match) {
        final base = match.group(1)!;
        final percentage = match.group(3)!;
        return '$base / ($percentage / 100)';
      });

      // Parse and evaluate the expression using math_expressions
      Parser parser = Parser();
      Expression exp = parser.parse(expression);

      // Create a context model (not used here, but helpful for variables)
      ContextModel contextModel = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, contextModel);

      // Update the output
      _output = result.toString();
    } catch (e) {
      // Handle errors in parsing or evaluation
      _output = "error";
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('History'),
          content: history.isEmpty
              ? Text('No history available.')
              : Container(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(history[index]),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  history.clear(); // Clear the history
                });
                Navigator.of(context).pop();
              },
              child: Text('Clear History'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Display Section with Backspace Button
          Container(
            height: 320,
            width: double.infinity,
            color: Colors.black,
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Input and Output Display
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Input Text
                      Text(
                        _input,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 30,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Output Text

                      Text(
                        _output,
                        style: TextStyle(
                          color:
                              Color.fromARGB(255, 0, 159, 53).withOpacity(0.8),
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(), // Empty space on the left for balance
                    InkWell(
                      onTap: () {
                        setState(() {
                          // Backspace Logic
                          if (_input.isNotEmpty) {
                            _input = _input.substring(0, _input.length - 1);
                          }
                        });
                      },
                      child: Icon(
                        Icons.backspace,
                        color: Colors.grey.withOpacity(0.5),
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Buttons Grid Section
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 6.0, right: 6.0),
              color: Colors.black,
              child: GridView.builder(
                physics: ClampingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 6,
                ),
                itemCount: widget.cardText.length, // Button labels count
                itemBuilder: (context, index) {
                  List<Color> buttonColors = [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.1),
                    Colors.orangeAccent.withOpacity(0.7),
                  ];
                  List<Color> textColors = [
                    Colors.redAccent,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white,
                  ];
                  return InkWell(
                      // onTap: () => _onButtonPressed(widget.cardText[index]),
                      onTap: () {
                        setState(() {
                          _onButtonPressed(widget.cardText[index], index);
                        });
                        // Reset the button animation state after a short delay
                        Future.delayed(const Duration(milliseconds: 200), () {
                          setState(() {
                            buttonPressed[index] = false; // Reset the state
                          });
                        });
                      },
                      child: AnimatedScale(
                        scale: buttonPressed[index] ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeInOut,
                        child: Card(
                          // color: Colors.grey.withOpacity(0.1),
                          color: buttonColors[index],

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),

                          child: Center(
                              child: Text(
                            widget.cardText[index], // Button label
                            style: TextStyle(
                              color: textColors[index],
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ),
                      ));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Display Section
//           Container(
//             height: 320,
//             width: double.infinity,
//             color: Colors.black,
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // History Icon
//                     IconButton(
//                       icon: Icon(Icons.history, color: Colors.white, size: 30),
//                       onPressed: _showHistoryDialog, // Show history dialog
//                     ),
//                     // Backspace Icon
//                     IconButton(
//                       icon: Icon(Icons.backspace, color: Colors.white, size: 30),
//                       onPressed: () {
//                         setState(() {
//                           if (_input.isNotEmpty) {
//                             _input = _input.substring(0, _input.length - 1);
//                           }
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//                 // Input and Output Display
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       // Input Text
//                       Text(
//                         _input,
//                         style: TextStyle(color: Colors.grey, fontSize: 30),
//                       ),
//                       // Output Text
//                       Text(
//                         _output,
//                         style: TextStyle(
//                           color: Color.fromARGB(255, 0, 159, 53),
//                           fontSize: 50,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Buttons Grid Section
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.all(6.0),
//               color: Colors.black,
//               child: GridView.builder(
//                 physics: ClampingScrollPhysics(),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 4,
//                   mainAxisSpacing: 10,
//                   crossAxisSpacing: 6,
//                 ),
//                 itemCount: buttonLabels.length,
//                 itemBuilder: (context, index) {
//                   return InkWell(
//                     onTap: () => _onButtonPressed(buttonLabels[index],index),
//                     child: Card(
//                       color: Colors.grey.withOpacity(0.1),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       child: Center(
//                         child: Text(
//                           buttonLabels[index],
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 25,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // List of calculator button labels
// const List<String> buttonLabels = [
//   'C',
//   '%',
//   '/',
//   'x',
//   '7',
//   '8',
//   '9',
//   '-',
//   '4',
//   '5',
//   '6',
//   '+',
//   '1',
//   '2',
//   '3',
//   '=',
//   '+/-',
//   '0',
//   '.'
// ];
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Display Section with Backspace Button
//           Container(
//             height: 320,
//             width: double.infinity,
//             color: Colors.black,
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   //history icon
//                   IconButton(
//                       icon: Icon(Icons.history, color: Colors.white, size: 30),
//                       onPressed: _showHistoryDialog, // Show history dialog
//                     ),
//                     //backspace button
//                     IconButton(
//                       icon: Icon(Icons.backspace, color: Colors.white, size: 30),
//                       onPressed: () {
//                         setState(() {
//                           if (_input.isNotEmpty) {
//                             _input = _input.substring(0, _input.length - 1);
//                           }
//                         });
//                       },
//                     )
//                 ],),
//                 // Input and Output Display
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Input Text
//                       Text(
//                         _input,
//                         style: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 30,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       // Output Text

//                       Text(
//                         _output,
//                         style: TextStyle(
//                           color:
//                               Color.fromARGB(255, 0, 159, 53).withOpacity(0.8),
//                           fontSize: 50,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SizedBox(), // Empty space on the left for balance
//                     InkWell(
//                       onTap: () {
//                         setState(() {
//                           // Backspace Logic
//                           if (_input.isNotEmpty) {
//                             _input = _input.substring(0, _input.length - 1);
//                           }
//                         });
//                       },
                      
//                       // child: Icon(
//                       //   Icons.backspace,
//                       //   color: Colors.grey.withOpacity(0.5),
//                       //   size: 30,
//                       // ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Buttons Grid Section
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.only(left: 6.0, right: 6.0),
//               color: Colors.black,
//               child: GridView.builder(
//                 physics: ClampingScrollPhysics(),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 4,
//                   mainAxisSpacing: 10,
//                   crossAxisSpacing: 6,
//                 ),
//                 itemCount: widget.cardText.length, // Button labels count
//                 itemBuilder: (context, index) {
//                   List<Color> buttonColors = [
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.grey.withOpacity(0.1),
//                     Colors.orangeAccent.withOpacity(0.7),
//                   ];
//                   List<Color> textColors = [
//                     Colors.redAccent,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                     Colors.white,
//                   ];
//                   return InkWell(
//                       // onTap: () => _onButtonPressed(widget.cardText[index]),
//                       onTap: () {
//                         setState(() {
//                           _onButtonPressed(widget.cardText[index], index);
//                         });
//                         // Reset the button animation state after a short delay
//                         Future.delayed(const Duration(milliseconds: 300), () {
//                           setState(() {
//                             buttonPressed[index] = false; // Reset the state
//                           });
//                         });
//                       },
//                       child: AnimatedScale(
//                         scale: buttonPressed[index] ? 1.1 : 1.0,
//                         duration: const Duration(milliseconds: 150),
//                         curve: Curves.easeInOut,
//                         child: Card(
//                           // color: Colors.grey.withOpacity(0.1),
//                           color: buttonColors[index],

//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(50),
//                           ),

//                           child: Center(
//                               child: Text(
//                             widget.cardText[index], // Button label
//                             style: TextStyle(
//                               color: textColors[index],
//                               fontSize: 25,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           )),
//                         ),
//                       ));
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
