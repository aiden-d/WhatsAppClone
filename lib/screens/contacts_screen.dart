import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;
String userEmail;

class ContactScreen extends StatefulWidget {
  final String emailID;
  static const String id = 'chat_screen';
  ContactScreen({@required this.emailID});
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String searchText;

  @override
  void initState() {
    userEmail = widget.emailID;
    print('userEmail = $userEmail');
    super.initState();
    getCurrentUser();
    createUserCollection();
  }

  void createUserCollection() async {
    try {
      _firestore.collection(userEmail).document(userEmail).setData({
        "text": 'value',
        'created_at': FieldValue.serverTimestamp(),
        'sender':
            'me' //your data which will be added to the collection and collection will be created after this
      }).then((_) {
        print("collection created");
      }).catchError((_) {
        print("an error occured");
      });
    } catch (e) {
      print(e);
    }
    messagesStream();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection(userEmail).snapshots()) {
      //print(snapshot.documents.toString());
      for (var message in snapshot.documents) {
        print(message.documentID);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),

      ),
      body: Container(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                decoration: kContactFinderContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageTextController,
                        onChanged: (value) {
                          searchText = value;
                          //Do something with the user input.
                        },
                        decoration: kContactFinderTextDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () async {
                        final snapshot = await _firestore
                            .collection(searchText.trim())
                            .getDocuments();
                        if (snapshot.documents.length == 0) {
                          print('doesnt exist');
                          //doesnt exist
                        } else {
                          print(
                              'contact exists pushing user: $userEmail + contact: $searchText');
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return ChatScreen(
                              contactID: searchText.trim(),
                              userID: userEmail,
                            );
                          }));
                        }
//                        _firestore.collection('messages').add({
//                          'text': searchText,
//                          'sender': loggedInUser.email,
//                          'created_at': FieldValue.serverTimestamp(),
//                        });

//                      Implement send functionality.
                      },
                      child: Text(
                        'Chat',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
              ContactsStream(),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactsStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(userEmail).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<ContactBox> messageBubbles = [];
        for (var message in messages) {
          //final messageText = message.data['text'];
          //TODO Make the current sender message invisble
          //final messageSender = message.data['sender'];
          //final currrentUser = loggedInUser.email;
          // bool isMe;
//          if (currrentUser == messageSender) {
//            isMe = true;
//          } else {
//            isMe = false;
//          }
          if (message.documentID != userEmail) {
            final messageBubble = ContactBox(
              contactName: message.documentID,
              lastMessage: 'Hello! how are you',
            );
            messageBubbles.add(messageBubble);
          }
        }
        return Expanded(
          child: ListView(
            reverse: false,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class ContactBox extends StatelessWidget {
  ContactBox({@required this.contactName, @required this.lastMessage});
  final String contactName;
  final String lastMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MaterialButton(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  contactName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  lastMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ChatScreen(
                contactID: contactName,
                userID: userEmail,
              );
            }));
          },
        ),
      ],
    );
  }
}
