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
    String textWithNames = text.replaceAllMapped(regex, (match) {
      return match.group(0)!.codeUnits.map((unit) => '\\u{${unit.toRadixString(16)}}').join('');
    });
    ////////////////

    final newPost = Post(
      // text: newText,
      // text: text,
      text: textWithNames,
      createdAt: Timestamp.now(), // 投稿日時は現在とします
      posterName: posterName,
      posterImageUrl: posterImageUrl,
      posterId: posterId,
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
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                // 上で作ったコントローラー（入力フィールドの文字を消すやつ）を与えます。
                controller: controller,

                decoration: InputDecoration(
                  // 未選択時の枠線
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                  // 選択時の枠線
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                  // 中を塗りつぶす色
                  fillColor: Colors.amber[50],
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

class PostWidget extends StatelessWidget {
  const PostWidget({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    // return Text(post.text);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              post.posterImageUrl,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.posterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      // toDate() で Timestamp から DateTime に変換できます。
                      DateFormat('MM/dd HH:mm').format(post.createdAt.toDate()),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ), //Row
                
                // Text(post.text),
                //投稿に背景色をつける
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // 角丸にするにはこれを追加します。
                    // 4 の数字を大きくするともっと丸くなります。
                    borderRadius: BorderRadius.circular(4),
                    // 色はここで変えられます
                    // // [100] この数字を小さくすると色が薄くなります。
                    // color: Colors.blue[100],
                    //上のcolorを下の三項演算子で自分の投稿だけ色を変えるようにされている
                    // [条件式] ? A : B の三項演算子を使っています。
                    color: FirebaseAuth.instance.currentUser!.uid == post.posterId ? Colors.amber[100] : Colors.blue[100],
                  ),
                  child: Text(post.text),
                ),
                
                if (FirebaseAuth.instance.currentUser!.uid == post.posterId)
                  Row(
                    children: [
                      /// 編集ボタン
                      IconButton(
                        onPressed: () {
                          //　ダイアログを表示する場合は `showDialog` 関数を実行します。
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                // content: Text('ダイアログ'),
                                content: TextFormField(
                                  initialValue: post.text,
                                  autofocus: true,
                                  //ダイアログを開いたタイミングですぐにキーボードが開かれてほしいです。
                                  //これを実現するには autofocus プロパティに true を与えましょう。
                                  onFieldSubmitted: (newText) {
                                    post.reference.update({'text': newText});
                                    //update したらダイアログを閉じよう
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.edit),
                      ),

                      /// 削除ボタン
                      IconButton(
                        onPressed: () {
                          // 削除は reference に対して delete() を呼ぶだけでよい。
                          post.reference.delete();
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
              ],
            ), //child
          ), //expanded
        ], //children
      ), //Row
    ); //Padding
  }
}