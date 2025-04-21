// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:configclient/login.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:http/http.dart' as http;

String host = "192.168.2.83";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ConfigClient());
}

class ConfigClient extends StatelessWidget {
  const ConfigClient({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Config Client',
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          home: LoginView(
            onLogin: (context) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigSelect() 
                )
              );
            },
            host: host,
          ),
        );
      },
    );
  }
}

class ConfigSelect extends StatefulWidget {
  const ConfigSelect({super.key});

  @override
  State<ConfigSelect> createState() => _ConfigSelectState();
}

class _ConfigSelectState extends State<ConfigSelect> {
  List<AllConfig> configs = [];

  _ConfigSelectState() {
    fetch();
  }

  List<Widget> configsToCards() {
    List<Widget> cards = [];
    configs.asMap().forEach((index, config) {
      cards.add(
        ConfigCard(
          config: config,
          removeConfig: () {
            setState(() {
              configs.remove(config);
            });
          },
          onEdit: (configId) async {
            AllConfig? editedConfig = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfigView(id: config.id,)
              )
            );
            if(editedConfig != null) {
              setState(() {
                configs[index] = editedConfig;
              });
            }
          },
        )
      );
    });
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text("Configs"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: IconButton(
              icon: Icon(sessionId.isEmpty ? Icons.circle_outlined : Icons.add),
              onPressed: sessionId.isEmpty ? null : () async {
                AllConfig? newConfig = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewConfigView()
                  )
                );
                if(newConfig != null) {
                  setState(() {
                    configs.add(newConfig);
                  });
                }
              },
            )
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            children: configsToCards(),
          ),
        ),
      ),
    );
  }

  void fetch() async {
    List<Future> tasks = [];
    
    tasks.add(http.get(Uri.parse("http://$host/api/ollamaconfig/config"), headers: headers).then((res) {
      if(res.statusCode == 200) {
        var configsRes = jsonDecode(res.body)["configs"];
        setState(() {
          for(var config in configsRes){
            configs.add(AllConfig.fromJson(config));
          }
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Login Error"),
              content: Text("Unable to get Configs with Status: ${res.statusCode}"),
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
    }));

    await Future.wait(tasks);
  }
}

class ConfigCard extends StatelessWidget {
  final AllConfig config;
  final Function removeConfig;
  final Function(String configId) onEdit;

  const ConfigCard({super.key, required this.config, required this.removeConfig, required this.onEdit});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 1,
          child: GestureDetector(
            onTap: () {
              onEdit(config.id);
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Delete Config"),
                    content: Text("Do you really wish to delete this config?"),
                    actions: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cancel", 
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                          ),
                        )
                      ),
                      FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateColor.resolveWith((states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Theme.of(context).colorScheme.error.withValues(alpha: 0.7); // Error color when pressed
                            }
                            return Theme.of(context).colorScheme.error; // Default error color
                          }),
                        ),
                        onPressed: () async {
                          await http.delete(Uri.parse("http://$host/api/ollamaconfig/config/${config.id}"), headers: headers);
                          removeConfig();
                          Navigator.of(context).pop();
                        }, 
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError
                          ),
                        )
                      )
                    ],
                  );
                }
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(config.name, textAlign: TextAlign.center,),
            ),
          ),
        ),
        Divider()
      ],
    );
  }
}

class NewConfigView extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final messageController = TextEditingController();

  NewConfigView({super.key});

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

class ConfigView extends StatefulWidget {
  final String id;
  Config? config;
  ConfigView({super.key, required this.id});

  @override
  State<ConfigView> createState() => _ConfigViewState(id: id);
}

class _ConfigViewState extends State<ConfigView> {
  final String id;

  _ConfigViewState({required this.id}) {
    fetch();
  }

  void fetch() async {
    List<Future> tasks = [];

    tasks.add(http.get(Uri.parse("http://$host/api/ollamaconfig/config/$id"), headers: headers).then((res) {
      if(res.statusCode == 200) {
        var configRes = jsonDecode(res.body);
        setState(() {
          widget.config = Config.fromJson(configRes);
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Getting Config Failed"),
              content: Text("It seems like we couldn't fetch your config. Please contact your administrator."),
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
    }));

    await Future.wait(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text(widget.config == null ? "Loading Config..." : widget.config!.name),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.config == null ? [] : [
            TextDivider(text: "Model"),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(widget.config!.model),
            ),
            TextDivider(text: "Message"),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
              child: Text(widget.config!.message),
            ),
          ],
        ),
      ),
    );
  }
}

class TextDivider extends StatelessWidget {
  final String text;

  const TextDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider()
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Text(text),
        ),
        Expanded(
          child: Divider()
        ),
      ]
    );
  }
}

class AllConfig {
  final String name;
  final String id;

  AllConfig({required this.name, required this.id});

  factory AllConfig.fromJson(Map<String, dynamic> json) {
    return AllConfig(
      name: json['name'],
      id: json['id'],
    );
  }
}

class Config {
  final String name;
  final String model;
  final String message;

  Config({required this.name, required this.model, required this.message});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      name: json['name'],
      model: json['model'],
      message: json['message'],
    );
  }
}