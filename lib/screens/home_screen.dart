import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:zia/constants/pallet.dart';
import 'package:zia/services/openai_service.dart';
import 'package:zia/widgets/feature_box.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  String lastWords = '';
  String? generatedContent;
  String? generatedImage;
  final OpenAPIService openAPIService = OpenAPIService();
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]);
    await flutterTts.setSharedInstance(true);
  }

  Future<void> initSpeechToText() async {
    print('DEBUG: INIT SpeachToText');
    await speechToText.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    print('DEBUG: INIT startListening:${speechToText.isListening}');
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {
      speechEnabled = true;
    });
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {
      speechEnabled = false;
    });
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  Future<void> systemSpeakStop() async {
    await flutterTts.stop();
  }

  @override
  void dispose() {
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zia'),
        leading: const Icon(Icons.menu),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Stack(
            children: [
              // Profile virtual assistant pic
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                      color: Pallete.assistantCircleColor,
                      shape: BoxShape.circle),
                ),
              ),
              Container(
                height: 123,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image:
                            AssetImage('assets/images/virtualAssistant.png'))),
              )
            ],
          ),

        Visibility(
            visible: lastWords !='' ,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              margin: EdgeInsets.symmetric(horizontal: 40).copyWith(top: 30),
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Pallete.borderColor,
                  ),
                  borderRadius:
                      BorderRadius.circular(20).copyWith(topLeft: Radius.zero)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                    lastWords,
                  style: TextStyle(
                      fontSize: generatedContent == null ? 25 : 18,
                      fontFamily: 'Cera Pro'),
                ),
              ),
            ),
          ),


          // Chat bubble
          Visibility(
            visible: generatedImage == null && lastWords == '' ,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              margin: EdgeInsets.symmetric(horizontal: 40).copyWith(top: 30),
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Pallete.borderColor,
                  ),
                  borderRadius:
                      BorderRadius.circular(20).copyWith(topLeft: Radius.zero)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  generatedContent == null
                      ? 'Good Morning, what i can do you ?'
                      : generatedContent!,
                  style: TextStyle(
                      fontSize: generatedContent == null ? 25 : 18,
                      fontFamily: 'Cera Pro'),
                ),
              ),
            ),
          ),


          

          if(generatedImage != null) 
            Container(child: Image.network(generatedImage!), padding:  const EdgeInsets.symmetric(vertical: 10),),
        
          // suggestions
          Visibility(
            visible: generatedContent == null && generatedImage == null,
            child: Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 10, left: 22),
              child: const Text(
                'Here are few commands',
                style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Cera Pro',
                    color: Pallete.mainFontColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // feature list

          Visibility(
            visible: generatedContent == null && generatedImage == null,
            child: const Column(
              children: [
                FeatureBox(
                  color: Pallete.firstSuggestionBoxColor,
                  headerText: 'ChatGPT',
                  descriptionText:
                      'A smarter way to stay organized and informed with ChatGPT',
                ),
                FeatureBox(
                  color: Pallete.secondSuggestionBoxColor,
                  headerText: 'Dall-E',
                  descriptionText:
                      'Get inspired and stay creative with your personal assistant powered by Dall-E',
                ),
                FeatureBox(
                    color: Pallete.thirdSuggestionBoxColor,
                    headerText: 'Smart voice assistant',
                    descriptionText:
                        'Get inspired and stay creative with ypur personal assistant powered by Dall-E and ChatGPT'),
              ],
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Pallete.firstSuggestionBoxColor,
          onPressed: () async {
            if (await speechToText.hasPermission &&
                speechToText.isNotListening) {
              await systemSpeakStop();
              await startListening();
            } else if (speechToText.isListening) {
              await stopListening();
              final speech = await openAPIService.isArtPromptAPI(lastWords);
              if (speech.contains('https')) {
                generatedImage = speech;
                setState(() {});
                generatedContent = null;
              } else {
                generatedImage = null;
                generatedContent = speech;
                setState(() {});
                await systemSpeak(speech);
              }
            } else {
              initSpeechToText();
            }
          },
          tooltip: 'Listen',
          child: Icon(speechToText.isNotListening ? Icons.mic_off : Icons.mic)),
    );
  }
}
