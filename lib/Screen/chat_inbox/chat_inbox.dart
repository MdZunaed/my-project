import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frog_chat/Screen/chat_inbox/inbox_element.dart';
import 'package:frog_chat/main.dart';
import 'package:frog_chat/models/InboxModel.dart';
import 'package:frog_chat/models/UserModel.dart';
import 'package:frog_chat/models/firebase_helper.dart';
import 'package:frog_chat/models/messageModel.dart';
import 'package:frog_chat/style.dart';

class ChatInbox extends StatefulWidget {
  final UserModel targetuser;
  final User firebaseUser;
  final InboxModel inbox;

  const ChatInbox(
      {super.key,
      required this.targetuser,
      required this.inbox,
      required this.firebaseUser});

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  TextEditingController msgController = TextEditingController();

  void sendMsg() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    UserModel? userModel =
        await FirebaseHelper.userModelByUid(currentUser!.uid);
    String msg = msgController.text.trim();
    msgController.clear();
    if (msg != null) {
      MessageModel newMessage = MessageModel(
        messageId: uuid.v1(),
        sender: userModel!.uid,
        creratedOn: DateTime.now().toString(),
        text: msg,
        seen: false,
      );
      FirebaseFirestore.instance
          .collection("inboxes")
          .doc(widget.inbox.inboxId)
          .collection("messages")
          .doc(newMessage.messageId)
          .set(newMessage.toMap());
      widget.inbox.lastMessage = msg;
      FirebaseFirestore.instance
          .collection("inboxes")
          .doc(widget.inbox.inboxId)
          .set(widget.inbox.toMap());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: kBgColor,
          title: InboxAppbar(
            name: widget.targetuser.name.toString(),
            imageUrl: widget.targetuser.pic.toString(),
          )),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8).r,
        child: Column(children: [
          Expanded(
              child: Container(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("inboxes")
                  .doc(widget.inbox.inboxId)
                  .collection("messages")
                  .orderBy("createdOn", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;
                    return ListView.builder(
                      reverse: true,
                      itemCount: dataSnapshot.docs.length,
                      itemBuilder: (context, index) {
                        MessageModel currentMessage = MessageModel.fromMap(
                            dataSnapshot.docs[index].data()
                                as Map<String, dynamic>);
                        return Row(
                          mainAxisAlignment:
                              (currentMessage.sender == widget.targetuser.uid)
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.end,
                          children: [
                            Container(
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: (currentMessage.sender ==
                                            widget.targetuser.uid)
                                        ? kDarkColor
                                        : kPrimaryColor),
                                child: Text(
                                  currentMessage.text.toString(),
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      color: (currentMessage.sender ==
                                              widget.targetuser.uid)
                                          ? kWhiteColor
                                          : kDarkColor,
                                      fontWeight: FontWeight.w500),
                                )),
                          ],
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    const Center(
                      child: Text("Error! PLease check your internet."),
                    );
                  } else {
                    Center(
                      child: Text("Say Hi to ${widget.targetuser.name}"),
                    );
                  }
                } else {
                  const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Container();
              },
            ),
          )),
          InboxNavbar(
            controller: msgController,
            onTap: () => sendMsg(),
          ),
        ]),
      )),
    );
  }
}
