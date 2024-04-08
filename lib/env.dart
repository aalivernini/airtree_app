import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'BING_KEY', obfuscate: true)
  static final String bingKey = _Env.bingKey;

  @EnviedField(varName: 'ADRESS_HOME', obfuscate: true)
  static final String adressHome = _Env.adressHome;

  @EnviedField(varName: 'AIRTREE_KEY', obfuscate: true)
  static final String airtreeKey = _Env.airtreeKey;
}

