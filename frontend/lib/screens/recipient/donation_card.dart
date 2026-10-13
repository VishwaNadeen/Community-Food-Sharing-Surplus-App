import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import 'donation_detail_screen.dart';
import 'submit_food_request_screen.dart';

class DonationCard extends StatelessWidget {

  final DonationModel donation;

  final String token;

  final VoidCallback onClaimed;

  const DonationCard({

    super.key,

    required this.donation,

    required this.token,

    required this.onClaimed,

  });

  Color _statusColor(String status) {

    switch (status.toUpperCase()) {

      case 'AVAILABLE':

      case 'APPROVED':

        return AppTheme.primaryGreen;

      case 'PENDING':

        return Colors.orange;

      case 'CANCELLED':

      case 'REJECTED':

        return Colors.red;

      case 'COLLECTED':

      case 'COMPLETED':

        return Colors.blue;

      default:

        return AppTheme.greyText;

    }

  }

  Future<void> _openDetails(BuildContext context) async {

    final result = await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (_) => DonationDetailScreen(

          donation: donation,

          token: token,

        ),

      ),

    );

    if (result == true) {

      onClaimed();

    }

  }

  Future<void> _requestFood(BuildContext context) async {

    final result = await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (_) => SubmitFoodRequestScreen(

          donation: donation,

          token: token,

        ),

      ),

    );

    if (result == true) {

      onClaimed();

    }

  }

  @override

  Widget build(BuildContext context) {

    final statusColor = _statusColor(donation.status);

    return Card(

      margin: EdgeInsets.zero,

      color: Colors.white,

      elevation: 2,

      shadowColor: Colors.black.withValues(alpha: 0.12),

      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(18),

        side: BorderSide(

          color: AppTheme.border.withValues(alpha: 0.6),

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Food image with status badge.

          SizedBox(

            height: 105,

            width: double.infinity,

            child: Stack(

              fit: StackFit.expand,

              children: [

                Material(

                  color: AppTheme.lightGreen,

                  child: InkWell(

                    onTap: () => _openDetails(context),

                    child: donation.imageUrl != null &&

                            donation.imageUrl!.isNotEmpty

                        ? Image.network(

                            donation.imageUrl!,

                            fit: BoxFit.cover,

                            width: double.infinity,

                            height: double.infinity,

                            loadingBuilder: (context, child, loadingProgress) {

                              if (loadingProgress == null) {

                                return child;

                              }

                              return const Center(

                                child: CircularProgressIndicator(

                                  color: AppTheme.primaryGreen,

                                  strokeWidth: 2,

                                ),

                              );

                            },

                            errorBuilder: (context, error, stackTrace) {

                              debugPrint(

                                  'Food image failed: ${donation.imageUrl}');

                              debugPrint('Image error: $error');

                              return const Center(

                                child: Icon(

                                  Icons.broken_image_outlined,

                                  size: 44,

                                  color: AppTheme.primaryGreen,

                                ),

                              );

                            },

                          )

                        : const Center(

                            child: Icon(

                              Icons.restaurant,

                              size: 44,

                              color: AppTheme.primaryGreen,

                            ),

                          ),

                  ),

                )

              ],

            ),

          ),

          // Donation information and actions.

          Expanded(

            child: Padding(

              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  InkWell(

                    onTap: () => _openDetails(context),

                    child: SizedBox(

                      width: double.infinity,

                      child: Text(

                        donation.category,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                          color: AppTheme.darkText,

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}',

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(

                      fontSize: 12,

                      color: AppTheme.greyText,

                    ),

                  ),

                  const SizedBox(height: 7),

                  Row(

                    children: [

                      const Icon(

                        Icons.location_on_outlined,

                        size: 15,

                        color: AppTheme.greyText,

                      ),

                      const SizedBox(width: 3),

                      Expanded(

                        child: Text(

                          donation.pickupLocation,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(

                            fontSize: 11.5,

                            color: AppTheme.greyText,

                          ),

                        ),

                      ),

                    ],

                  ),

                  const Spacer(),

                  SizedBox(

                    width: double.infinity,

                    height: 34,

                    child: ElevatedButton(

                      onPressed: () => _requestFood(context),

                      style: ElevatedButton.styleFrom(

                        backgroundColor: AppTheme.primaryGreen,

                        foregroundColor: Colors.white,

                        elevation: 0,

                        padding: const EdgeInsets.symmetric(

                          horizontal: 6,

                        ),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(9),

                        ),

                      ),

                      child: const Text(

                        'Request Food',

                        maxLines: 1,

                        style: TextStyle(

                          fontSize: 11.5,

                          fontWeight: FontWeight.w600,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}

// ---------------------------------------------------------------------------

// MY REQUESTS TAB

// ---------------------------------------------------------------------------
