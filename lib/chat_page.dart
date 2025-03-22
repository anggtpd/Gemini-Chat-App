import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/chat_bubble.dart';


class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final GenerativeModel model;

  @override
  void initState() {
    super.initState();

    final apiKey = dotenv.env['GEMINI_API_KEY']; // Load key dynamically
    model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey!,
    );
  }

  
 Future<String> getTextFromImage(File photo, String message) async {
  try {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey!,
    );

    final prompt = TextPart(message);
    final imageParts = [
      DataPart('image/jpeg', await photo.readAsBytes()),
    ];
    final response = await model.generateContent([
      Content.multi([prompt, ...imageParts]),
    ]);

    print(response.text); // Log the response text
    return response.text ?? "No text generated";
  } catch (e) {
    print("Error: $e");
    return "Error occurred";
  }
}


  TextEditingController messageController = TextEditingController();
  TextEditingController message2Controller = TextEditingController();
  bool isLoading = false;

  List<ChatBubble> chatBubbles = [
    const ChatBubble(
      direction: Direction.left, 
      message: "Hi there, what's going on?", 
      type: BubbleType.alone)
  ];

  File? selectedImage; // Store the picked image

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Gemini AI', style: TextStyle(color: Colors.white)),
      backgroundColor: Color(0xff1C202A),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            reverse: true,
            padding: const EdgeInsets.all(10),
            children: chatBubbles.reversed.toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  
                  if (pickedFile != null) {
                    setState(() {
                      selectedImage = File(pickedFile.path);
                    });
                  }
                },
                icon: const Icon(Icons.add),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff303748),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Display picked image
                      if (selectedImage != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                selectedImage!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImage = null;
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          cursorColor: const Color(0xff077dfe),
                          style: const TextStyle(color: Colors.white),
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything',
                            hintStyle: TextStyle(color: Color(0xff7d88a1)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              isLoading
                  ? const CircularProgressIndicator(color: Color(0xff6058cc))
                  : IconButton(
                      icon: const Icon(Icons.send, color: Color(0xff6058cc)),
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });

                         chatBubbles = [
                      ...chatBubbles,
                      ChatBubble(
                        direction: Direction.right, 
                        message: messageController.text, 
                        type: BubbleType.alone,
                        photoUrl: selectedImage,
              )
                    ];

                        if (selectedImage != null) {
                          final String result = await getTextFromImage(
                              selectedImage!,
                              messageController.text);
                          chatBubbles.add(ChatBubble(
                              direction: Direction.left,
                              message: result,
                              type: BubbleType.alone,));
                        } else {
                          final content = [Content.text(messageController.text)];
                          final GenerateContentResponse response = await model.generateContent(content);
                          chatBubbles.add(ChatBubble(
                              direction: Direction.left,
                              message: response.text ??
                                  "Sorry, I don't understand",
                              type: BubbleType.alone));
                        }

                        messageController.clear();
                        selectedImage = null;

                        setState(() {
                          isLoading = false;
                        });
                      },
                    ),
            ],
          ),
        ),
      ],
    ),
  );
}
}