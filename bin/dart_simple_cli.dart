import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

Future<void> main(List<String> args) async {
  // ---------- 引数パース ----------
  final ArgParser parser = ArgParser();
  // オプション：出力ファイルのパス指定
  parser.addOption(
    'output',
    abbr: "o",
    help: 'Define output filename and path',
    valueHelp: '/path/to/file.md',
  );
  // オプション：出力ファイル名指定
  parser.addOption(
    'title',
    abbr: "t",
    help: 'Define output filename (won\'t work with \'--output\' option)',
    valueHelp: 'file.md',
  );
  // オプション：出力ディレクトリ指定
  parser.addOption(
    'directory',
    abbr: "d",
    help: 'Difile output directory (won\'t work with \'--output\' option)',
    valueHelp: '/path/to/directory/',
  );
  // フラグ：ヘルプ表示
  parser.addFlag('help', abbr: 'h', hide: true);
  // 因数取得
  final ArgResults results = parser.parse(args);

  // ---------- ヘルプの表示 ----------

  if (results['help']) {
    print(parser.usage);
    return; // 早期リターン
  }

  // ---------- 変数、定数 ----------

  // 年月日文字列
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String timestamp = formatter.format(now);

  // ホームとデスクトップのディレクトリパス
  final String homePath = getHomeDir();
  final String desktopPath = "${homePath}Desktop/";

  // 出力ファイル名 (値は下行で決定するため、ここでは宣言まで)
  late String fileName;
  late String fileExtention = extension(fileName) == '' ? '.md' : extension(fileName); // ファイル拡張子
  late String fileNameRaw = basenameWithoutExtension(fileName); // ファイル名の拡張子以前の部分
  late String fileDir; // 出力ディレクトリパス
  late String filePath; // 出力ファイルパス
  int fileIndex = 1; // ファイル名の連番用

  // ---------- 出力パスの決定 ----------

  // オプションで分岐して、ファイル名と出力ディレクトリパスの決定
  // outputオプションで出力パスを指定
  if (results['output'] != null) {
    // 引数の出力パスをディレクトリとファイル名に分解
    final filePathArray = results['output'].toString().split('/');
    fileName = filePathArray.removeLast();
    fileDir = '${filePathArray.join('/')}/';
  } else {
    // titleオプションでファイル名指定
    if (results['title'] != null) {
      fileName = '$timestamp' '_' '${results['title']}.md';
    } else {
      fileName = '$timestamp.md';
    }

    // directoryオプションでディレクトリ指定
    if (results['directory'] != null) {
      fileDir = results['directory'];
      // スラッシュの補完
      if (fileDir[fileDir.length - 1] != '/') fileDir += '/';
    } else {
      fileDir = desktopPath;
    }
  }
  // ファイルパスの決定
  filePath = fileDir + fileNameRaw + fileExtention;

  // ---------- ファイル名に連番をつけて重複を防ぐ処理 ----------

  bool created = false; // ファイル生成が完了したかチェック
  while (!created) {
    // すでに同名のファイルが存在する場合はindexをインクリメント
    if (await File(filePath).exists()) {
      // インクリメント
      fileIndex++;
      // indexを2桁のStringにする
      final String fileIndexStr = fileIndex.toString().padLeft(2, '0');

      // ファイル名とパスの再決定
      filePath = '$fileDir${fileNameRaw}_$fileIndexStr$fileExtention';
    } else {
      // 同名のファイルがなければ生成して、ループ終了
      await File(filePath).create().then((file) async {
        await file.writeAsString(getMinutesTemplate()).then((_) => created = true);
      });
    }
  }
}

//  ---------- ホームディレクトリのパス取得 ----------

String getHomeDir() {
  // 出力用文字列
  late String home;

  // 実行環境の取得
  Map<String, String> envVars = Platform.environment;

  // OSで分岐してホームディレクトリを取得
  if (Platform.isMacOS) {
    home = envVars['HOME']!;
  } else if (Platform.isLinux) {
    home = envVars['HOME']!;
  } else if (Platform.isWindows) {
    home = envVars['UserProfile']!;
  }

  // 出力
  return '$home/';
}

// ---------- テンプレート文字列出力 ----------

String getMinutesTemplate() {
  return '''## 場所

- 

## 参加者

- 

## アジェンダ

- 

## 議事録

- 
''';
}

String getErDiagramTemplate() {
  return '''@startuml er
hide circle
skinparam linetype ortho

entity Entity {
    id : number
    ---
    title : text
    category_id : number <<FK>>
}

entity Category {
    id : number
    ---
    title : text
}

Entity o--|| Category
@enduml
''';
}
