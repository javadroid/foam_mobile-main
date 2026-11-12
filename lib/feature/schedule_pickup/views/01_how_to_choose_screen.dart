import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/location_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/02_tiers_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/03_nearby_stores_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HowToChooseScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/choose';

  const HowToChooseScreen({super.key});

  @override
  State<HowToChooseScreen> createState() => _HowToChooseScreenState();
}

class _HowToChooseScreenState extends State<HowToChooseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthProvider? auth;
      try {
        auth = Provider.of<AuthProvider>(context, listen: false);
      } catch (_) {}
      Provider.of<SchedulePickupProvider>(context, listen: false)
          .initFlowData(authProvider: auth);
    });
  }

  void _showLocationPickerModal(
      BuildContext context, SchedulePickupProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerModal(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final isFoamChoose = provider.selectedMethod == ScheduleMethod.letFoamChoose;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212828), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Schedule pickup',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212828),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address banner - Tappable to open location picker modal
              InkWell(
                onTap: () => _showLocationPickerModal(context, provider),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00AABC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup from',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF5E5E5E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              provider.pickupAddress,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF212828),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF5E5E5E),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Who should clean your clothes?',
                style: GoogleFonts.dmSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212828),
                ),
              ),

              const SizedBox(height: 20),

              // Option 1: Let Foam choose
              InkWell(
                onTap: () => provider.selectMethod(ScheduleMethod.letFoamChoose),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isFoamChoose ? const Color(0xFFE5F7F8) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFoamChoose ? const Color(0xFF00AABC) : const Color(0xFFE4E4E4),
                      width: isFoamChoose ? 1.4 : 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Let Foam choose',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212828),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AABC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'EASIEST',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Pick a price level with Foam's turnaround guarantee. We'll match you with the best store nearby.",
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E5E5E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Option 2: Pick a store
              InkWell(
                onTap: () => provider.selectMethod(ScheduleMethod.pickStore),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: !isFoamChoose ? const Color(0xFFE5F7F8) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isFoamChoose ? const Color(0xFF00AABC) : const Color(0xFFE4E4E4),
                      width: !isFoamChoose ? 1.4 : 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a store',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212828),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Browse stores near you by distance, rating and turnaround.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5E5E5E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Gradient Continue button
              Container(
                width: double.infinity,
                height: 53,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00AABC), Color(0xFFC5EFF3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (isFoamChoose) {
                      Navigator.pushNamed(context, ScheduleTiersScreen.id);
                    } else {
                      Navigator.pushNamed(context, NearbyStoresScreen.id);
                    }
                  },
                  child: Text(
                    'Continue',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPickerModal extends StatefulWidget {
  final SchedulePickupProvider provider;

  const _LocationPickerModal({required this.provider});

  @override
  State<_LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<_LocationPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<AddressSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _isDetecting = false;
  bool _isResolving = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      try {
        final results = await LocationService.searchAddressSuggestions(query);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _handleAutoDetect() async {
    setState(() => _isDetecting = true);
    final success = await widget.provider.autoDetectLocation();
    if (mounted) {
      setState(() => _isDetecting = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not detect location. Please check GPS permissions or search address.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleSelectSuggestion(AddressSuggestion suggestion) async {
    setState(() => _isResolving = true);
    try {
      final details =
          await LocationService.resolveSuggestionDetails(suggestion);
      widget.provider.setPickupLocation(
        address: details.formattedAddress,
        lat: details.latitude,
        lng: details.longitude,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error resolving address suggestion: $e');
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select pickup location',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212828),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF5E5E5E)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Saved Address option if available
          Builder(
            builder: (ctx) {
              AuthProvider? auth;
              try {
                auth = Provider.of<AuthProvider>(ctx, listen: false);
              } catch (_) {}
              if (auth == null || auth.addressStreet.isEmpty) {
                return const SizedBox.shrink();
              }
              final savedText = auth.addressCity.isNotEmpty
                  ? '${auth.addressStreet}, ${auth.addressCity}'
                  : auth.addressStreet;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    widget.provider.setPickupLocation(
                      address: savedText,
                      lat: auth?.addressLatitude,
                      lng: auth?.addressLongitude,
                    );
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF86EFAC), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_added_rounded,
                            color: Color(0xFF16A34A), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Saved Pickup Address',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                savedText,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: const Color(0xFF166534),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Auto-detect tile
          InkWell(
            onTap: (_isDetecting || _isResolving) ? null : _handleAutoDetect,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00AABC), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location,
                      color: Color(0xFF00AABC), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-detect current location',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF001C1F),
                          ),
                        ),
                        Text(
                          'Use device GPS coordinates',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF5E5E5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isDetecting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00AABC),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search box
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search address or landmark...',
              hintStyle: GoogleFonts.dmSans(
                  fontSize: 14, color: const Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00AABC)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF5F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isSearching || _isResolving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00AABC)),
              ),
            )
          else
            Expanded(
              child: _suggestions.isEmpty
                  ? (_searchController.text.trim().length >= 2
                      ? Center(
                          child: Text(
                            'No addresses found for "${_searchController.text}"',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: const Color(0xFF5E5E5E)),
                          ),
                        )
                      : Center(
                          child: Text(
                            'Type to search Nigeria addresses via Google Places',
                            style: GoogleFonts.dmSans(
                                fontSize: 13, color: const Color(0xFF9E9E9E)),
                          ),
                        ))
                  : ListView.separated(
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          leading: const Icon(Icons.location_on_outlined,
                              color: Color(0xFF00AABC)),
                          title: Text(
                            item.title,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212828),
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle.isNotEmpty
                                ? item.subtitle
                                : item.fullAddress,
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: const Color(0xFF5E5E5E)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _handleSelectSuggestion(item),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
