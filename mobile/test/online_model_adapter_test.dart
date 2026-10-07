import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:diary/domain/local_assistant_message.dart';
import 'package:diary/services/online_model_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

void main() {
  late HttpServer server;
  late OpenAiCompatibleAdapter adapter;
  final servers = <HttpServer>[];
  final directories = <Directory>[];

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(server);
    adapter = OpenAiCompatibleAdapter(allowInsecureLoopback: true);
  });

  tearDown(() async {
    await adapter.dispose();
    for (final fixture in servers) {
      await fixture.close(force: true);
    }
    servers.clear();
    for (final directory in directories) {
      final absolute = p.normalize(directory.absolute.path);
      if (!p.equals(p.dirname(absolute), Directory.systemTemp.absolute.path) ||
          !p.basename(absolute).startsWith('diary_online_image_test_')) {
        throw StateError('Unexpected temporary image directory.');
      }
      await directory.delete(recursive: true);
    }
    directories.clear();
  });

  OnlineModelConfiguration configuration({
    bool sendImages = false,
    OnlineModelProvider provider = OnlineModelProvider.compatible,
    String model = 'test-model',
  }) => OnlineModelConfiguration(
    provider: provider,
    baseUrl: 'http://127.0.0.1:${server.port}/v1',
    model: model,
    sendImages: sendImages,
  );

  Stream<String> generate({
    String diary = '今天还没吃晚饭，好饿。',
    String persona = defaultLocalAssistantPersona,
    List<String> imagePaths = const [],
    bool sendImages = false,
  }) => adapter.generate(
    configuration: configuration(sendImages: sendImages),
    apiKey: 'fixture-secret-key',
    diary: diary,
    tone: LocalAssistantTone.gentle,
    persona: persona,
    imagePaths: imagePaths,
  );

  void respond(Future<void> Function(HttpRequest request) handler) {
    server.listen((request) async {
      try {
        await handler(request);
      } on SocketException {
        // Cancellation intentionally interrupts fixture responses.
      } on HttpException {
        // Cancellation intentionally interrupts fixture responses.
      }
    });
  }

  Future<Map<String, dynamic>> readRequest(HttpRequest request) async {
    return jsonDecode(await utf8.decoder.bind(request).join())
        as Map<String, dynamic>;
  }

  Future<void> jsonResponse(HttpRequest request, String reply) async {
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({
        'choices': [
          {
            'message': {
              'content': reply,
              'reasoning_content': 'hidden reasoning',
            },
          },
        ],
      }),
    );
    await request.response.close();
  }

  Future<String> fixtureImage({int width = 1400, int height = 700}) async {
    final directory = await Directory.systemTemp.createTemp(
      'diary_online_image_test_',
    );
    directories.add(directory);
    final path = p.join(directory.path, 'fixture.png');
    final pixels = image.Image(width: width, height: height);
    image.fill(pixels, color: image.ColorRgb8(127, 95, 60));
    await File(path).writeAsBytes(image.encodePng(pixels));
    return path;
  }

  test(
    'SSE decodes split Chinese, comments, CRLF, usage and ignores reasoning',
    () async {
      late Map<String, dynamic> sent;
      late String? authorization;
      late Uri endpoint;
      respond((request) async {
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        endpoint = request.uri;
        sent = await readRequest(request);
        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
          charset: 'utf-8',
        );
        final wire = utf8.encode(
          ': heartbeat\r\n\r\n'
          'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'reasoning_content': 'secret thoughts'},
              },
            ],
          })}\r\n\r\n'
          'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'content': '先吃饱'},
              },
            ],
          })}\r\n\r\n'
          'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'content': '再说呀。'},
              },
            ],
          })}\r\n\r\n'
          'data: ${jsonEncode({
            'choices': [],
            'usage': {'total_tokens': 10},
          })}\r\n\r\n'
          'data: [DONE]\r\n\r\n',
        );
        for (var offset = 0; offset < wire.length; offset += 2) {
          request.response.add(
            wire.sublist(offset, (offset + 2).clamp(0, wire.length)),
          );
          await request.response.flush();
        }
        await request.response.close();
      });
      final replies = await generate().toList();
      expect(replies.last, '先吃饱再说呀。');
      expect(replies.join(), isNot(contains('secret thoughts')));
      expect(authorization, 'Bearer fixture-secret-key');
      expect(endpoint.path, '/v1/chat/completions');
      expect(sent['stream'], true);
      expect(sent['max_tokens'], 256);
      expect(sent['temperature'], 0.7);
      expect(sent, isNot(contains('thinking')));
      expect(sent['messages'], hasLength(2));
      expect((sent['messages'] as List).last, {
        'role': 'user',
        'content': '今天还没吃晚饭，好饿。',
      });
    },
  );

  test('JSON fallback emits only assistant body', () async {
    respond((request) async {
      await readRequest(request);
      await jsonResponse(request, '吃点喜欢的，先照顾好自己。');
    });
    expect(await generate().toList(), ['吃点喜欢的，先照顾好自己。']);
  });

  test(
    'explicit DeepSeek adapter disables thinking only in its payload',
    () async {
      await adapter.dispose();
      adapter = DeepSeekAdapter(allowInsecureLoopback: true);
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '今天辛苦啦。');
      });
      await generate().drain<void>();
      expect(sent['thinking'], {'type': 'disabled'});
    },
  );

  test(
    'MiniMax M3 uses modern length limit and separates disabled reasoning',
    () async {
      await adapter.dispose();
      adapter = MiniMaxAdapter(allowInsecureLoopback: true);
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '<think>private reasoning</think>吃饱才有精神。');
      });
      final replies = await adapter
          .generate(
            configuration: configuration(
              provider: OnlineModelProvider.miniMax,
              model: 'MiniMax-M3',
            ),
            apiKey: 'fixture-key',
            diary: '我还没吃晚饭',
            tone: LocalAssistantTone.gentle,
            persona: defaultLocalAssistantPersona,
          )
          .toList();
      expect(replies, ['吃饱才有精神。']);
      expect(sent['reasoning_split'], true);
      expect(sent['max_completion_tokens'], 1024);
      expect(sent, isNot(contains('max_tokens')));
      expect(sent['thinking'], {'type': 'disabled'});
    },
  );

  test(
    'MiniMax newer preview models are not sent unsupported disabled thinking',
    () async {
      await adapter.dispose();
      adapter = MiniMaxAdapter(allowInsecureLoopback: true);
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '好的。');
      });
      await adapter
          .generate(
            configuration: configuration(
              provider: OnlineModelProvider.miniMax,
              model: 'MiniMax-M3.1-Flash-Preview',
            ),
            apiKey: 'fixture-key',
            diary: '今天挺开心',
            tone: LocalAssistantTone.gentle,
            persona: defaultLocalAssistantPersona,
          )
          .drain<void>();
      expect(sent, isNot(contains('thinking')));
      expect(sent['reasoning_effort'], 'low');
    },
  );

  test('MiniMax filters thought tags split across streaming packets', () async {
    await adapter.dispose();
    adapter = MiniMaxAdapter(allowInsecureLoopback: true);
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      for (final fragment in [
        '<th',
        'ink>secret thought',
        '</thi',
        'nk>先吃点',
        '东西。',
      ]) {
        request.response.write(_chunk(fragment));
        await request.response.flush();
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.close();
    });
    final snapshots = await generate().toList();
    expect(snapshots.last, '先吃点东西。');
    expect(snapshots.join(), isNot(contains('secret thought')));
    expect(snapshots.join(), isNot(contains('<th')));
  });

  for (final streaming in [false, true]) {
    test(
      'MiniMax HTTP 200 base_resp failure remains a safe account error (stream $streaming)',
      () async {
        await adapter.dispose();
        adapter = MiniMaxAdapter(allowInsecureLoopback: true);
        respond((request) async {
          await readRequest(request);
          final failure = jsonEncode({
            'base_resp': {
              'status_code': 1008,
              'status_msg': 'fixture-secret-key private details',
            },
          });
          if (streaming) {
            request.response.headers.contentType = ContentType(
              'text',
              'event-stream',
              charset: 'utf-8',
            );
            request.response.write('data: $failure\n\n');
          } else {
            request.response.headers.contentType = ContentType.json;
            request.response.write(failure);
          }
          await request.response.close();
        });
        await expectLater(
          generate().toList(),
          throwsA(
            isA<OnlineModelException>().having(
              (e) => e.message,
              'message',
              allOf(contains('余额'), isNot(contains('fixture-secret-key'))),
            ),
          ),
        );
      },
    );
  }

  test(
    'diary questions stay single-entry content and cannot become chat invites',
    () async {
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '先选一份喜欢吃的，别让肚子等太久。');
      });
      const diary = '我还没吃晚饭，怎么办？打算点外卖吧。';
      const persona = '一个活泼的朋友，每次都邀请我继续聊、让我再补充信息。';
      await generate(diary: diary, persona: persona).drain<void>();
      final messages = sent['messages'] as List;
      expect(messages, hasLength(2));
      expect(messages.last, {'role': 'user', 'content': diary});
      final instruction = messages.first['content'] as String;
      expect(instruction, contains('还没吃晚饭'));
      expect(instruction, contains('不是已经吃过'));
      expect(instruction, contains('普通生活记录'));
      expect(instruction, contains('不把所有记录都套成需要安慰'));
      // A custom persona is retained as a preference, then followed by the
      // higher-priority product boundary, even when it asks for a chat loop.
      final styleIndex = instruction.indexOf('人设：$persona');
      expect(styleIndex, greaterThan(0));
      final boundary = instruction.substring(styleIndex + '人设：$persona'.length);
      expect(boundary, contains('回应边界（优先于人设）'));
      expect(boundary, contains('不提问、不邀请继续交流、不要求补充信息'));
      expect(boundary, contains('原文有问句也不反问'));
    },
  );

  test(
    'prompt bounds latest text and persona without splitting emoji',
    () async {
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '好呀。');
      });
      await generate(
        diary: '${List.filled(1500, '🙂').join()}这是最新结尾',
        persona: List.filled(800, '🙂').join(),
      ).drain<void>();
      final messages = sent['messages'] as List;
      final diary = messages.last['content'] as String;
      final system = messages.first['content'] as String;
      expect(diary.runes.length, 1200);
      expect(diary, endsWith('这是最新结尾'));
      expect(system.split('人设：').last.split('\n回应边界').first.runes.length, 600);
      expect(diary, isNot(contains('\uFFFD')));
    },
  );

  for (final sample in [
    (status: 401, message: 'API Key'),
    (status: 402, message: '余额'),
    (status: 403, message: '权限'),
    (status: 429, message: '请求受限'),
    (status: 500, message: '暂时不可用'),
  ]) {
    test(
      'HTTP ${sample.status} has safe readable error and does not retry',
      () async {
        var requests = 0;
        respond((request) async {
          requests++;
          await readRequest(request);
          request.response.statusCode = sample.status;
          request.response.write('fixture-secret-key provider private body');
          await request.response.close();
        });
        await expectLater(
          generate().toList(),
          throwsA(
            isA<OnlineModelException>().having(
              (error) => error.toString(),
              'safe message',
              allOf(
                contains(sample.message),
                isNot(contains('fixture-secret-key')),
                isNot(contains('provider private body')),
              ),
            ),
          ),
        );
        expect(requests, 1);
      },
    );
  }

  test(
    'redirect never forwards authorization or reaches another server',
    () async {
      final destination = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      servers.add(destination);
      var redirectedRequests = 0;
      destination.listen((request) async {
        redirectedRequests++;
        await request.response.close();
      });
      respond((request) async {
        await readRequest(request);
        request.response.statusCode = HttpStatus.temporaryRedirect;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://127.0.0.1:${destination.port}/leak',
        );
        await request.response.close();
      });
      await expectLater(
        generate().toList(),
        throwsA(
          isA<OnlineModelException>().having(
            (e) => e.message,
            'message',
            contains('重定向'),
          ),
        ),
      );
      expect(redirectedRequests, 0);
    },
  );

  test(
    'explicit cancel interrupts awaiting headers and allows another request',
    () async {
      final received = Completer<void>();
      final release = Completer<void>();
      var requests = 0;
      respond((request) async {
        await readRequest(request);
        requests++;
        if (requests == 1) {
          received.complete();
          await release.future;
        }
        await jsonResponse(request, '下一条正常回复。');
      });
      final pending = generate().toList();
      await received.future;
      await adapter.cancel().timeout(const Duration(seconds: 2));
      expect(await pending, isEmpty);
      release.complete();
      expect(await generate().toList(), ['下一条正常回复。']);
    },
  );

  test('subscription cancel closes a slow active SSE connection', () async {
    await adapter.dispose();
    final clients = <_TrackedHttpClient>[];
    adapter = OpenAiCompatibleAdapter(
      allowInsecureLoopback: true,
      clientFactory: () {
        final client = _TrackedHttpClient(HttpClient());
        clients.add(client);
        return client;
      },
    );
    final started = Completer<void>();
    final release = Completer<void>();
    var requests = 0;
    respond((request) async {
      await readRequest(request);
      if (++requests > 1) {
        await jsonResponse(request, '下一条正常回复。');
        return;
      }
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write(': connected\n\n');
      await request.response.flush();
      started.complete();
      await release.future;
      request.response.write('${_chunk('迟到的内容')}data: [DONE]\n\n');
      await request.response.close();
    });
    final snapshots = <String>[];
    final errors = <Object>[];
    final subscription = generate().listen(snapshots.add, onError: errors.add);
    await started.future;
    await subscription.cancel().timeout(const Duration(seconds: 2));
    expect(clients.single.forcedClosed, isTrue);
    release.complete();
    expect(await generate().toList(), ['下一条正常回复。']);
    expect(snapshots, isEmpty);
    expect(errors, isEmpty);
    expect(clients, hasLength(2));
  });

  test('idle timeout returns safe message and closes the request', () async {
    await adapter.dispose();
    adapter = OpenAiCompatibleAdapter(
      allowInsecureLoopback: true,
      idleTimeout: const Duration(milliseconds: 80),
      totalTimeout: const Duration(seconds: 2),
    );
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write(': alive\n\n');
      await request.response.flush();
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('超时'),
        ),
      ),
    );
  });

  test('total timeout remains bounded despite heartbeat traffic', () async {
    await adapter.dispose();
    adapter = OpenAiCompatibleAdapter(
      allowInsecureLoopback: true,
      idleTimeout: const Duration(seconds: 2),
      totalTimeout: const Duration(milliseconds: 150),
    );
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      for (var index = 0; index < 30; index++) {
        request.response.write(': alive\n\n');
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await request.response.close();
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('超时'),
        ),
      ),
    );
  });

  test('EOF without completion marker reports incomplete response', () async {
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write(_chunk('只写了半句'));
      await request.response.close();
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('未完成'),
        ),
      ),
    );
  });

  for (final pendingFinish in ['', ' ', '\t']) {
    test(
      'blank finish_reason ${jsonEncode(pendingFinish)} waits for completion',
      () async {
        respond((request) async {
          await readRequest(request);
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
            charset: 'utf-8',
          );
          for (final choice in [
            {
              'delta': {'role': 'assistant'},
              'finish_reason': pendingFinish,
            },
            {
              'delta': {'content': '先吃点热乎的饭吧。'},
              'finish_reason': pendingFinish,
            },
            {'delta': {}, 'finish_reason': 'stop'},
          ]) {
            request.response.write(
              'data: ${jsonEncode({
                'choices': [choice],
              })}\n\n',
            );
          }
          await request.response.close();
        });
        expect((await generate().toList()).last, '先吃点热乎的饭吧。');
      },
    );
  }

  test('blank finish_reason does not permit an incomplete EOF', () async {
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write(
        'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'content': '半句'},
              'finish_reason': '',
            },
          ],
        })}\n\n',
      );
      await request.response.close();
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (error) => error.message,
          'message',
          contains('提前中断'),
        ),
      ),
    );
  });

  for (final failureFinish in [
    'length',
    'content_filter',
    'tool_calls',
    'unexpected-value',
  ]) {
    test(
      'non-stop finish_reason $failureFinish does not save an incomplete response',
      () async {
        respond((request) async {
          await readRequest(request);
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
            charset: 'utf-8',
          );
          request.response.write(
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {'content': '半句'},
                  'finish_reason': '',
                },
              ],
            })}\n\n',
          );
          request.response.write(
            'data: ${jsonEncode({
              'choices': [
                {'delta': {}, 'finish_reason': failureFinish},
              ],
            })}\n\n',
          );
          request.response.write('data: [DONE]\n\n');
          await request.response.close();
        });
        await expectLater(
          generate().toList(),
          throwsA(
            isA<OnlineModelException>().having(
              (error) => error.message,
              'message',
              contains(failureFinish == 'length' ? '达到上限' : '未能完成'),
            ),
          ),
        );
      },
    );
  }

  test('finish_reason permits a valid stream without DONE', () async {
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write(
        '${_chunk('完整回复。')}data: ${jsonEncode({
          'choices': [
            {'delta': {}, 'finish_reason': 'stop'},
          ],
        })}\n\n',
      );
      await request.response.close();
    });
    expect((await generate().toList()).last, '完整回复。');
  });

  test('reasoning-only response does not become saved body', () async {
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write(
        'data: ${jsonEncode({
          'choices': [
            {
              'delta': {'reasoning_content': 'private thought'},
            },
          ],
        })}\n\n'
        'data: [DONE]\n\n',
      );
      await request.response.close();
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('正文'),
        ),
      ),
    );
  });

  test('malformed JSON never echoes provider private body', () async {
    respond((request) async {
      await readRequest(request);
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      request.response.write('data: fixture-secret-key invalid data\n\n');
      await request.response.close();
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          isNot(contains('fixture-secret-key')),
        ),
      ),
    );
  });

  test('response bytes are bounded before JSON decoding', () async {
    await adapter.dispose();
    adapter = OpenAiCompatibleAdapter(
      allowInsecureLoopback: true,
      maxResponseBytes: 100,
    );
    respond((request) async {
      await readRequest(request);
      await jsonResponse(request, List.filled(200, '啊').join());
    });
    await expectLater(
      generate().toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('过大'),
        ),
      ),
    );
  });

  test(
    'snapshots are cumulative and final short fragment is preserved',
    () async {
      respond((request) async {
        await readRequest(request);
        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
          charset: 'utf-8',
        );
        for (var index = 0; index < 30; index++) {
          request.response.write(_chunk('哈'));
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        request.response.write('${_chunk('。')}data: [DONE]\n\n');
        await request.response.close();
      });
      final snapshots = await generate().toList();
      expect(snapshots.last, '${List.filled(30, '哈').join()}。');
      expect(snapshots.length, lessThan(10));
      for (var index = 1; index < snapshots.length; index++) {
        expect(snapshots[index], startsWith(snapshots[index - 1]));
      }
    },
  );

  test(
    'disabled image setting sends text without reading missing paths',
    () async {
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '好的。');
      });
      await generate(
        imagePaths: ['Z:/missing/private-image.png'],
      ).drain<void>();
      expect((sent['messages'] as List).last['content'], isA<String>());
      expect(jsonEncode(sent), isNot(contains('image_url')));
      expect(jsonEncode(sent), isNot(contains('private-image')));
    },
  );

  test(
    'image-only diary sends resized JPEG with no file path or EXIF',
    () async {
      final imagePath = await fixtureImage();
      late Map<String, dynamic> sent;
      respond((request) async {
        sent = await readRequest(request);
        await jsonResponse(request, '这一刻看着挺温暖的。');
      });
      await generate(
        diary: '',
        imagePaths: [imagePath],
        sendImages: true,
      ).drain<void>();
      final parts = (sent['messages'] as List).last['content'] as List;
      expect(parts, hasLength(2));
      expect(parts.first['type'], 'text');
      final url = parts.last['image_url']['url'] as String;
      expect(url, startsWith('data:image/jpeg;base64,'));
      final encoded = base64Decode(url.split(',').last);
      expect(encoded.length, lessThanOrEqualTo(1024 * 1024));
      final decoded = image.decodeJpg(encoded)!;
      expect(decoded.width, 1024);
      expect(decoded.height, 512);
      expect(decoded.exif.imageIfd.values, isEmpty);
      expect(decoded.exif.gpsIfd.values, isEmpty);
      expect(jsonEncode(sent), isNot(contains(imagePath)));
    },
  );

  test('unreadable images fail before creating any HTTP request', () async {
    var requests = 0;
    respond((request) async {
      requests++;
      await request.response.close();
    });
    await expectLater(
      generate(imagePaths: ['Z:/missing/image.png'], sendImages: true).toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('图片无法读取'),
        ),
      ),
    );
    expect(requests, 0);
  });

  test(
    'cancel during image preparation never sends the old image request',
    () async {
      final imagePath = await fixtureImage();
      var requests = 0;
      respond((request) async {
        requests++;
        await request.response.close();
      });
      final pending = generate(
        imagePaths: [imagePath],
        sendImages: true,
      ).toList();
      await adapter.cancel().timeout(const Duration(seconds: 2));
      expect(await pending, isEmpty);
      expect(requests, 0);
    },
  );

  test('image count is checked before reading or making requests', () async {
    var requests = 0;
    respond((request) async {
      requests++;
      await request.response.close();
    });
    await expectLater(
      generate(
        imagePaths: List.filled(5, 'missing.png'),
        sendImages: true,
      ).toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('最多发送 4 张'),
        ),
      ),
    );
    expect(requests, 0);
  });

  test('oversized PNG dimensions are rejected before pixel decoding', () async {
    final imagePath = await fixtureImage(width: 1, height: 1);
    final bytes = await File(imagePath).readAsBytes();
    final header = ByteData.sublistView(bytes);
    header.setUint32(16, 20000, Endian.big);
    header.setUint32(20, 20000, Endian.big);
    await File(imagePath).writeAsBytes(bytes);
    await expectLater(
      generate(imagePaths: [imagePath], sendImages: true).toList(),
      throwsA(
        isA<OnlineModelException>().having(
          (e) => e.message,
          'message',
          contains('图片无法读取'),
        ),
      ),
    );
  });
}

class _TrackedHttpClient implements HttpClient {
  _TrackedHttpClient(this.delegate);
  final HttpClient delegate;
  bool forcedClosed = false;
  @override
  Duration? get connectionTimeout => delegate.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => delegate.connectionTimeout = value;
  @override
  Future<HttpClientRequest> postUrl(Uri url) => delegate.postUrl(url);
  @override
  void close({bool force = false}) {
    forcedClosed = forcedClosed || force;
    delegate.close(force: force);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _chunk(String text) =>
    'data: ${jsonEncode({
      'choices': [
        {
          'delta': {'content': text},
        },
      ],
    })}\n\n';
