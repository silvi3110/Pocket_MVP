import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

class PinInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final String? label;

  const PinInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.label,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onDigit(int index, String value) {
    if (value.isEmpty) {
      // borrar — mover al anterior
      if (index > 0) {
        _controllers[index].clear();
        _focusNodes[index - 1].requestFocus();
      }
    } else {
      // escribir — mover al siguiente
      _controllers[index].text = value.isNotEmpty ? value[value.length - 1] : '';
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_value.length == widget.length) widget.onCompleted?.call();
      }
    }
    widget.onChanged(_value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = _controllers[i].text.isNotEmpty;
            final focused = _focusNodes[i].hasFocus;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < widget.length - 1 ? 10 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 56,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.purpleLight : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: focused
                          ? AppColors.purple
                          : filled
                              ? AppColors.purple.withValues(alpha: 0.4)
                              : AppColors.purple.withValues(alpha: 0.2),
                      width: focused ? 2 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: filled
                        ? Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                          )
                        : focused
                            ? Container(
                                width: 2, height: 20,
                                color: AppColors.purple,
                              )
                            : null,
                  ),
                ),
              ),
            );
          }),
        ),
        // TextField invisible que captura el input real
        SizedBox(
          height: 0,
          child: Stack(
            children: List.generate(widget.length, (i) => Positioned(
              left: i * 100.0, // fuera de vista
              child: SizedBox(
                width: 1, height: 1,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  keyboardType: TextInputType.number,
                  obscureText: false,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => _onDigit(i, v),
                  decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                  style: const TextStyle(fontSize: 1),
                ),
              ),
            )),
          ),
        ),
        // Área tappable para activar el teclado
        GestureDetector(
          onTap: () {
            final firstEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
            final target = firstEmpty == -1 ? widget.length - 1 : firstEmpty;
            _focusNodes[target].requestFocus();
          },
          child: Container(
            height: 0,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}

// Versión simplificada que usa un solo TextField oculto
// más confiable en Flutter Web
class PinInputSimple extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final String? label;
  final int length;

  const PinInputSimple({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.label,
    this.length = 6,
  });

  @override
  State<PinInputSimple> createState() => _PinInputSimpleState();
}

class _PinInputSimpleState extends State<PinInputSimple> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _pin = '';

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final filled = i < _pin.length;
              final active = i == _pin.length && _focus.hasFocus;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < widget.length - 1 ? 10 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    decoration: BoxDecoration(
                      color: filled ? AppColors.purpleLight : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.purple
                            : filled
                                ? AppColors.purple.withValues(alpha: 0.5)
                                : AppColors.purple.withValues(alpha: 0.2),
                        width: active ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: filled
                          ? Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                            )
                          : active
                              ? TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 500),
                                  builder: (_, v, __) => Opacity(
                                    opacity: (v * 2 - 1).abs(),
                                    child: Container(width: 2, height: 22, color: AppColors.purple),
                                  ),
                                )
                              : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // TextField oculto que captura el teclado
        SizedBox(
          width: 0,
          height: 0,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            obscureText: true,
            onChanged: (v) {
              setState(() => _pin = v);
              widget.onChanged(v);
              if (v.length == widget.length) {
                _focus.unfocus();
                widget.onCompleted?.call();
              }
            },
            decoration: const InputDecoration(counterText: '', border: InputBorder.none),
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
          ),
        ),
      ],
    );
  }
}
