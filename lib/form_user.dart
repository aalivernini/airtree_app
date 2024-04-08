import 'package:flutter/material.dart';
import 'database.dart' as db;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class UserForm extends StatefulWidget {
    const UserForm({super.key});

    @override
    State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
    RegExp regExp = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$');
    bool _passwordVisible = false;
    final _formKey = GlobalKey<FormState>();
    String? languageFromDB = '';
    String? handFromDB = '';
    Map data = {
    "nome": "",
    "cognome": "",
    "username": "",
    "email": "",
    "password": "",
};

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        Widget formWidget = Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.register),
            ),
            body: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                child: Form(
                    key: _formKey,
                    child: Column(
                        children: [
                            Text(
                                AppLocalizations.of(context)!.joinAirtree,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                ),
                            ),
                            TextFormField(
                                // Validatore prima di restituire il dato
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.missingFirstName;
                        }
                                    return null;
                                },
                                //Salva il dato nella Map data
                                onSaved: (value) {
                                    data['nome'] = value;
                                },
                                // Manda al prossimo campo dopo aver premuto invio
                                textInputAction: TextInputAction.next,

                                // Label per il campo
                                decoration: InputDecoration(
                                    label: Text(
                                        AppLocalizations.of(context)!.firstNameRegister)),
                            ),
                            TextFormField(
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.missingLastName;
                        }
                                    return null;
                                },
                                onSaved: (value) {
                                    data['cognome'] = value;
                                },
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                    label: Text(
                                        AppLocalizations.of(context)!.lastNameRegister)),
                            ),
                            TextFormField(
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.missingUsername;
                        }
                                    return null;
                                },
                                onSaved: (value) {
                                    data['username'] = value;
                                },
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                    label: Text(
                                        AppLocalizations.of(context)!.userNameRegister)),
                            ),
                            TextFormField(
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.missingEmail;
                        }
                                    return null;
                                },
                                onSaved: (value) {
                                    data['email'] = value;
                                },
                                textInputAction: TextInputAction.next,

                                // Tastiera style email per semplificare l'utente
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(label: Text('E-mail')),
                            ),
                            TextFormField(
                                // Chiude la tastiera dopo aver premuto invio
                                textInputAction: TextInputAction.done,

                                // Testo oscurato per la password
                                obscureText: !_passwordVisible,
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.missingPassword;
                        }
                        //Lunghezza minima
                        else if (value.length < 8) {
                          return AppLocalizations.of(context)!.passwordShort;
                        }
                        // Una maiuscola, una minuscola e una lettera
                        else if (!regExp.hasMatch(value)) {
                          return AppLocalizations.of(context)!.passwordPath;
                        } else {
                          return null;
                        }
                                },
                                onSaved: (value) {
                                    data['password'] = value;
                                },
                                //Icona per visualizzare la password non oscurata
                                decoration: InputDecoration(
                                    label: Text(AppLocalizations.of(context)!.password),
                                    suffixIcon: IconButton(
                                        icon: !_passwordVisible
                                        ? const Icon(
                                            Icons.visibility,
                                            size: 25.0,
                                        )
                                        : const Icon(Icons.visibility_off, size: 25.0),
                                        onPressed: () {
                                            setState(() {
                                                _passwordVisible = !_passwordVisible;
                                            });
                                        },
                                    )),
                            ),
                            Container(
                                margin: const EdgeInsets.only(
                                    left: 0, top: 20, right: 0, bottom: 0),
                                child: ElevatedButton(
                                    // Quando viene premuto
                                    onPressed: () async {
                                        // Controllo se la validazione ha dato esito corretto

                                        if (_formKey.currentState!.validate()) {
                              //Salva i dati
                              _formKey.currentState!.save();

                              try {
                                await db.DatabaseManager.createUser(data);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .registrationOk),
                                      duration: Duration(seconds: 2)),
                                );
                                Navigator.pop(context, true);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .registrationFailed)),
                                );
                              }
                            }
                                    },
                                    child: Text(
                                        AppLocalizations.of(context)!.submit,
                                        style: TextStyle(color: Colors.black),
                                    )),
                            )
                        ],
                    ))));

        return formWidget;
    }
}

class InfoUser extends StatelessWidget {
    const InfoUser({Key? key, required this.data}) : super(key: key);

    final Map data;

    @override
    Widget build(BuildContext context) {
        Widget info = Scaffold(
            appBar: AppBar(
                title: const Text('Info'),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(AppLocalizations.of(context)!.firstName(data["nome"])),
                        Text(AppLocalizations.of(context)!.lastName(data["cognome"])),
                        Text(AppLocalizations.of(context)!.userName(data["username"])),
                        Text(AppLocalizations.of(context)!.email(data["email"])),
                    ],
                ),
            ),
        );

        return info;
    }
}

