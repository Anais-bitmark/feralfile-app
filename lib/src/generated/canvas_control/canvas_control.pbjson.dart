///
//  Generated code. Do not modify.
//  source: canvas_control.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = const {
  '1': 'ConnectRequest',
  '2': const [
    const {'1': 'deviceName', '3': 1, '4': 1, '5': 9, '10': 'deviceName'},
    const {'1': 'connection_id', '3': 2, '4': 1, '5': 9, '10': 'connectionId'},
    const {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor = $convert.base64Decode('Cg5Db25uZWN0UmVxdWVzdBIeCgpkZXZpY2VOYW1lGAEgASgJUgpkZXZpY2VOYW1lEiMKDWNvbm5lY3Rpb25faWQYAiABKAlSDGNvbm5lY3Rpb25JZBIYCgdtZXNzYWdlGAMgASgJUgdtZXNzYWdl');
@$core.Deprecated('Use connectReplyDescriptor instead')
const ConnectReply$json = const {
  '1': 'ConnectReply',
  '2': const [
    const {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ConnectReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectReplyDescriptor = $convert.base64Decode('CgxDb25uZWN0UmVwbHkSGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZQ==');
