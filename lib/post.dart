//足した
import 'package:cloud_firestore/cloud_firestore.dart';
////DocumentSnapshotが動かなくてpackageをimportしました。

class Post {
     Post({
          required this.text,
          required this.textEn,
          required this.textJa,
          required this.createdAt,
          required this.posterName,
          required this.posterImageUrl,
          required this.posterId,
          required this.posterLocale,
          required this.reference,
     });

     factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
          final map = snapshot.data()!; // data() の中には Map 型のデータが入っています。
          // data()! この ! 記号は nullable な型を non-nullable として扱うよ！ という意味です。
          // data の中身はかならず入っているだろうという仮説のもと ! をつけています。
          // map データが得られているのでここからはいつもと同じです。
          return Post(
               text: map['text'],
               textEn: map['textEn'] ?? map['text'],
               textJa: map['textJa'] ?? map['text'],
               createdAt: map['createdAt'],
               posterName: map['posterName'],
               posterImageUrl: map['posterImageUrl'],
               posterId: map['posterId'],
               posterLocale: map['posterLocale'] ?? "en_US",
               reference: snapshot.reference, // 注意。reference は map ではなく snapshot に入っています。
          );
     }

     Map<String, dynamic> toMap() {
          return {
               'text': text,
               'textEn': textEn,
               'textJa': textJa,
               'createdAt': createdAt,
               'posterName': posterName,
               'posterImageUrl': posterImageUrl,
               'posterId': posterId,
               'posterLocale': posterLocale,
               // 'reference': reference, reference は field に含めなくてよい
               // field に含めなくても DocumentSnapshot に reference が存在するため
          };
     }
     /// 投稿文
     final String text;

     /// 投稿文英語
     final String textEn;

     /// 投稿文日本語
     final String textJa;

     /// 投稿日時
     final Timestamp createdAt;

     /// 投稿者の名前
     final String posterName;

     /// 投稿者のアイコン画像URL
     final String posterImageUrl;

     /// 投稿者のユーザーID
     final String posterId;

     /// 投稿者の設定言語
     final String posterLocale;

     /// Firestoreのどこにデータが存在するかを表すpath情報
     final DocumentReference reference;
}