import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // managing the diplay of android top bar
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import 'database.dart' as db;
import 'providers.dart' as pr;
import 'widget.dart' as wid;
import 'widget_other.dart' as oth;
import 'package:Airtree/l10n/l10n.dart';
import 'package:Airtree/src/generated/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart' as info;
import 'form.dart' as inp;

import 'camera/camera.dart' as cam;
import 'camera/provider_lai.dart' as pr;

import 'package:Airtree/map/imagery_provider.dart';

import 'env.dart' ;
String addressHome = Env.adressHome;


Future<bool> checkPrivacyAccepted(BuildContext context) async {
    final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
    await gProvider.getUserSetting();
    final uSettings = gProvider.userSetting!;

    info.PackageInfo packageInfo = await info.PackageInfo.fromPlatform();
    String buildNumberStr = packageInfo.buildNumber;
    int buildNumber = int.parse(buildNumberStr);
    final check = uSettings.idPrivacyTerms == buildNumber;
    return check;
}

Future<void> setPrivacyAccepted() async {
    info.PackageInfo packageInfo = await info.PackageInfo.fromPlatform();
    String buildNumberStr = packageInfo.buildNumber;
    int buildNumber = int.parse(buildNumberStr);
    final uSettings = await db.UserSetting.fromDb();
    uSettings.idPrivacyTerms = buildNumber;
    await uSettings.dbUpdate();
}


void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // The Android status bar (top) is always hidden: the map and the panels
    // are the only content the user needs and the top bar steals space.
    // Only the bottom system bar stays visible.
    await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: <SystemUiOverlay>[SystemUiOverlay.bottom],
    );

    // Android re-enables the system overlays while the on-screen keyboard is
    // visible and does not restore them when it is dismissed, so the status
    // bar would come back for good after the first text entry.
    WidgetsBinding.instance.addObserver(_SystemUiOverlayGuard());

    runApp(MultiProvider(
            providers: [
                ChangeNotifierProvider(create: (context) => pr.ParamProvider()),
                ChangeNotifierProvider(create: (context) => pr.GlobalProvider()),
                ChangeNotifierProvider(create: (context) => pr.MapProvider()),
                ChangeNotifierProvider(create: (context) => pr.EditorProvider()),
                ChangeNotifierProvider(create: (context) => pr.PanelProvider()),
                ChangeNotifierProvider(create: (context) => pr.ResultProvider()),
                ChangeNotifierProvider(create: (context) => pr.ProviderLai()),
                ChangeNotifierProvider(
                    create: (context) =>
                        ImageryProvider()..refreshAvailability()),
            ],
            child:  const MaterialApp(
                home: NavigationBarApp(),
                debugShowCheckedModeBanner: false,
            )));
}

class NavigationBarApp extends StatelessWidget {
    const NavigationBarApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MultiProvider(
            providers: [
                ChangeNotifierProvider(create: (context) => pr.ParamProvider()),
            ],
            child: Consumer<pr.GlobalProvider>(
                builder: (context, gProvider, child) {
                    return MaterialApp(
                        debugShowCheckedModeBanner: false,
                        supportedLocales: L10n.all,
                        locale: Locale(gProvider.languageInterface),
                        localizationsDelegates: const [
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                        ],
                    routes: {
                        '/': (context) => const NavigationPage(),
                        '/greenForm': (context) =>  inp.GreenForm(),
                        '/camera': (context) => cam.TakePictureScreen(),
                        '/camera/preview': (context) =>  const cam.DisplayPicture(),
                        '/camera/lai': (context) => const cam.DisplayThreshold(),
                    },
                    );
                },
            ),
        );
    }
}



class NavigationPage extends StatefulWidget {
    const NavigationPage({super.key});

    @override
    NavigationPageState createState() => NavigationPageState();
}

class NavigationPageState extends State<NavigationPage> {
    // int currentPageIndex = 0;
    var restoringUIOverlays = false;
    final GlobalKey<NavigationPageState> navigationKey = GlobalKey();

    bool doCheckPrivacy = true;


