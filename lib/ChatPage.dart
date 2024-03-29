import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:chat/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//絵文字のためにimportした
import 'package:emoji_regex/emoji_regex.dart';
// import 'package:flutter/src/widgets/framework.dart';
import 'package:intl/intl.dart';
//もし 2022/01/01 21:55:31 のように表示したいのであれば
//DateFormat('yyyy/MM/dd HH:mm:ss')
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//言語変更のため
import 'package:chat/main.dart';
import 'package:chat/post.dart';
import 'package:chat/my_page.dart';
import 'package:http/http.dart' as http;
//言語翻訳のため
import 'dart:convert'; // JSONデータを解析するために必要
// StatefulWidget使うため
import 'package:flutter/src/widgets/framework.dart';
import 'package:chat/Utils.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  Future<void> sendPost(String text) async {
  
    // まずは user という変数にログイン中のユーザーデータを格納します
    final user = FirebaseAuth.instance.currentUser!;

    final posterId = user.uid; // ログイン中のユーザーのIDがとれます
    final posterName = user.displayName!; // Googleアカウントの名前がとれます
    final posterImageUrl = user.photoURL!; // Googleアカウントのアイコンデータがとれます
    final posterLocale = window.locale.toString(); // ユーザーのデバイスの設定言語（ロケール）を取得します
    // 先ほど作った postsReference からランダムなIDのドキュメントリファレンスを作成します
    // doc の引数を空にするとランダムなIDが採番されます
    final newDocumentReference = postsReference.doc();


    //  String newText='';
    //  for(int i=0;i<text.length;i++){
      
    //   if(isEmoji(text[i])){
    //     print('絵文字です: $text[i]');
    //     newText+='a';
    //   }
    //   else{
    //     newText+=text[i];

    //   }

    //  }
    // 新しいテキストを初期化

    ////////emoji　の認識（一応動いたっぽい）
    // Use emojiRegex() to get the emoji regex pattern as a string
    String emojiPattern = emojiRegex().pattern;
    
    // Define a regular expression using the emoji pattern
    RegExp regex = RegExp(emojiPattern);

    // Replace emojis with their names
    // String textWithNames = text.replaceAllMapped(regex, (match) {
    //   return match.group(0)!.codeUnits.map((unit) => '\\u{${unit.toRadixString(16)}}').join('');
    // });
    String textWithNamesAndMeanings = await Utils.replaceEmojisWithMeanings(text, regex);
    
    String textEn = textWithNamesAndMeanings;
    String textJa = textWithNamesAndMeanings;
    if(posterLocale=="en_US"){
      textJa = await Utils.translateText(textJa, 'ja');
      String decodedText = utf8.decode(textJa.runes.toList());
      textJa = decodedText;
      //utf-8にエンコードしなければならなそう
    }
    else{
      textEn = await Utils.translateText(textEn, 'en');
    }

    ////////////////

    final newPost = Post(
      // text: newText,
      // text: text,
      text: textWithNamesAndMeanings,
      textEn: textEn, 
      textJa: textJa, 
      createdAt: Timestamp.now(), // 投稿日時は現在とします
      posterName: posterName,
      posterImageUrl: posterImageUrl,
      posterId: posterId,
      posterLocale: posterLocale,
      reference: newDocumentReference,
    );

    // 先ほど作った newDocumentReference のset関数を実行するとそのドキュメントにデータが保存されます。
    // 引数として Post インスタンスを渡します。
    // 通常は Map しか受け付けませんが、withConverter を使用したことにより Post インスタンスを受け取れるようになります。
    newDocumentReference.set(newPost);
  }

  //////////////////////////////////
  //投稿時に入力されているテキストの削除
  // build の外でインスタンスを作ります。
  final controller = TextEditingController();

  /// この dispose 関数はこのWidgetが使われなくなったときに実行されます。
  @override
  void dispose() {
    // TextEditingController は使われなくなったら必ず dispose する必要があります。
    controller.dispose();
    super.dispose();
  }
  //////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        // キーボードを閉じたい時はこれを呼びます。
        primaryFocus?.unfocus();
      },
    
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).title),
          // actions プロパティにWidgetを与えると右端に表示されます。
          actions: [
            // tap 可能にするために InkWell を使います。
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const MyPage();
                    },
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser!.photoURL!,
                ),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Post>>(
                // stream プロパティに snapshots() を与えると、コレクションの中のドキュメントをリアルタイムで監視することができます。
                // stream: postsReference.snapshots(),
                //下のやつでpostの表示を時効列に変えている
                stream: postsReference.orderBy('createdAt').snapshots(),
                // ここで受け取っている snapshot に stream で流れてきたデータが入っています。
                builder: (context, snapshot) {
                  // docs には Collection に保存されたすべてのドキュメントが入ります。
                  // 取得までには時間がかかるのではじめは null が入っています。
                  // null の場合は空配列が代入されるようにしています。
                  final docs = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      // data() に Post インスタンスが入っています。
                      // これは withConverter を使ったことにより得られる恩恵です。
                      // 何もしなければこのデータ型は Map になります。
                      final post = docs[index].data();
                      // return Text(post.text);
                      return PostWidget(post: docs[index].data());
                    },
                  ); //return
                }, //builder
              ), //child
            ), //Expanded

            //下のpadding と入れ変えた
            // TextFormField(
            //   onFieldSubmitted: (text) {
            //     sendPost(text);
            //   },
            // ),

            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,   // Left padding
                top: 10.0,    // Top padding
                right: 10.0,  // Right padding
                bottom: 30.0, // Bottom padding
              ),
              child: TextFormField(
                // 上で作ったコントローラー（入力フィールドの文字を消すやつ）を与えます。
                controller: controller,

                decoration: InputDecoration(
                  // 未選択時の枠線
                  // enabledBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(8),
                  //   borderSide: const BorderSide(color: Colors.grey),
                  // ),
                  // // 選択時の枠線
                  // focusedBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(8),
                  //   borderSide: const BorderSide(
                  //     color: Colors.grey,
                  //     width: 1,
                  //   ),
                  // ),
                  // 中を塗りつぶす色
                  // fillColor: Colors.white,
                  fillColor: Color.fromRGBO(242, 239, 237, 1.0),
                  // 中を塗りつぶすかどうか
                  filled: true,
                ),

                onFieldSubmitted: (text) {
                  sendPost(text);
                  // 入力中の文字列を削除します。
                  controller.clear();
                },
                

              ), //child
            ), //Padding
          ]
        ),
      ),
    );
  }
}

