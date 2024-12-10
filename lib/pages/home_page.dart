import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();

  String? recordingPath;
  String transcriptedText = '';
  bool isRecording = false, isPlaying = false;

  Future<void> hitFlaskApi() async {
    const String url =
        'http://10.0.2.2:5000/test'; // Replace with your Flask API URL if different
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response from Flask API: $data');
      } else {
        print('Failed to hit API. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Future<void> sendAudioToAPI(
  //     String filePath, int surahNumber, int ayahNumber) async {
  //   try {
  //     final url = Uri.parse('http://192.168.100.21:5000/transcribe');

  //     final file = File(filePath);

  //     // Validate that the file is an MP3
  //     if (!filePath.endsWith('.mp3')) {
  //       throw Exception(
  //           "The file is not in MP3 format. Please provide a valid MP3 file.");
  //     }

  //     final fileBytes = await file.readAsBytes();

  //     // Create multipart request
  //     final request = http.MultipartRequest('POST', url);
  //     print('--------------------inside function-----------');

  //     request.files.add(http.MultipartFile.fromBytes(
  //       'audio',
  //       fileBytes,
  //       filename: basename(file.path),
  //       contentType:
  //           MediaType('audio', 'mpeg'), // Set content type as audio/mpeg (MP3)
  //     ));

  //     // Add the other fields (Surah number and Ayah number)
  //     request.fields['surah_number'] = surahNumber.toString();
  //     request.fields['ayah_number'] = ayahNumber.toString();

  //     print('--------------------inside function 111-----------');

  //     // Send the request
  //     final response = await request.send();
  //     print(
  //         '\n--------------------response status ${response.statusCode}-----------\n');

  //     if (response.statusCode == 200) {
  //       // Read the response body
  //       final responseBody = await response.stream.bytesToString();
  //       print('\n--------------------response body-----------\n');

  //       print("----------------Response from API: $responseBody");
  //       var jsonResponse = jsonDecode(responseBody);
  //       print(jsonResponse);
  //       print(jsonResponse['transcription']);
  //       transcriptedText = jsonResponse['transcription'];
  //       setState(() {});
  //     } else {
  //       print(
  //           '===============Failed to send the audio. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print("====================Error sending audio to API: $e");
  //   }
  // }

  Future<void> sendQaidaAudioToAPI(String filePath, String letter) async {
    try {
      final url = Uri.parse('http://192.168.100.21:5000/qaida');

      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', url);
      print('--------------------inside function-----------');
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        fileBytes,
        filename: basename(file.path),
        contentType: MediaType('audio', 'wav'),
      ));

      request.fields['letter'] = letter;

      print('--------------------inside function    111-----------');

      // Send the request
      final response = await request.send();
      print(
          '\n--------------------response status ${response.statusCode}-----------\n');

      if (response.statusCode == 200) {
        // Read the response body
        final responseBody = await response.stream.bytesToString();
        print('\n--------------------response body-----------\n');

        print("----------------Response from API: $responseBody");
        var jsonResponse = jsonDecode(responseBody);
        print(jsonResponse);
        print(jsonResponse['transcription']);
        transcriptedText = jsonResponse['transcription'];
        setState(() {});
      } else {
        print(
            '===============Failed to send the audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("====================Error sending audio to API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _recordingButton(),
      body: _buildUI(context),
    );
  }

  Widget _buildUI(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (recordingPath != null)
            MaterialButton(
              onPressed: () async {
                if (audioPlayer.playing) {
                  audioPlayer.stop();
                  setState(() {
                    isPlaying = false;
                  });
                } else {
                  await audioPlayer.setFilePath(recordingPath!);
                  audioPlayer.play();
                  setState(() {
                    isPlaying = true;
                  });
                }
              },
              color: Theme.of(context).colorScheme.primary,
              child: Text(
                isPlaying
                    ? "Stop Playing Recording"
                    : "Start Playing Recording",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          if (recordingPath == null)
            const Text(
              "No Recording Found. :(",
            ),
          TextButton(
              onPressed: () => hitFlaskApi(), child: Text('Hit GET API')),
          Text(transcriptedText)
        ],
      ),
    );
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();
          if (filePath != null) {
            setState(() {
              isRecording = false;
              recordingPath = filePath;
            });
            print('-------------${recordingPath!}');

            String letter = 'ا';
            // int surahNumber = 1;
            // int ayahNumber = 4;
            // await sendAudioToAPI(recordingPath!, surahNumber, ayahNumber);
            await sendQaidaAudioToAPI(recordingPath!, letter);
          }
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory appDocumentsDir =
                await getApplicationDocumentsDirectory();
            final String filePath =
                p.join(appDocumentsDir.path, "recording.wav");
            await audioRecorder.start(
              const RecordConfig(),
              path: filePath,
            );
            setState(() {
              isRecording = true;
              recordingPath = null;
            });
          }
        }
      },
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
      ),
    );
  }
}
