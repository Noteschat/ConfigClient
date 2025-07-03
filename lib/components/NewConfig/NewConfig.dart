import 'dart:convert';

import 'package:configclient/dtos/Config.dart';
import 'package:configclient/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewConfigView extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final messageController = TextEditingController();
  
  final String host;

  NewConfigView({super.key, required this.host});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: const Text("Start a new Chat"),
      ),
      body: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (value) {
                        if(value == null || value.isEmpty){
                          return "Enter a name...";
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      controller: modelController,
                      decoration: const InputDecoration(labelText: "Model"),
                      validator: (value) {
                        if(value == null || value.isEmpty){
                          return "Enter a model...";
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextFormField(
                      controller: messageController,
                      decoration: const InputDecoration(labelText: "Message"),
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      validator: (value) {
                        if(value == null || value.isEmpty){
                          return "Enter a message...";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  try {
                    var res = await http.post(
                      Uri.parse("http://$host/api/ollamaconfig/config"),
                      headers: headers,
                      body: jsonEncode({
                        "name": nameController.text,
                        "model": modelController.text,
                        "message": messageController.text
                      })
                    );
                    if(res.statusCode != 200) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Creating Config Failed"),
                            content: Text("It seems like we couldn't create the config. Please try again later."),
                            actions: [
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("Ok")
                              )
                            ],
                          );
                        }
                      );
                      return;
                    }
                    var newId = jsonDecode(res.body)["id"];
                    Navigator.of(context).pop(
                      AllConfig(id: newId, name: nameController.text)
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Creating Config Failed"),
                          content: Text("It seems like we couldn't create the config. Please contact your administrator."),
                          actions: [
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Ok")
                            )
                          ],
                        );
                      }
                    );
                  }
                },
                child: const Text("Create Config"),
              ),
            )
          ]
        )
      )
    );
  }
}