//   //その文字が絵文字かどうか
//   bool isEmoji(String character) {
//     RegExp emojiPattern = RegExp(
//       r"[\u{1F600}-\u{1F64F}"
//       r"\u{1F300}-\u{1F5FF}"
//       r"\u{1F680}-\u{1F6FF}"
//       r"\u{1F1E0}-\u{1F1FF}"
//       r"\u{2600}-\u{26FF}"
//       r"\u{2700}-\u{27BF}"
//       r"]",
//       unicode: true,
//     );
//     return emojiPattern.hasMatch(character);
//    }
//  String newText = '';
//   // 一文字ずつ処理するためのforループ
//     for (int i = 0; i < text.length; i++) {
//         final character = text[i];
//         // 文字が絵文字かどうかをチェックする
//         if (isEmoji(character)) {
//             // 絵文字の場合、代わりに文字 "a" を newText に追加
//             newText += 'a';
//         } else {
//             // 絵文字でない場合、そのまま newText に追加
//             newText += character;
//         }
//     }

class PostWidget extends StatefulWidget {
  const PostWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool showIcons = false;
  @override
  Widget build(BuildContext context) {
    // return Text(post.text);
    if (FirebaseAuth.instance.currentUser!.uid == widget.post.posterId) {
    
      return InkWell(
        onTap: () {
          // Toggle the visibility of the icons
          setState(() {
            showIcons = !showIcons;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row( //posterName & date
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          // toDate() で Timestamp から DateTime に変換できます。
                          DateFormat('MM/dd HH:mm').format(widget.post.createdAt.toDate()),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ), //Row                   
                    //投稿に背景色をつける
                    Align( //post
                      alignment: Alignment.centerRight,
                      child: Container( //post
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          // 角丸にするにはこれを追加します。
                          // 4 の数字を大きくするともっと丸くなります。
                          borderRadius: BorderRadius.circular(6),
                          // 色はここで変えられます
                          // // [100] この数字を小さくすると色が薄くなります。
                          // color: Colors.blue[100],
                          //上のcolorを下の三項演算子で自分の投稿だけ色を変えるようにされている
                          // [条件式] ? A : B の三項演算子を使っています。
                          color: Colors.blue[900],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2), // Shadow color
                              spreadRadius: 3, // Spread radius
                              blurRadius: 5, // Blur radius
                              offset: Offset(0, 3), // Offset in x and y directions
                            ),
                          ],
                        ),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ja' ? 
                            widget.post.textJa    : 
                            widget.post.textEn,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),  

                      ),
                    ),
                    
                    if (showIcons)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          /// 編集ボタン
                          IconButton( //edit
                            onPressed: () {
                              //　ダイアログを表示する場合は `showDialog` 関数を実行します。
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    // content: Text('ダイアログ'),
                                    content: TextFormField(
                                      initialValue: widget.post.text,
                                      autofocus: true,
                                      //ダイアログを開いたタイミングですぐにキーボードが開かれてほしいです。
                                      //これを実現するには autofocus プロパティに true を与えましょう。
                                      onFieldSubmitted: (newText) async {
                                        String emojiPattern = emojiRegex().pattern;
                                        // Define a regular expression using the emoji pattern
                                        RegExp regex = RegExp(emojiPattern);
                                        String textWithNamesAndMeanings =  await Utils.replaceEmojisWithMeanings(newText, regex);
    
                                        String textEn = textWithNamesAndMeanings;
                                        String textJa = textWithNamesAndMeanings;
                                        if(widget.post.posterLocale == "en_US"){
                                          textJa = await Utils.translateText(textJa, 'ja');
                                          String decodedText = utf8.decode(textJa.runes.toList());
                                          textJa = decodedText;
                                          //utf-8にエンコードしなければならなそう
                                        }
                                        else{
                                          textEn = await Utils.translateText(textEn, 'en');
                                        }
                                        widget.post.reference.update({'textJa': textJa});
                                        widget.post.reference.update({'textEn': textEn});
                                        widget.post.reference.update({'text': newText});
                                        //update したらダイアログを閉じよう
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.edit,
                              size: 15,
                            ),
                          ),

                          /// 削除ボタン
                          IconButton( //delete
                            onPressed: () {
                              // 削除は reference に対して delete() を呼ぶだけでよい。
                              widget.post.reference.delete();
                            },
                            icon: const Icon(
                              Icons.delete,
                              size: 15,
                            ),
                          ),
                          IconButton( //元の文を表示する
                            onPressed: () {
                              //　ダイアログを表示する場合は `showDialog` 関数を実行します。
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('元のテキスト'), // Add the additional text
                                        SizedBox(height: 8), // Add some space between the texts
                                        Text(widget.post.text), // Display the original text
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.read_more,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                  ],
                ), //child
              ), //expanded
              const SizedBox(width: 5),
            ], //children
          ), //Row
        ), //Padding
      );
    } else {
      return InkWell(
        onTap: () {
          // Toggle the visibility of the icons
          setState(() {
            showIcons = !showIcons;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  widget.post.posterImageUrl,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row( //posterName & date
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.post.posterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          // toDate() で Timestamp から DateTime に変換できます。
                          DateFormat('MM/dd HH:mm').format(widget.post.createdAt.toDate()),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ), //Row
                    //投稿に背景色をつける
                    Container( //post
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // 角丸にするにはこれを追加します。
                        // 4 の数字を大きくするともっと丸くなります。
                        borderRadius: BorderRadius.circular(6),
                        // 色はここで変えられます
                        // // [100] この数字を小さくすると色が薄くなります。
                        // color: Colors.blue[100],
                        //上のcolorを下の三項演算子で自分の投稿だけ色を変えるようにされている
                        // [条件式] ? A : B の三項演算子を使っています。
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2), // Shadow color
                            spreadRadius: 3, // Spread radius
                            blurRadius: 5, // Blur radius
                            offset: Offset(0, 3), // Offset in x and y directions
                          ),
                        ],
                      ),
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ja' ? 
                          widget.post.textJa    : 
                          widget.post.textEn,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      
                      ),  
                    ),
                    if (showIcons)
                      Row( //icon buttons
                        // mainAxisSize: MainAxisSize.min, // Set to MainAxisSize.min to make the Row occupy minimum space
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton( //元の文を表示する
                            onPressed: () {
                              //　ダイアログを表示する場合は `showDialog` 関数を実行します。
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('元のテキスト'), // Add the additional text
                                        SizedBox(height: 8), // Add some space between the texts
                                        Text(widget.post.text), // Display the original text
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.read_more,
                              size: 15,
                            ),
                          ),
                        ]
                      ), //row
                    //if showIcon
                  ],
                ), //child
              ), //expanded
            ], //children
          ), //Row
        ), //Padding
      );

    }
  }
}