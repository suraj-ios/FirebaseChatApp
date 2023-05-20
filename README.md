# FirebaseChatApp

Create firebase account
Add One Demo Account
Add Google info plist file into the Projects
Start Chating...

# Firebase Structure:

|- Chats (Collection)
| — AutoID (Document)
| —- users (Field {Array})
| —- thread(Collection)
| — — AutoID (Document)
| — —- content (Field {String})
| — —- created (Field {DateTime})
| — —- id (Field {String})
| — —- senderID (Field {String})
| — —- senderName (Field {String})
