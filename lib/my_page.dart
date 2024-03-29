import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart'; 
import 'package:chat/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class MyPage extends StatelessWidget {
     const MyPage({super.key});

     @override
     Widget build(BuildContext context) {
     // 何度も FirebaseAuth.instance.currentUser! と書くのは大変です。
     // そこで適当な変数名をつけた変数に一時的に値を格納して記述量を短くする場合があります。
     final user = FirebaseAuth.instance.currentUser!;
     // final posterLocale = window.locale.toString();
     final posterLocale = Localizations.localeOf(context).toString();


     return Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context).mypage)),
          body: Container(
               alignment: Alignment.center,
               padding: const EdgeInsets.all(32),
               child: Column(
                    children: [
                         // ユーザーアイコン画像
                         CircleAvatar(
                              backgroundImage: NetworkImage(user.photoURL!),
                              radius: 40,
                         ),
                         // ユーザー名
                         Text(
                              user.displayName!,
                              style: const TextStyle(
                                   fontWeight: FontWeight.bold,
                                   fontSize: 20,
                              ),
                         ),
                         const SizedBox(height: 16),

                         // 部分的に左寄せにしたい場合の書き方
                         Align(
                              alignment: Alignment.centerLeft,
                              // ユーザー ID
                              child: Text('${AppLocalizations.of(context).userid}：${user.uid}'),
                         ),
                         Align(
                              alignment: Alignment.centerLeft,
                              // 登録日
                              child: Text('${AppLocalizations.of(context).registrationdate}：${user.metadata.creationTime!}'),
                         ),
                         Align(
                              alignment: Alignment.centerLeft,
                              // 登録日
                              child: Text('Language：${posterLocale!}'),
                         ),
                         const SizedBox(height: 16),
                              ElevatedButton(
                                   onPressed: () async {
                                        // Google からサインアウト
                                        await GoogleSignIn().signOut();
                                        // Firebase からサインアウト
                                        await FirebaseAuth.instance.signOut();
                                        // SignInPage に遷移
                                        // このページには戻れないようにします。
                                        Navigator.of(context).pushAndRemoveUntil(
                                             MaterialPageRoute(builder: (context) {
                                                  return const SignInPage();
                                             }),
                                             (route) => false,
                                        );
                                   },
                                   child: Text(AppLocalizations.of(context).signout),
                              ),
                              // const SizedBox(height: 16),
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     ElevatedButton(
                              //       onPressed: () {
                              //         // 日本語を選択した場合の処理
                              //         Locale locale = Locale('ja', 'JP');
                                      
                              //       },
                              //       child: const Text('日本語'),
                              //     ),
                              //     const SizedBox(width: 16),
                              //     ElevatedButton(
                              //       onPressed: () {
                              //         // 英語を選択した場合の処理
                              //         Locale locale = Locale('en', 'US');
                                      
                              //       },
                              //       child: const Text('English'),
                              //     ),
                              //   ],
                              // ),
                    ],
               ),
          ),
    );
  }
}