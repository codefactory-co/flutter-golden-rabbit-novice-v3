import 'package:isar/isar.dart';

part 'message_model.g.dart';

@collection
class MessageModel {
  Id id = Isar.autoIncrement;
  bool? isMine;
  String? message;
  int? point;
  DateTime? date;
}
