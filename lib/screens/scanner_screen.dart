import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/utils.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Сканер QR для организатора: камера + ручной ввод кода (резервный вариант).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  final _manual = TextEditingController();
  String? _eventFilter;
  CheckInResult? _result;
  String? _lastRaw;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;

  bool get _cameraSupported =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _process(String raw) async {
    final now = DateTime.now();
    // защита от повторной обработки одного и того же кода
    if (_busy || (raw == _lastRaw && now.difference(_lastAt).inSeconds < 3)) return;
    _busy = true;
    _lastRaw = raw;
    _lastAt = now;
    final res = await appState.checkIn(raw, onlyEventId: _eventFilter);
    if (!mounted) return;
    setState(() => _result = res);
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final events = appState.myEvents;
        return Scaffold(
          appBar: AppBar(title: const Text('Сканер QR')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              DropdownButtonFormField<String?>(
                value: events.any((e) => e.id == _eventFilter) ? _eventFilter : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Мероприятие', prefixIcon: Icon(Icons.event)),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Все мои мероприятия')),
                  ...events.map((e) => DropdownMenuItem<String?>(
                      value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _eventFilter = v),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 300,
                  child: _controller == null
                      ? Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                            'Камера недоступна на этой платформе.\nИспользуйте ручной ввод кода ниже.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Stack(fit: StackFit.expand, children: [
                          MobileScanner(
                            controller: _controller!,
                            onDetect: (capture) {
                              for (final b in capture.barcodes) {
                                final v = b.rawValue;
                                if (v != null) {
                                  _process(v);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, error, child) => Container(
                              color: Colors.black87,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(20),
                              child: const Text(
                                'Нет доступа к камере.\nРазрешите доступ в настройках телефона.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton.filledTonal(
                              onPressed: () => _controller?.toggleTorch(),
                              icon: const Icon(Icons.flashlight_on),
                            ),
                          ),
                        ]),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _manual,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Код вручную',
                      hintText: 'например, DEMO42',
                      prefixIcon: Icon(Icons.keyboard),
                    ),
                    onSubmitted: (v) => _submitManual(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(60, 52)),
                    onPressed: _submitManual,
                    child: const Icon(Icons.check),
                  ),
                ),
              ]),
              if (_result != null) ...[
                const SectionTitle('Результат проверки'),
                _ResultCard(result: _result!),
              ],
              if (_eventFilter != null) ...[
                const SectionTitle('Статистика'),
                _Progress(eventId: _eventFilter!),
              ],
            ],
          ),
        );
      },
    );
  }

  void _submitManual() {
    final v = _manual.text.trim();
    if (v.isEmpty) {
      showSnack(context, 'Введите код', error: true);
      return;
    }
    _lastRaw = null; // ручной ввод всегда обрабатываем
    _process(v);
    _manual.clear();
  }
}

class _Progress extends StatelessWidget {
  final String eventId;
  const _Progress({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final total = appState.registrationsOf(eventId).length;
    final done = appState.checkedInCount(eventId);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Пришло $done из $total зарегистрированных', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 8, borderRadius: BorderRadius.circular(8)),
        ]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final CheckInResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String title;
    String? subtitle;
    switch (result.status) {
      case CheckInStatus.ok:
        color = Colors.green;
        icon = Icons.check_circle;
        title = 'Вход разрешён';
        break;
      case CheckInStatus.already:
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        title = 'Уже отмечен';
        subtitle = 'Время входа: ${fmtTime(result.registration!.checkedInAt!)}';
        break;
      case CheckInStatus.wrongEvent:
        color = Colors.red;
        icon = Icons.block;
        title = 'Не то мероприятие';
        subtitle = 'Билет относится к другому событию.';
        break;
      case CheckInStatus.notFound:
        color = Colors.red;
        icon = Icons.cancel;
        title = 'Билет не найден';
        subtitle = 'QR-код или код недействителен, либо это не ваше мероприятие.';
        break;
      case CheckInStatus.error:
        color = Colors.red;
        icon = Icons.error_outline;
        title = 'Ошибка';
        subtitle = result.message;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            if (result.registration != null) Text(result.registration!.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (result.event != null) Text(result.event!.title, style: TextStyle(color: Colors.grey.shade700)),
            if (subtitle != null) Text(subtitle),
          ]),
        ),
      ]),
    );
  }
}