    @override
    void initState() {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
        final rProvider = Provider.of<pr.ResultProvider>(context, listen: false);
        db.Settings.updateFromWeb();
        db.Base.getConnection();
        gProvider.getProjects();
        mProvider.setStartCoords(); // set start coords from current position (gps); start coords are updated later if it's selected a not empty project

        // Result check and download periodically
        const intervalDownload = Duration(seconds: 10);
        Timer.periodic(intervalDownload, (Timer t) {
            wid.downloadResults(context).then((value) {
                if (value == 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('New results downloaded'),
                            duration: Duration(seconds: 4),
                        ),
                    );
                    gProvider.getProjects();
                    rProvider.reset();

                    setState(() {});
                }
            });
        });
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        // SERVER ADDRESS
        //print("server: $addressHome");

        return FutureBuilder<bool>(
            future: checkPrivacyAccepted(context),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (!snapshot.hasData) {
                    return const Center(
                        child: SizedBox(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator()
                        )
                    );
                } else
                {
                    bool isPrivacyAccepted = snapshot.data!;

                    // PRIVACY AND TERMS OF USE POPUP
                    if (doCheckPrivacy) {
                        if (!isPrivacyAccepted) {
                            Future.delayed(Duration.zero, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const oth.PrivacyTermsForm(),
                                    )
                                ).then((value) {
                                    if (value == null) {
                                        // exiting privacy term form through back button (or similar)
                                        Navigator.pushNamedAndRemoveUntil(context,'/',(_) => false);

                                    } else {
                                        if (value) {
                                            // privacy and terms of use are accepted
                                            setPrivacyAccepted();
                                            // avoid to show privacy and terms of use form again
                                            doCheckPrivacy = false;
                                        } else {
                                            // exiting privacy term form without acceptance
                                            Navigator.pushNamedAndRemoveUntil(context,'/',(_) => false);
                                        }
                                    }
                                });
                            });
                        }
                    }


                    // START AIRTREE PANEL
                    return Consumer3<pr.GlobalProvider, pr.MapProvider, pr.ParamProvider>(
                        builder: (context, gProvider, mProvider, pProvider, child) {
                            return Scaffold(
                                key: navigationKey,
                                bottomNavigationBar: NavigationBar(
                                    height: 60,
                                    onDestinationSelected: (int index) {
                                        setState(() {
                                            if (index == 3 || index == 0) {
                                                gProvider.currentPageIndex = index;
                                            } else {
                                                if (
                                                    // user registration not required in mobile app
                                                    // gProvider.idUser.isNotEmpty &&
                                                    gProvider.idProject.isNotEmpty) {
                                                    gProvider.currentPageIndex = index;
                                                } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('select project first')),
                                                    );
                                                }
                                            }
                                        });
                                    },
                                    selectedIndex: gProvider.currentPageIndex,
                                    destinations: <Widget>[
                                        NavigationDestination(
                                            icon: const Icon(Icons.menu_open),
                                            label: AppLocalizations.of(context)!.prj,
                                        ),
                                        NavigationDestination(
                                            icon: const Icon(Icons.explore),
                                            label: AppLocalizations.of(context)!.map,
                                        ),
                                        NavigationDestination(
                                            icon: const Icon(Icons.inbox),
                                            label: AppLocalizations.of(context)!.result,
                                        ),
                                        NavigationDestination(
                                            icon: const Icon(Icons.more_vert),
                                            label: AppLocalizations.of(context)!.other,
                                        ),
                                    ],
                                    ),
                                    body: wid.getPageList(context)[gProvider.currentPageIndex],
                                    ); // end of main scaffold
                        }); // end of consumer
                }}); // end of build
            } // end of class
    }

        Future<void> setSystemUIChangeCallback(SystemUiChangeCallback? callback) async {
            ServicesBinding.instance.setSystemUiChangeCallback(callback);
            // Skip setting up the listener if there is no callback.
            if (callback != null) {
                await SystemChannels.platform.invokeMethod<void>(
                    'SystemChrome.setSystemUIChangeListener',
                );
            }
        }

/// Restores the hidden top system overlay after the on-screen keyboard is
/// dismissed.
///
/// Android re-enables the system overlays while the keyboard is visible and
/// does not restore them when it closes, so the status bar would come back
/// for good after the first text entry. The engine restores the previous
/// overlay state only when the application loses and regains the focus, which
/// never happens on a form screen, so the state is re-asserted here.
class _SystemUiOverlayGuard with WidgetsBindingObserver {
    /// Whether the on-screen keyboard was covering the app at the previous
    /// window metrics change.
    bool _keyboardVisible = false;

    @override
    void didChangeMetrics() {
        final bool keyboardVisible = _isKeyboardVisible();
        if (_keyboardVisible && !keyboardVisible) {
            // The keyboard has just been dismissed. Android refuses to change
            // the overlay visibility during the second that follows the
            // keyboard closing, so the restore is delayed accordingly.
            Future<void>.delayed(const Duration(milliseconds: 1100), () {
                SystemChrome.restoreSystemUIOverlays();
            });
        }
        _keyboardVisible = keyboardVisible;
    }

    /// Reports whether the on-screen keyboard currently covers the app.
    bool _isKeyboardVisible() {
        for (final view in WidgetsBinding.instance.platformDispatcher.views) {
            if (view.viewInsets.bottom > 0) {
                return true;
            }
        }
        return false;
    }
}
