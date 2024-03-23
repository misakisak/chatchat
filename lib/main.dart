import 'package:chat/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import3つ足した。
import 'package:chat/post.dart';
import 'package:chat/ChatPage.dart';
////postが見つからないエラーが出たから足しました
import 'package:cloud_firestore/cloud_firestore.dart';
////FirebaseFirestoreが動かなくてpackageをimportしました
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'dart:ui'; // Import the dart:ui library

Future<void> main() async {
  // main 関数でも async が使えます
  WidgetsFlutterBinding.ensureInitialized(); // runApp 前に何かを実行したいときはこれが必要です。
  await Firebase.initializeApp(
    // これが Firebase の初期化処理です。
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());

  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   theme: ThemeData(),
    //   home: const SignInPage(),
    // );
    // currentUser が null であればログインしていません。
    if (FirebaseAuth.instance.currentUser == null) {
      // 未ログイン
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates, // 追加
        supportedLocales: AppLocalizations.supportedLocales,             // 追加
        theme: ThemeData(),
        home: const SignInPage(),
      );
    } else {
      // ログイン中
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates, // 追加
      supportedLocales: AppLocalizations.supportedLocales,             // 追加
        theme: ThemeData(),
        home: const ChatPage(),
      );
    }
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  Future<void> signInWithGoogle() async {
    // GoogleSignIn をして得られた情報を Firebase と関連づけることをやっています。
    final googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();

    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }
  final posterLocale = window.locale.toString();

  @override
  Widget build(BuildContext context) {
    String buttonTitle = ''; // Variable to store the app bar title
    String appBarTitle = '';

    // Set the app bar title based on the posterLocale
    if (posterLocale == 'ja_JP') {
      buttonTitle = 'Googleでサインイン';
      appBarTitle = 'サインイン';
    } else if (posterLocale == 'en_US') {
      buttonTitle = 'Sign In with Google';
      appBarTitle = 'Sign in';
    }
    return Scaffold(
      backgroundColor: Color.fromRGBO(222, 251, 255, 1.0),
      // appBar: AppBar(
      //   title:  Text(appBarTitle),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/chatchat.png'), // Display the custom image in the leading position
            SizedBox(width: 5, height: 20),
            Text('アプリ名'),
            const SizedBox(width: 20, height: 20),
            ElevatedButton(
              child:  Text(buttonTitle),
              onPressed: () async {
                await signInWithGoogle();
                
                // ログインが成功すると FirebaseAuth.instance.currentUser にログイン中のユーザーの情報が入ります
                print(FirebaseAuth.instance.currentUser?.displayName);
                
                // ログインに成功したら ChatPage に遷移します。
                // 前のページに戻らせないようにするにはpushAndRemoveUntilを使います。
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) {
                      return const ChatPage();
                    }),
                    (route) => false,
                  );
                }
              },
            ),
          ]
        )
      ),
    );
  }
}

final postsReference = FirebaseFirestore.instance.collection('posts').withConverter<Post>( // <> ここに変換したい型名をいれます。今回は Post です。
  fromFirestore: ((snapshot, _) { // 第二引数は使わないのでその場合は _ で不使用であることを分かりやすくしています。
    return Post.fromFirestore(snapshot); // 先ほど定期着した fromFirestore がここで活躍します。
  }),
  toFirestore: ((value, _) {
    return value.toMap(); // 先ほど適宜した toMap がここで活躍します。
  }),
);
