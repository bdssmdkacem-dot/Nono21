import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() => runApp(const Nono21App());

class Nono21App extends StatelessWidget {
  const Nono21App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nono21',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const GeneratePage(),
    );
  }
}

class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  final promptController = TextEditingController(
    text: 'Panning wide shot of a calico kitten sleeping in the sunshine',
  );
  final serverController = TextEditingController(text: 'http://10.0.2.2:8000');
  VideoPlayerController? videoController;
  Timer? timer;
  String status = 'Ready';
  String? imageUrl;
  String? videoUrl;
  bool busy = false;

  @override
  void dispose() {
    timer?.cancel();
    videoController?.dispose();
    promptController.dispose();
    serverController.dispose();
    super.dispose();
  }

  String baseUrl() => serverController.text.trim().replaceAll(RegExp(r'/$'), '');

  Future<void> generate() async {
    if (busy) return;
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      busy = true;
      status = 'Starting...';
      imageUrl = null;
      videoUrl = null;
    });
    await videoController?.dispose();
    videoController = null;

    try {
      final response = await http.post(
        Uri.parse('${baseUrl()}/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );
      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final jobId = data['job_id'] as String;
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 3), (_) => poll(jobId));
      await poll(jobId);
    } catch (e) {
      setState(() {
        busy = false;
        status = 'Error: ${e}';
      });
    }
  }

  Future<void> poll(String jobId) async {
    try {
      final response = await http.get(Uri.parse('${baseUrl()}/jobs/${jobId}'));
      if (response.statusCode != 200) throw Exception('Status ${response.statusCode}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final state = data['status'] as String? ?? 'unknown';
      final message = data['message'] as String? ?? state;

      if (!mounted) return;
      setState(() {
        status = message;
        if (data['image_url'] != null) {
          imageUrl = '${baseUrl()}${data['image_url']}';
        }
      });

      if (state == 'completed') {
        timer?.cancel();
        final url = '${baseUrl()}${data['video_url']}';
        setState(() {
          videoUrl = url;
          busy = false;
        });
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await controller.initialize();
        if (!mounted) {
          controller.dispose();
          return;
        }
        setState(() => videoController = controller);
        await controller.play();
      } else if (state == 'failed') {
        timer?.cancel();
        setState(() {
          busy = false;
          status = 'Error: $message';
        });
      }
    } catch (e) {
      if (mounted) setState(() => status = 'Connection: ${e}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = videoController;
    return Scaffold(
      appBar: AppBar(title: const Text('Nono21')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: serverController,
            decoration: const InputDecoration(
              labelText: 'Nono21 server URL',
              hintText: 'http://192.168.1.10:8000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: promptController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : generate,
            icon: const Icon(Icons.movie_creation),
            label: Text(busy ? 'Generating...' : 'Generate'),
          ),
          const SizedBox(height: 16),
          Text(status, style: Theme.of(context).textTheme.bodyLarge),
          if (imageUrl != null) ...[
            const SizedBox(height: 16),
            const Text('Nano Banana 2 image'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl!, errorBuilder: (_, __, ___) => const Text('Image unavailable')),
            ),
          ],
          if (controller != null && controller.value.isInitialized) ...[
            const SizedBox(height: 16),
            const Text('Veo 3.1 video'),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            VideoProgressIndicator(controller, allowScrubbing: true),
            IconButton(
              onPressed: () => setState(() {
                controller.value.isPlaying ? controller.pause() : controller.play();
              }),
              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ],
          if (videoUrl != null)
            SelectableText('\nVideo URL:\n${videoUrl}'),
        ],
      ),
    );
  }
}
