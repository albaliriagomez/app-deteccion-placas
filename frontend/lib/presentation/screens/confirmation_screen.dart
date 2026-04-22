import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';
import 'dart:convert';
import '../../services/parqueo_service.dart';
import '../../services/session_manager.dart';
import 'verificando_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String plate;
  final String base64Image;
  final String location;
  final String latitude;
  final String longitude;
  final String hora;

  const ConfirmationScreen({
    super.key,
    required this.plate,
    required this.base64Image,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.hora,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  // ── Paleta oficial ────────────────────────────────────────────
  static const Color _purple    = Color(0xFF462677);
  static const Color _purpleMid = Color(0xFF6C559F);
  static const Color _cyan      = Color(0xFFB2DFEF);
  static const Color _cyanMid   = Color(0xFF4ABFDD);
  static const Color _cyanDark  = Color(0xFF00ABD6);
  static const Color _green     = Color(0xFFA5C857);
  static const Color _red       = Color(0xFFE32344);
  static const Color _bgGray    = Color(0xFFF8FAFF);
  static const Color _white     = Colors.white;

  late TextEditingController _plateController;
  final ApiRepository _apiRepository = ApiRepository();
  bool _isSaving  = false;
  bool _isEditing = false;
  late final Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.plate);
    _imageBytes      = base64Decode(widget.base64Image);
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: _bgGray,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildProgressIndicator(),
                const SizedBox(height: 24),
                _buildCapturedImage(),
                const SizedBox(height: 24),
                _buildPlateEditField(),
                const SizedBox(height: 12),
                _buildHelpText(),
                const SizedBox(height: 20),
                _buildLocationChip(),
                const SizedBox(height: 32),
                _buildActionButtons(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar con gradiente morado ───────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_purple, Color(0xFF6B3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Icon(Icons.fact_check_rounded, color: _cyan, size: 18),
          const SizedBox(width: 8),
          Text(
            'Confirmar Patente',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  // ── Indicador de pasos ────────────────────────────────────────
  Widget _buildProgressIndicator() {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cyan.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepCircle('1', filled: true),
            _stepLine(filled: true),
            _stepCircle('2', filled: true),
            _stepLine(filled: false),
            _stepCircle('3', filled: false),
          ],
        ),
      ),
    );
  }

  Widget _stepCircle(String label, {required bool filled}) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(
                colors: [_purple, _purpleMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: filled ? null : _cyan.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? Colors.transparent : _cyan.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: filled ? _white : _purpleMid,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _stepLine({required bool filled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 40, height: 3,
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(
                  colors: [_purple, _cyanMid],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: filled ? null : _cyan.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Imagen capturada ──────────────────────────────────────────
  Widget _buildCapturedImage() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                _imageBytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                  color: _purple.withOpacity(0.12)),
            ),
            // Marco de patente con color cyan
            Center(
              child: Container(
                width: 200, height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: _cyanMid, width: 2.5),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _cyanMid.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Campo editable de patente ─────────────────────────────────
  Widget _buildPlateEditField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Número de patente',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _purpleMid,
              ),
            ),
            // Badge lectura exitosa con verde oficial
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _green.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: _green, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'LECTURA EXITOSA',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D5A0D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isEditing
                  ? _cyanMid
                  : _cyan.withOpacity(0.4),
              width: _isEditing ? 2 : 1.5,
            ),
            boxShadow: _isEditing
                ? [
                    BoxShadow(
                      color: _cyanMid.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: _purple.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _plateController,
                  onTap:      () => setState(() => _isEditing = true),
                  onSubmitted: (_) => setState(() => _isEditing = false),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _purple,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Patente',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: _cyan.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isEditing = !_isEditing),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? _cyanMid.withOpacity(0.15)
                        : _purple.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    color: _isEditing ? _cyanDark : _purple,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Texto de ayuda ────────────────────────────────────────────
  Widget _buildHelpText() {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 14, color: _purpleMid.withOpacity(0.5)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Revise el texto. Puede editarlo si hubo un error en el escaneo.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _purpleMid.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Chip de ubicación ─────────────────────────────────────────
  Widget _buildLocationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cyan.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _purple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación detectada',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _purpleMid.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.location,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Botones de acción ─────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Confirmar — gradiente morado
        AbsorbPointer(
          absorbing: _isSaving,
          child: Opacity(
            opacity: _isSaving ? 0.7 : 1.0,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_purple, _purpleMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         Colors.transparent,
                    shadowColor:             Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSaving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        _isSaving ? 'Guardando...' : 'Confirmar Patente',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Volver a escanear — borde cyan
        if (!_isSaving)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: BorderSide(color: _cyan.withOpacity(0.7), width: 2),
                backgroundColor: _cyan.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.camera_alt_rounded,
                  color: _purple, size: 20),
              label: Text(
                'Volver a Escanear',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _purple,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Lógica intacta ────────────────────────────────────────────
  Future<void> _onConfirm() async {
    final placa = _plateController.text.trim().toUpperCase();

    SessionManager.ultimaPlaca     = placa;
    SessionManager.ultimaLatitud   = widget.latitude;
    SessionManager.ultimaLongitud  = widget.longitude;

    // ✅ NUEVO: Verificar sesión antes de proceder
    bool sesionVigente = await SessionManager.sesionVigente();
    if (!sesionVigente) {
      if (mounted) {
        // Ir al login elegantemente
        await Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
          arguments: {'sessionExpired': true}
        );
      }
      return;
    }

    // El resto del código sigue igual
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerificandoScreen(
          data: {
            "placa":       placa,
            "base64Image": widget.base64Image,
            "ubicacion":   widget.location,
            "latitude":    widget.latitude,
            "longitude":   widget.longitude,
          },
        ),
      ),
    );
}
}