import 'dart:convert';

import 'package:configclient/components/Config/ConfigView.dart';
import 'package:configclient/components/ConfigSelect/ConfigCard.dart';
import 'package:configclient/components/NewConfig/NewConfig.dart';
import 'package:configclient/dtos/Config.dart';
import 'package:configclient/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConfigSelect extends StatefulWidget {
  final String host;

  const ConfigSelect({super.key, required this.host});

  @override
  State<ConfigSelect> createState() => _ConfigSelectState(host);
}

class _ConfigSelectState extends State<ConfigSelect> {
  List<AllConfig> configs = [];

  _ConfigSelectState(String host) {
    fetch(host);
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
                builder: (context) => ConfigView(id: config.id, host: widget.host)
              )
            );
            if(editedConfig != null) {
              setState(() {
                configs[index] = editedConfig;
              });
            }
          },
          host: widget.host,
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
                    builder: (context) => NewConfigView(host: widget.host)
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

  void fetch(String host) async {
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