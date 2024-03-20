import 'package:flutter/material.dart';
import 'package:chat/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chat/main.dart';
import 'package:chat/post.dart';
import 'package:chat/my_page.dart';

class ChatPage extends StatefulWidget {
     const ChatPage({super.key});

     @override
     State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

     @override
     Widget build(BuildContext context) {
          return Scaffold(
               appBar: AppBar(
                    title: const Text('チャット'),
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
                                                  return Text(post.text);
                                             },
                                        );
                                   },
                              ),
                         ),
                         TextFormField(
                              onFieldSubmitted: (text) {
                                   // まずは user という変数にログイン中のユーザーデータを格納します
                                   final user = FirebaseAuth.instance.currentUser!;

                                   final posterId = user.uid; // ログイン中のユーザーのIDがとれます
                                   final posterName = user.displayName!; // Googleアカウントの名前がとれます
                                   final posterImageUrl = user.photoURL!; // Googleアカウントのアイコンデータがとれます

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
    

                                   final newPost = Post(
                                        text: newText,
                                        createdAt: Timestamp.now(), // 投稿日時は現在とします
                                        // createdAt: DateTime.now().millisecondsSinceEpoch,
                                        // createdAt: Timestamp.now(),
                                        posterName: posterName,
                                        posterImageUrl: posterImageUrl,
                                        posterId: posterId,
                                        reference: newDocumentReference,
                                   );

                                   // 先ほど作った newDocumentReference のset関数を実行するとそのドキュメントにデータが保存されます。
                                   // 引数として Post インスタンスを渡します。
                                   // 通常は Map しか受け付けませんが、withConverter を使用したことにより Post インスタンスを受け取れるようになります。
                                   newDocumentReference.set(newPost);
                              },
                         ),
                    ]
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
