class CallType {
  static const VIDEO_CALL = 1;
  static const AUDIO_CALL = 2;
}

class RTCConfig {
  static const int _defaultDillingTimeInterval = 3;
  static const int _defaultNoAnswerTimeout = 60;

  static int get defaultDillingTimeInterval => _defaultDillingTimeInterval;
  static int get defaultNoAnswerTimeout => _defaultNoAnswerTimeout;
}
