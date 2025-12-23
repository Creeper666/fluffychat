import 'package:flutter/material.dart';
import 'package:fluffychat/pages/gamestore/components/post_list_item.dart';

class NewPost extends StatefulWidget {
  const NewPost({super.key});


  @override
  State<NewPost> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<NewPost> {


  String imageUrl = "https://galgames.vip/wp-content/uploads/2025/11/image.png";
  String title = "一个十分长的标题测试测试测个十分长的标题测试测试测个十分长的标题测试测试测试";
  String summary = "This is a new post with a lot of description content. saki江post有很多的描述内容saki江post有很多的描述内容saki江";
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Image.network(imageUrl),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: PostListItem(
              imageUrl: imageUrl,
              title: title,
              date: "2023-01-01",
              summary: summary,
            ),
          ),
        ],
      ),
    );
  }
}