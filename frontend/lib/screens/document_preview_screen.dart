import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document.dart';
import '../config/api_config.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final Document document;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // On web, open document in new tab instead of using WebView
      final baseUri = Uri.parse(ApiConfig.baseUrl);
      final fileUri = baseUri.resolve(widget.document.fileUrl ?? '');
      launchUrl(fileUri, mode: LaunchMode.externalApplication);
      // Close the preview screen after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final fileUri = baseUri.resolve(widget.document.fileUrl ?? '');

    _controller = WebViewController();
    
    _controller!
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load document: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(fileUri);
  }

  Future<void> _downloadDocument() async {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final fileUri = baseUri.resolve(widget.document.fileUrl ?? '');

    try {
      final success = await launchUrl(
        fileUri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download document. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.document.originalFilename ?? widget.document.fileName ?? 'Document';
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final fileUri = baseUri.resolve(widget.document.fileUrl ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(filename),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download',
            onPressed: _downloadDocument,
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (_controller != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        _controller!.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await launchUrl(
                        fileUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to open document in external app')),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open in Browser'),
                  ),
                ],
              ),
            )
          : _controller == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Opening document in new tab...'),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller!),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
    );
  }
}
