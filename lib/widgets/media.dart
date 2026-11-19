import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/config.dart';
import '../core/theme.dart';
import 'common.dart';

// ------------------------------------------------------------------ Images

/// Network image for an API media path (`/uploads/...`) with placeholder and error state.
class NetImage extends StatelessWidget {
  const NetImage(this.path, {super.key, this.fit = BoxFit.cover, this.radius = 0, this.width, this.height});
  final String? path;
  final BoxFit fit;
  final double radius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.media(path);
    Widget placeholder([IconData icon = Icons.image_outlined]) => Container(
          width: width,
          height: height,
          color: AppColors.surfaceDark,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textFaint, size: 28),
        );
    final child = url.isEmpty
        ? placeholder(Icons.home_work_outlined)
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            width: width,
            height: height,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, _) => placeholder(),
            errorWidget: (_, _, _) => placeholder(Icons.broken_image_outlined),
          );
    return radius > 0 ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: child) : child;
  }
}

/// Image from either a local file path or an API path.
class AnyImage extends StatelessWidget {
  const AnyImage(this.source, {super.key, this.radius = 0, this.fit = BoxFit.cover});
  final String source;
  final double radius;
  final BoxFit fit;

  bool get isLocal => !source.startsWith('/uploads') && !source.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (!isLocal) return NetImage(source, radius: radius, fit: fit);
    final img = Image.file(File(source), fit: fit, width: double.infinity, height: double.infinity);
    return radius > 0 ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: img) : img;
  }
}

/// Fullscreen zoomable photo viewer.
void openPhotoViewer(BuildContext context, List<String> photos, int initial) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _PhotoViewer(photos: photos, initial: initial),
  ));
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos, required this.initial});
  final List<String> photos;
  final int initial;
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}', style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: AnyImage(widget.photos[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

/// Swipeable photo carousel with page dots. Tapping opens the fullscreen viewer.
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.photos, this.height = 260, this.radius = 24, this.showArrows = false, this.footer});
  final List<String> photos;
  final double height;
  final double radius;
  final bool showArrows;

  /// Optional widget shown between the arrows (e.g. date label on project detail).
  final Widget? footer;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant PhotoCarousel old) {
    super.didUpdateWidget(old);
    if (old.photos != widget.photos && _index >= widget.photos.length) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.photos.length - 1);
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < photos.length.clamp(0, 8); i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _index ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _index ? AppColors.black : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: photos.isEmpty
              ? NetImage(null, radius: widget.radius)
              : PageView.builder(
                  controller: _controller,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => openPhotoViewer(context, photos, i),
                    child: AnyImage(photos[i], radius: widget.radius),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        if (widget.showArrows)
          Row(
            children: [
              CircleIconButton(icon: Icons.chevron_left, tooltip: 'Previous photo', onTap: _index > 0 ? () => _go(-1) : null),
              const SizedBox(width: 12),
              if (widget.footer != null) widget.footer!,
              Expanded(child: Center(child: photos.length > 1 ? dots : const SizedBox.shrink())),
              CircleIconButton(icon: Icons.chevron_right, tooltip: 'Next photo', onTap: _index < photos.length - 1 ? () => _go(1) : null),
            ],
          )
        else if (photos.length > 1)
          dots,
      ],
    );
  }
}

// ------------------------------------------------------------------ Picking photos

final _picker = ImagePicker();

Future<List<String>> pickPhotos(BuildContext context, {required bool camera, int max = 10}) async {
  try {
    if (camera) {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 2000);
      return x == null ? [] : [x.path];
    }
    final xs = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 2000, limit: max > 1 ? max : null);
    return xs.take(max).map((x) => x.path).toList();
  } catch (e) {
    if (context.mounted) showSnack(context, 'Could not open ${camera ? 'camera' : 'gallery'}: $e', error: true);
    return [];
  }
}

/// Dashed "Add photos  1 / 10 photos  [Camera] [Gallery]" box with thumbnails.
class PhotoPickerBox extends StatelessWidget {
  const PhotoPickerBox({super.key, required this.photos, required this.onChanged, this.max = 10, this.existing = const [], this.onRemoveExisting});
  final List<String> photos; // local file paths
  final ValueChanged<List<String>> onChanged;
  final int max;
  final List<String> existing; // already uploaded (edit mode)
  final ValueChanged<String>? onRemoveExisting;

  int get _count => photos.length + existing.length;

