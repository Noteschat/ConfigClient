import 'dart:convert';

import 'package:configclient/components/general/TextDivider.dart';
import 'package:configclient/dtos/Config.dart';
import 'package:configclient/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConfigView extends StatefulWidget {
  final String id, host;
  Config? config;
  ConfigView({super.key, required this.id, required this.host});

  @override
  State<ConfigView> createState() => _ConfigViewState(id: id, host: host);
}

class _ConfigViewState extends State<ConfigView> {
  final String id, host;

  _ConfigViewState({required this.id, required this.host}) {
    fetch(host);
  }

  void fetch(String host) async {
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