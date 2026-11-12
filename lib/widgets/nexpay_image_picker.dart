import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';

class NexPayImageUploader extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final double previewHeight;

  const NexPayImageUploader({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.previewHeight = 140,
  });

  @override
  State<NexPayImageUploader> createState() => _NexPayImageUploaderState();
}

class _NexPayImageUploaderState extends State<NexPayImageUploader> {
  late TextEditingController _urlCtrl;
  String _currentValue = '';
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.trim();
    _urlCtrl = TextEditingController(
      text: _currentValue.startsWith('data:image') ? '[Uploaded Gallery Image]' : _currentValue,
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isPicking = true);
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'png';
          final mime = (ext == 'jpg' || ext == 'jpeg')
              ? 'image/jpeg'
              : (ext == 'webp' ? 'image/webp' : 'image/png');
          final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
          setState(() {
            _currentValue = dataUri;
            _urlCtrl.text = '[Gallery File: ${file.name}]';
          });
          widget.onChanged(dataUri);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image pick error: $e'),
            backgroundColor: AppConstants.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            color: AppConstants.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                onChanged: (v) {
                  final trimmed = v.trim();
                  if (!trimmed.startsWith('[')) {
                    setState(() => _currentValue = trimmed);
                    widget.onChanged(trimmed);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Upload from Gallery or paste https:// image link',
                  prefixIcon: Icon(Icons.image_outlined, size: 18),
                  suffixIcon: _currentValue.isNotEmpty
                      ? IconButton(
                    tooltip: 'Clear Image',
                    icon: Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      setState(() {
                        _currentValue = '';
                        _urlCtrl.clear();
                      });
                      widget.onChanged('');
                    },
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isPicking ? null : _pickFromGallery,
              icon: _isPicking
                  ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Icon(Icons.photo_library_rounded, size: 17),
              label: Text('Upload Gallery'),
            ),
          ],
        ),
        if (_currentValue.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            height: widget.previewHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderStrong),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: NexPaySmartImage(source: _currentValue, fit: BoxFit.contain),
            ),
          ),
        ],
      ],
    );
  }
}

/// Renders both Base64 Data URIs (from Gallery Upload) and Network URLs seamlessly
class NexPaySmartImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final Widget? fallback;

  const NexPaySmartImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final s = source.trim();
    if (s.isEmpty) {
      return fallback ?? Icon(Icons.image_outlined, color: AppConstants.textMuted);
    }
    try {
      if (s.startsWith('data:image')) {
        final b64 = s.split(',').last;
        return Image.memory(base64Decode(b64), fit: fit);
      }
      if (s.startsWith('http://') || s.startsWith('https://')) {
        return Image.network(
          s,
          fit: fit,
          errorBuilder: (_, __, ___) =>
          fallback ?? Icon(Icons.broken_image_outlined, color: AppConstants.textMuted),
        );
      }
      return Image.memory(base64Decode(s), fit: fit);
    } catch (_) {
      return fallback ?? Icon(Icons.broken_image_outlined, color: AppConstants.textMuted);
    }
  }
}