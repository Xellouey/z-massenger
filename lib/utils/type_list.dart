enum MessageType {
  text,
  image,
  video,
  doc,
  location,
  contact,
  audio,
  messageType,
  gif,
  link,
  imageArray,
  note,
  chatLoading,
  catalogue,
  emoji
}

enum StatusType { text, image, video }

enum PositionItemType {
  log,
  position,
}

MessageType getMessageTypeFromString(String type) {
  return MessageType.values.firstWhere(
        (e) => e.name == type,
    orElse: () => MessageType.messageType, // default fallback
  );
}