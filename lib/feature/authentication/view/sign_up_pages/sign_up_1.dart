import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/model/sign_up_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';

class SignUpPage1 extends StatefulWidget {
  const SignUpPage1({super.key});

  @override
  State<SignUpPage1> createState() => _SignUpPage1State();
}

class _SignUpPage1State extends State<SignUpPage1> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  //text editing controllers
  final addressController = TextEditingController();

  final cityController = TextEditingController();

  final instructionController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 18.0),
              child: Text('step 2 of 2'),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 17.0),
                        child: Text(
                          'Pick up address',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      //username textfield
                      MyTextField(
                        controller: addressController,
                        hinText: 'Address',
                        obscureText: false,
                        isPassword: false,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      //password textfield
                      MyTextField(
                        controller: cityController,
                        hinText: 'City',
                        obscureText: false,
                        isPassword: false,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      MyTextField(
                        controller: instructionController,
                        hinText: 'Pick up and delivery instructions',
                        obscureText: false,
                        isPassword: false,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 350,
                  ),
                  Column(
                    children: [
                      //sign in button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25.0),
                              child: GradientButton(
                                isLoading: loading,
                                onPressed: () async {
                                  setState(() {
                                    loading = true;
                                  });

                                  await SignUpModel.getInputAddress(
                                    context,
                                    addressController.text, //street
                                    cityController.text, //city
                                    instructionController.text, //postalCode
                                    'Nigeria', //Country
                                    _scaffoldKey,
                                  );

                                  setState(() {
                                    loading = false;
                                  });
                                },
                                text: 'Complete',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 50.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
