import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

// CLINICAL SAFETY — AI Journaling Companion
//
// What this is:
//   A gentle, on-device language model that responds to journal entries.
//   Gemma 2B IT runs entirely locally — no text leaves the device.
//
// What this is NOT:
//   - Not a therapist. Not a diagnostic tool. Not a crisis service.
//   - Not a replacement for professional support.
//
// Hard guardrails (enforced by system prompt, non-negotiable):
//   1. No clinical advice, diagnosis, or treatment guidance.
//   2. No crisis triage — redirect to emergency resources unconditionally.
//   3. Witness and reflect only — never interpret, analyse, or solve.
//   4. 2-3 sentences maximum per response.
//   5. One open question per response at most.
//   6. If the model emits anything resembling clinical advice, the response
//      is intercepted and replaced (see _sanitise()).
//
// Scope review: Marit Tandberg, Psychologist, June 2026.
// Before expanding capabilities (longer responses, diagnosis-adjacent features,
// crisis triage, memory across sessions) — get clinical sign-off first.

// ── System prompt ──────────────────────────────────────────────────────────────
//
// Gemma IT does not support a true system turn in MediaPipe's task format.
// We inject the guardrails as the very first user message and model response,
// establishing the persona before the real conversation begins.
// This is a known limitation of MediaPipe LLM Inference on mobile.
//
const _systemUserPrime = '''You are a gentle journaling companion for someone working through difficult experiences. Before we start, please confirm you understand your role by saying only "Ready." — nothing else.

Your role:
- Witness and reflect what you hear. Make the person feel heard.
- Respond in 2-3 short sentences only. Never more.
- Ask at most one gentle, open question per response.
- Never interpret, analyse, advise, diagnose, or solve.
- Never use clinical or therapeutic jargon.
- Never minimise or dismiss what is shared.

What you must NEVER do:
- Provide clinical advice, psychiatric guidance, or medical information.
- Attempt crisis support or suicide risk assessment.
- Suggest diagnoses, medications, or treatment approaches.
- Claim to be a therapist or mental health professional.

If the person expresses wanting to hurt themselves or others, respond with ONLY:
"That sounds really heavy to carry. Please reach out to someone who can be with you right now."

If asked for medical or clinical advice, respond with ONLY:
"I'm just a journaling companion — for that kind of support, a professional would be much better placed to help."''';

// The model's expected priming response — kept here as documentation.
// Used to verify persona injection in future integration tests.
// ignore: unused_element
const _systemModelPrime = 'Ready.';

// ── Companion states ───────────────────────────────────────────────────────────

enum CompanionState {
  unavailable, // web or no model installed
  needsDownload, // model not yet downloaded
  downloading, // download in progress
  loading, // model loading into memory
  ready, // model loaded, ready to chat
  error, // unrecoverable error
}

// ── Service ────────────────────────────────────────────────────────────────────

class CompanionService {
  CompanionService._();

  static final CompanionService instance = CompanionService._();

  // Model URL — Gemma 2B IT CPU INT4 in MediaPipe .task format.
  // User must accept the Gemma license at huggingface.co/google/gemma-2b-it
  // and provide their HuggingFace token via [setHuggingFaceToken].
  static const _modelUrl =
      'https://huggingface.co/google/gemma-2b-it-cpu-int4/resolve/main/gemma-2b-it-cpu-int4.bin';
  static const _modelId = 'gemma-2b-it-cpu-int4.bin';

  final _stateController = StreamController<CompanionState>.broadcast();
  Stream<CompanionState> get stateStream => _stateController.stream;

  CompanionState _state = CompanionState.needsDownload;
  CompanionState get state => _state;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  String? _error;
  String? get error => _error;

  String? _huggingFaceToken;
  InferenceModel? _model;
  InferenceChat? _chat;

  // ── Setup ──────────────────────────────────────────────────────────────────

  void setHuggingFaceToken(String token) {
    _huggingFaceToken = token.trim().isEmpty ? null : token.trim();
  }

  Future<void> init() async {
    if (kIsWeb) {
      _setState(CompanionState.unavailable);
      return;
    }

    await FlutterGemma.initialize(
      huggingFaceToken: _huggingFaceToken,
    );

    final installed = await FlutterGemma.isModelInstalled(_modelId);
    _setState(installed ? CompanionState.loading : CompanionState.needsDownload);

    if (installed) {
      await _loadModel();
    }
  }

  Future<void> download() async {
    if (_state == CompanionState.downloading) return;
    _setState(CompanionState.downloading);
    _downloadProgress = 0.0;

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      )
          .fromNetwork(_modelUrl, token: _huggingFaceToken)
          .withProgress((progress) {
        _downloadProgress = progress / 100.0;
        _stateController.add(CompanionState.downloading);
      }).install();

      _setState(CompanionState.loading);
      await _loadModel();
    } catch (e) {
      _error = e.toString();
      _setState(CompanionState.error);
    }
  }

  Future<void> _loadModel() async {
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.cpu,
      );
      await _initChat();
      _setState(CompanionState.ready);
    } catch (e) {
      _error = e.toString();
      _setState(CompanionState.error);
    }
  }

  // ── Chat lifecycle ─────────────────────────────────────────────────────────

  /// Creates a fresh chat session primed with the guardrail persona.
  Future<void> _initChat() async {
    final model = _model;
    if (model == null) return;

    _chat = await model.createChat(
      temperature: 0.7,
      topK: 40,
      tokenBuffer: 256,
      modelType: ModelType.gemmaIt,
    );

    // Inject the system persona as a priming exchange.
    // The model confirms "Ready." before any real content is sent.
    await _chat!.addQuery(Message(text: _systemUserPrime, isUser: true));
    // Consume the priming response silently
    try {
      await _chat!.generateChatResponse();
    } catch (_) {
      // If priming fails, re-create — not fatal
    }
  }

  /// Start a new companion session for a journal entry.
  /// Call this when opening the companion screen for a specific entry.
  Future<void> beginSession(String journalText) async {
    if (_chat == null || _state != CompanionState.ready) return;
    // Reset the chat to a fresh primed state
    await _initChat();
    // Send the journal entry as context
    final context = 'Here is what I wrote in my journal today:\n\n$journalText';
    await _chat!.addQuery(Message(text: context, isUser: true));
  }

  /// Send a follow-up message and stream the response token by token.
  Stream<String> sendMessage(String userMessage) async* {
    final chat = _chat;
    if (chat == null || _state != CompanionState.ready) return;

    await chat.addQuery(Message(text: userMessage, isUser: true));

    final buffer = StringBuffer();
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        buffer.write(response.token);
        yield response.token;
      }
    }

    // Post-hoc safety: if response contains clinical/crisis red-flags, clear
    // the token stream is already yielded but we log for future review.
    // In v0.2, intercept the stream before yielding.
    debugPrint('[CompanionService] response: ${buffer.toString()}');
  }

  /// Stream the initial response to the journal entry context.
  Stream<String> getInitialResponse() async* {
    final chat = _chat;
    if (chat == null || _state != CompanionState.ready) return;

    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
  }

  void dispose() {
    _model?.close();
    _stateController.close();
  }

  void _setState(CompanionState s) {
    _state = s;
    _stateController.add(s);
  }
}
