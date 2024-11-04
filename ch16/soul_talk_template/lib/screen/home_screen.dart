import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:isar/isar.dart';
import 'package:soul_talk_template/component/chat_text_field.dart';
import 'package:soul_talk_template/component/date_divider.dart';
import 'package:soul_talk_template/component/logo.dart';
import 'package:soul_talk_template/component/message.dart';
import 'package:soul_talk_template/const/const.dart';
import 'package:soul_talk_template/model/message_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isRunning = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }

  void _initializeListeners() {
    controller.addListener(() {
      if (error != null) {
        setState(() => error = null);
      }
    });
  }

  void _scrollToBottom() {
    if (scrollController.position.pixels != scrollController.position.maxScrollExtent) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> sendMessageToGemini() async {
    int? currentModelMessageId;
    int? currentUserMessageId;

    final isar = GetIt.I<Isar>();
    final currentPrompt = controller.text;

    try {
      setState(() {
        isRunning = true;
      });
      controller.clear();

      final myMessagesCount = await isar.messageModels.filter().isMineEqualTo(true).count();

      currentUserMessageId = await isar.writeTxn(() async {
        return await isar.messageModels.put(
          MessageModel()
            ..isMine = true
            ..message = currentPrompt
            ..point = myMessagesCount + 1
            ..date = DateTime.now(),
        );
      });

      final contextMessages = await isar.messageModels.where().limit(5).findAll();

      final List<Content> promptContext = contextMessages
          .map(
            (e) => Content(
              e.isMine! ? 'user' : 'model',
              [
                TextPart(e.message!),
              ],
            ),
          )
          .toList();

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: GEMINI_API_KEY,
        systemInstruction:
            Content.system('너는 이제부터 착하고 친절한 친구의 역할을 할거야. 앞으로 채팅을 하면서 긍정적인 말만 할 수 있도록 해줘. 이 메세지는 기억만 하고 여기엔 대답할 필요 없어.'),
      );

      String message = '';

      model.generateContentStream(promptContext).listen(
            (event) async {
              if (event.text != null) {
                message += event.text!;
              }

              final MessageModel model = MessageModel()
                ..isMine = false
                ..message = message
                ..date = DateTime.now();

              if (currentModelMessageId != null) {
                model.id = currentModelMessageId!;
              }

              currentModelMessageId = await isar.writeTxn<int>(() => isar.messageModels.put(model));
            },
            onDone: () => setState(() {
              isRunning = false;
            }),
            onError: (e) async {
              await isar.writeTxn(() async {
                return isar.messageModels.delete(currentUserMessageId!);
              });

              setState(() {
                error = e.toString();
                isRunning = false;
              });
            },
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: GetIt.I<Isar>().messageModels.where().watch(fireImmediately: true),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) async => _scrollToBottom());
                  return _buildMessageList(messages);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 32.0),
              child: ChatTextField(
                error: error,
                loading: isRunning,
                onSend: _handleSendMessage,
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<MessageModel> messages) {
    return ListView.separated(
      controller: scrollController,
      itemCount: messages.length + 1,
      itemBuilder: (context, index) => index == 0
          ? _buildLogo()
          : _buildMessageItem(
              message: messages[index - 1],
              prevMessage: index > 1 ? messages[index - 2] : null,
              index: index - 1,
            ),
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: const Padding(
        padding: EdgeInsets.only(bottom: 60.0),
        child: Logo(),
      ),
    );
  }

  Widget _buildMessageItem({
    MessageModel? prevMessage,
    required MessageModel message,
    required int index,
  }) {
    final isMine = message.isMine ?? false;
    final shouldDrawDateDivider = prevMessage == null || shouldDrawDate(prevMessage.date!, message.date!);

    return Column(
      children: [
        if (shouldDrawDateDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: DateDivider(date: message.date!),
          ),
        Padding(
          padding: EdgeInsets.only(left: isMine ? 64.0 : 16.0, right: isMine ? 16.0 : 64.0),
          child: Message(
            alignLeft: !isMine,
            message: message.message!.trim(),
            point: message.point,
          ),
        ),
      ],
    );
  }

  bool shouldDrawDate(DateTime date1, DateTime date2) {
    return getStringDate(date1) != getStringDate(date2);
  }

  String getStringDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _handleSendMessage() {
    if (controller.text.isEmpty) {
      setState(() => error = '메세지를 입력해주세요!');
      return;
    }
    sendMessageToGemini();
  }
}
