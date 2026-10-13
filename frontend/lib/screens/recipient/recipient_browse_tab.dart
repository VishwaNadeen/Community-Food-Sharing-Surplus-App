import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import 'donation_card.dart';
import 'recipient_shared_widgets.dart';

class BrowseTab extends StatefulWidget {

  const BrowseTab({super.key});

  @override

  State<BrowseTab> createState() => _BrowseTabState();

}

class _BrowseTabState extends State<BrowseTab> {

  final TextEditingController _categoryCtrl = TextEditingController();

  final TextEditingController _locationCtrl = TextEditingController();

  List<DonationModel> _donations = [];

  bool _isLoading = false;

  String? _error;

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDonations());

  }

  @override

  void dispose() {

    _categoryCtrl.dispose();

    _locationCtrl.dispose();

    super.dispose();

  }

  Future<void> _loadDonations() async {

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    setState(() {

      _isLoading = true;

      _error = null;

    });

    try {

      final results = await DonationService.browseDonations(

        token: token,

        category: _categoryCtrl.text.trim(),

        location: _locationCtrl.text.trim(),

      );

      if (!mounted) return;

      setState(() => _donations = results);

    } catch (e) {

      if (!mounted) return;

      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));

    } finally {

      if (mounted) setState(() => _isLoading = false);

    }

  }

  @override

  Widget build(BuildContext context) {

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    return Column(

      children: [

        // ── Search / filter row ──

        Container(

          color: Colors.white,

          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),

          child: Row(

            children: [

              Expanded(

                child: TextField(

                  controller: _categoryCtrl,

                  textInputAction: TextInputAction.next,

                  decoration: InputDecoration(

                    hintText: 'Category…',

                    hintStyle: TextStyle(

                      color: Colors.grey.shade400,

                      fontSize: 13.5,

                    ),

                    prefixIcon: const Icon(

                      Icons.category_outlined,

                      size: 18,

                      color: AppTheme.primaryGreen,

                    ),

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 12,

                      vertical: 10,

                    ),

                    filled: true,

                    fillColor: AppTheme.fieldFill,

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: BorderSide.none,

                    ),

                    enabledBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: AppTheme.border),

                    ),

                    focusedBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(

                        color: AppTheme.primaryGreen,

                        width: 1.4,

                      ),

                    ),

                  ),

                ),

              ),

              const SizedBox(width: 8),

              Expanded(

                child: TextField(

                  controller: _locationCtrl,

                  textInputAction: TextInputAction.search,

                  onSubmitted: (_) => _loadDonations(),

                  decoration: InputDecoration(

                    hintText: 'Location…',

                    hintStyle: TextStyle(

                      color: Colors.grey.shade400,

                      fontSize: 13.5,

                    ),

                    prefixIcon: const Icon(

                      Icons.location_on_outlined,

                      size: 18,

                      color: AppTheme.primaryGreen,

                    ),

                    contentPadding: const EdgeInsets.symmetric(

                      horizontal: 12,

                      vertical: 10,

                    ),

                    filled: true,

                    fillColor: AppTheme.fieldFill,

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: BorderSide.none,

                    ),

                    enabledBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: AppTheme.border),

                    ),

                    focusedBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(

                        color: AppTheme.primaryGreen,

                        width: 1.4,

                      ),

                    ),

                  ),

                ),

              ),

              const SizedBox(width: 8),

              Material(

                color: AppTheme.primaryGreen,

                borderRadius: BorderRadius.circular(12),

                child: InkWell(

                  borderRadius: BorderRadius.circular(12),

                  onTap: _loadDonations,

                  child: const Padding(

                    padding: EdgeInsets.all(12),

                    child: Icon(Icons.search, color: Colors.white, size: 20),

                  ),

                ),

              ),

            ],

          ),

        ),

        const Divider(height: 1, color: AppTheme.border),

        // ── List ──

        Expanded(

          child: _isLoading

              ? const Center(

                  child: CircularProgressIndicator(

                    color: AppTheme.primaryGreen,

                  ),

                )

              : _error != null

                  ? RecipientErrorState(message: _error!, onRetry: _loadDonations)

                  : _donations.isEmpty

                      ? RecipientEmptyState(

                          icon: Icons.no_food_outlined,

                          message: 'No donations available.\nCheck back later!',

                          onRetry: _loadDonations,

                        )

                      : RefreshIndicator(

                          color: AppTheme.primaryGreen,

                          onRefresh: _loadDonations,

                          child: GridView.builder(

                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

                            gridDelegate:

                                const SliverGridDelegateWithFixedCrossAxisCount(

                              crossAxisCount: 2,

                              crossAxisSpacing: 12,

                              mainAxisSpacing: 12,

                              childAspectRatio: 0.66,

                            ),

                            itemCount: _donations.length,

                            itemBuilder: (context, index) => DonationCard(

                              donation: _donations[index],

                              token: token,

                              onClaimed: _loadDonations,

                            ),

                          ),

                        ),

        ),

      ],

    );

  }

}

// ---------------------------------------------------------------------------

// DONATION CARD

// ---------------------------------------------------------------------------
