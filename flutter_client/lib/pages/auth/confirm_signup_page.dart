import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client/cubits/auth/auth_cubit.dart';
import 'package:flutter_client/pages/auth/login_page.dart';
import 'package:flutter_client/services/auth/auth_services.dart';
import 'package:flutter_client/utils/utils.dart';

class ConfirmSignupPage extends StatefulWidget {
  final String email;
  static MaterialPageRoute<dynamic> route({required String email}) =>
      MaterialPageRoute(builder: (context) => ConfirmSignupPage(email: email));
  const ConfirmSignupPage({super.key, required this.email});

  @override
  State<ConfirmSignupPage> createState() => _ConfirmSignupPageState();
}

class _ConfirmSignupPageState extends State<ConfirmSignupPage> {
  late TextEditingController emailController;
  final otpController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final authServices = AuthServices();

  @override
  void initState() {
    emailController = TextEditingController(text: widget.email);
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void confirmSignUp() async {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().confirmSignupUser(
        email: emailController.text.trim(),
        otp: otpController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthConfirmSignupSuccess) {
              showSnackbar(context, state.message);
              Navigator.pushReplacement(context, LoginPage.route());
            } else if (state is AuthError) {
              showSnackbar(context, state.error);
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return Center(child: CircularProgressIndicator.adaptive());
            }
            return Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Confirm Signup",
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    enabled: false,
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "Enter your email",
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.isEmpty &&
                          !value.contains("@")) {
                        return "Email cannot be empty";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: otpController,
                    decoration: InputDecoration(
                      labelText: "OTP",
                      hintText: "Enter the OTP sent to your email",
                    ),
                    validator: (value) {
                      if (value != null && value.isEmpty && value.length != 6) {
                        return "OTP cannot be empty";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      confirmSignUp();
                    },
                    child: Text(
                      "Confirm",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context, LoginPage.route());
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: Theme.of(context).textTheme.titleMedium,
                        children: [
                          TextSpan(
                            text: "Login",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
