import 'package:flash_chat/screens/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;
int latestMessage;

class ChatScreen extends StatefulWidget {
  final String contactID;
  final String userID;
  ChatScreen({@required this.contactID, @required this.userID});
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messageText;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text(widget.contactID),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(
              contactID: widget.contactID,
              userID: widget.userID,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      messageTextController.clear();
//                      _firestore.collection('messages').add({
//                        'text': messageText,
//                        'sender': loggedInUser.email,
//                      });
                      CollectionReference user1 =
                          _firestore.collection(widget.userID);
                      CollectionReference user2 =
                          _firestore.collection(widget.contactID);
                      DocumentSnapshot ds =
                          await user1.document(widget.contactID).get();

                      /////////////////////
                      if (!ds.exists) {
                        print('document is null');
                        user1.document(widget.contactID).setData({
                          'message$latestMessage': messageText,
                          'sender$latestMessage': widget.userID,
                        })
                          ..then((value) => print("User Added")).catchError(
                              (error) => print("Failed to add user: $error"));
                        //////////////////
                        user2.document(widget.userID).setData({
                          'message$latestMessage': messageText,
                          'sender$latestMessage': widget.userID,
                        })
                          ..then((value) => print("User Added")).catchError(
                              (error) => print("Failed to add user: $error"));
                      }
                      ////////////////
                      else {
                        user1.document(widget.contactID).updateData({
                          'message$latestMessage': messageText,
                          'sender$latestMessage': widget.userID,
                        })
                          ..then((value) => print("User Added")).catchError(
                              (error) => print("Failed to add user: $error"));
                        ///////////////
                        user2.document(widget.userID).updateData({
                          'message$latestMessage': messageText,
                          'sender$latestMessage': widget.userID,
                        })
                          ..then((value) => print("User Added")).catchError(
                              (error) => print("Failed to add user: $error"));
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final String contactID;
  final String userID;
  MessagesStream({@required this.contactID, @required this.userID});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection(userID).document(contactID).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data;
        List<MessageBubble> messageBubbles = [];
        bool b = true;
        int i = 0;
        while (b == true) {
          print('int i = $i');
          String currentMessage;
          String currentSender;
          try {
            currentMessage = messages.data['message$i'];
            currentSender = messages.data['sender$i'];
            print(currentMessage);
            print(currentSender);
          } catch (e) {
            print('yeet');
            print(e);
            b = false;
          }

          if (currentMessage != null) {
            bool isMe = false;
            if (currentSender == userID) {
              isMe = true;
            }
            final messageBubble = MessageBubble(
                sender: currentSender, text: currentMessage, isMe: isMe);
            messageBubbles.add(messageBubble);
            i++;
          } else {
            b = false;
          }
        }
        //TODO make sure that there are not errors because of the latest message conflict
        latestMessage = i;

//        for (var message in messages) {
//          final messageText = message.data['text'];
//          final messageSender = message.data['sender'];
//
//          final currentUser = loggedInUser.email;
//
//          final messageBubble = MessageBubble(
//            sender: messageSender,
//            text: messageText,
//            isMe: currentUser == messageSender,
//          );
//
//          messageBubbles.add(messageBubble);
//        }
        return Expanded(
          child: ListView(
            reverse: false,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
//          Text(
//            sender,
//            style: TextStyle(
//              fontSize: 12.0,
//              color: Colors.black54,
//            ),
//          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
