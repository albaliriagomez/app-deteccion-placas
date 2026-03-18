import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/api_repository.dart';

class RecordDetailScreen extends StatefulWidget {
  final PlateRecord record;

  const RecordDetailScreen({
    super.key,
    required this.record,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
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

  // ── Lógica intacta ────────────────────────────────────────────
  final ApiRepository _apiRepository = ApiRepository();
  String? _loadedImageData;
  bool    _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.record.imagen.isEmpty) {
      _fetchFullImage();
    } else {
      _loadedImageData = widget.record.imagen;
    }
  }

  Future<void> _fetchFullImage() async {
    setState(() => _isLoadingImage = true);
    try {
      final fullImage =
          await _apiRepository.getFullImage(widget.record.id);
      if (mounted) {
        setState(() {
          _loadedImageData  = fullImage;
          _isLoadingImage   = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  // ── Estado del registro → config visual ──────────────────────
  Map<String, dynamic> _getStatusConfig(String estado) {
    switch (estado.trim()) {
      case 'Pago Vigente':
        return {
          'color':  _green,
          'bg':     _green.withOpacity(0.12),
          'border': _green.withOpacity(0.3),
          'icon':   Icons.check_circle_rounded,
          'label':  'PAGO VIGENTE',
        };
      case 'Pago Vencido':
        return {
          'color':  _red,
          'bg':     _red.withOpacity(0.10),
          'border': _red.withOpacity(0.3),
          'icon':   Icons.gavel_rounded,
          'label':  'PAGO VENCIDO',
        };
      case 'No Registrado':
        return {
          'color':  Colors.orange,
          'bg':     Colors.orange.withOpacity(0.10),
          'border': Colors.orange.withOpacity(0.3),
          'icon':   Icons.warning_amber_rounded,
          'label':  'NO REGISTRADO',
        };
      default:
        return {
          'color':  _purpleMid,
          'bg':     _purpleMid.withOpacity(0.10),
          'border': _purpleMid.withOpacity(0.2),
          'icon':   Icons.help_outline_rounded,
          'label':  estado.toUpperCase(),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A0F2E) : _bgGray,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageSection(isDark),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBadge(),
                  const SizedBox(height: 20),
                  _buildInfoCard(isDark),
                  const SizedBox(height: 16),
                  _buildVerificationCard(isDark),
                  const SizedBox(height: 28),
                  _buildActionButtons(isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar con gradiente morado ───────────────────────────────
  AppBar _buildAppBar(bool isDark) {
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
          Icon(Icons.receipt_long_rounded, color: _cyan, size: 18),
          const SizedBox(width: 8),
          Text(
            'Detalles del Registro',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  // ── Sección imagen ────────────────────────────────────────────
  Widget _buildImageSection(bool isDark) {
    return Container(
      width: double.infinity,
      height: 280,
      color: isDark ? const Color(0xFF2A1A4A) : _white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageWidget(),
          // Degradado superior
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _purple.withOpacity(0.5),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          // Badges superiores
          Positioned(
            top: 14, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniBadge(widget.record.estado),
                _buildZoneChip(widget.record.zona),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_isLoadingImage) {
      return Center(
        child: CircularProgressIndicator(color: _cyanMid),
      );
    }

    final imagePath = _loadedImageData ?? "";

    if (imagePath.isEmpty) return _buildNoImage();

    if (imagePath.startsWith('/9j/') || imagePath.length > 500) {
      try {
        String base64String = imagePath;
        if (imagePath.contains(',')) {
          base64String = imagePath.split(',').last;
        }
        return Image.memory(
          base64Decode(base64String.trim()),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildNoImage(),
        );
      } catch (e) {
        return _buildNoImage();
      }
    }

    if (imagePath.startsWith('/') || imagePath.contains(':/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildNoImage(),
      );
    }

    return _buildNoImage();
  }

  Widget _buildNoImage() {
    return Container(
      color: _cyan.withOpacity(0.15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_rounded,
                size: 60, color: _purpleMid.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text('Sin imagen disponible',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _purpleMid.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String estado) {
    final cfg = _getStatusConfig(estado);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (cfg['color'] as Color).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg['icon'] as IconData,
              color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            cfg['label'] as String,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneChip(String zona) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _cyan.withOpacity(0.3), width: 1),
      ),
      child: Text(
        zona,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Badge de estado central ───────────────────────────────────
  Widget _buildStatusBadge() {
    final cfg   = _getStatusConfig(widget.record.estado);
    final color = cfg['color'] as Color;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: cfg['bg'] as Color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cfg['border'] as Color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cfg['icon'] as IconData,
                color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              cfg['label'] as String,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de información principal ─────────────────────────────
  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A4A) : _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: _cyan.withOpacity(isDark ? 0.2 : 0.35),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección label
          Row(
            children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_purple, _cyanMid],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Número de Patente',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _purpleMid.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Número de placa grande
          Text(
            widget.record.placa,
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: _purple,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 18),
          Divider(
              color: _cyan.withOpacity(0.3), height: 1, thickness: 1),
          const SizedBox(height: 18),

          // Fecha + Supervisor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                'Fecha y Hora',
                _formatDateTime(widget.record.fecha),
                isDark,
              ),
              _buildInfoItem(
                'Supervisor',
                widget.record.supervisor,
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Ubicación
          Text(
            'Ubicación',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _purpleMid.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _cyan.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: _purple, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.record.ubicacion,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _purpleMid.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : _purple,
          ),
        ),
      ],
    );
  }

  // ── Card de verificación ──────────────────────────────────────
  Widget _buildVerificationCard(bool isDark) {
    final cfg   = _getStatusConfig(widget.record.estado);
    final color = cfg['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1A4A) : _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: cfg['border'] as Color, width: 1.5),
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
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: (cfg['bg'] as Color),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(cfg['icon'] as IconData,
                color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  widget.record.estado == 'Pago Vigente'
                      ? 'La patente tiene todos los permisos requeridos'
                      : widget.record.estado == 'Pago Vencido'
                          ? 'El pago de parqueo ha vencido'
                          : 'No se encontró registro de pago',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _purpleMid.withOpacity(0.6),
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
  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        _buildButton(
          icon:      Icons.print_rounded,
          label:     'Imprimir',
          textColor: _purple,
          bgColor:   isDark ? const Color(0xFF2A1A4A) : _white,
          iconColor: _purple,
          isDark:    isDark,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String   label,
    required Color    textColor,
    required Color    bgColor,
    required Color    iconColor,
    required bool     isDark,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _cyan.withOpacity(isDark ? 0.2 : 0.4),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lógica intacta ────────────────────────────────────────────
  String _formatDateTime(DateTime dateTime) {
    final now        = DateTime.now();
    final today      = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(
        dateTime.year, dateTime.month, dateTime.day);
    String dayLabel  = recordDate == today
        ? 'Hoy'
        : '${recordDate.day}/${recordDate.month}/${recordDate.year}';
    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dayLabel • $timeStr';
  }
}