  Future<void> _add(BuildContext context, bool camera) async {
    final remaining = max - _count;
    if (remaining <= 0) {
      showSnack(context, 'You can add up to $max photos');
      return;
    }
    final picked = await pickPhotos(context, camera: camera, max: remaining);
    if (picked.isNotEmpty) onChanged([...photos, ...picked.take(remaining)]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomPaint(
          painter: _DashedBorderPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                const Icon(Icons.add_photo_alternate_outlined, size: 36),
                const SizedBox(height: 10),
                const Text('Add photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('$_count / $max photos', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: AppButton(label: 'Camera', icon: Icons.photo_camera_outlined, style: AppButtonStyle.outline, height: 46, onPressed: () => _add(context, true))),
                    const SizedBox(width: 10),
                    Expanded(child: AppButton(label: 'Gallery', icon: Icons.photo_library_outlined, style: AppButtonStyle.outline, height: 46, onPressed: () => _add(context, false))),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_count > 0) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in existing) _Thumb(source: p, onRemove: onRemoveExisting == null ? null : () => onRemoveExisting!(p)),
                for (final p in photos) _Thumb(source: p, onRemove: () => onChanged([...photos]..remove(p))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.source, this.onRemove});
  final String source;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          SizedBox(width: 88, height: 88, child: AnyImage(source, radius: 14)),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textFaint
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------------ Voice notes

/// Records up to [maxDuration] of audio and reports the saved file path.
class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({super.key, required this.onRecorded, this.path, this.maxDuration = const Duration(minutes: 2), this.compact = false});
  final ValueChanged<String?> onRecorded;
  final String? path; // current recording, if any
  final Duration maxDuration;
  final bool compact; // small round mic button only

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _recording = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) return _stop();
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) showSnack(context, 'Microphone permission is needed to record', error: true);
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000), path: file);
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= widget.maxDuration) _stop();
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Could not start recording: $e', error: true);
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    widget.onRecorded(path);
  }

  String get _clock => '${_elapsed.inMinutes}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return CircleIconButton(
        icon: _recording ? Icons.stop : (widget.path != null ? Icons.mic : Icons.mic_none),
        size: 52,
        dark: _recording || widget.path != null,
        tooltip: _recording ? 'Stop recording ($_clock)' : 'Record voice note',
        onTap: _toggle,
      );
    }
    if (widget.path != null && !_recording) {
      return Row(
        children: [
          Expanded(child: VoiceNotePlayer(source: widget.path!)),
          const SizedBox(width: 8),
          CircleIconButton(icon: Icons.delete_outline, tooltip: 'Delete recording', onTap: () => widget.onRecorded(null)),
        ],
      );
    }
    return Column(
      children: [
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: _recording ? AppColors.red : AppColors.black, shape: BoxShape.circle),
            child: Icon(_recording ? Icons.stop_rounded : Icons.mic_none_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 10),
        Text(_recording ? 'Recording $_clock · tap to stop' : 'Tap the mic to start', style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// Simple play/pause audio bar for a local file or an uploaded voice note.
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key, required this.source});
  final String source;
  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    _subs.add(_player.onPlayerStateChanged.listen((s) => mounted ? setState(() => _state = s) : null));
    _subs.add(_player.onPositionChanged.listen((p) => mounted ? setState(() => _pos = p) : null));
    _subs.add(_player.onDurationChanged.listen((d) => mounted ? setState(() => _dur = d) : null));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_state == PlayerState.playing) {
        await _player.pause();
      } else if (_state == PlayerState.paused) {
        await _player.resume();
      } else {
        final src = widget.source;
        final isRemote = src.startsWith('/uploads') || src.startsWith('http');
        await _player.play(isRemote ? UrlSource(AppConfig.media(src)) : DeviceFileSource(src));
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Could not play voice note', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _state == PlayerState.playing;
    final progress = _dur.inMilliseconds == 0 ? 0.0 : _pos.inMilliseconds / _dur.inMilliseconds;
    String fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleIconButton(icon: playing ? Icons.pause : Icons.play_arrow, dark: true, size: 36, tooltip: playing ? 'Pause' : 'Play', onTap: _toggle),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 4, backgroundColor: AppColors.surfaceDark, color: AppColors.orange),
            ),
          ),
          const SizedBox(width: 10),
          Text(_dur == Duration.zero ? 'Voice note' : fmt(playing || _pos > Duration.zero ? _pos : _dur), style: AppText.small),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
