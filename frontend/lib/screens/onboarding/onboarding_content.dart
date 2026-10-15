import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One short feature tag on an onboarding slide, e.g. "Post food".
class OnboardingFeature {
  final IconData icon;
  final String text;

  const OnboardingFeature(this.icon, this.text);
}

/// Content for one onboarding slide. Each slide introduces one FoodLink
/// role. The features listed here are ones the app actually provides.
class OnboardingSlide {
  /// Matches the role names used at sign-up.
  final String roleName;
  final String headline;

  /// One short line under the headline.
  final String description;

  /// Illustration shown at the top of the slide. If the file is missing,
  /// an icon illustration built from [icon] and [decorations] is shown.
  final String imageAsset;

  final IconData icon;

  /// Small icons placed around [icon] in the fallback illustration.
  final List<IconData> decorations;

  /// Role colour, used for the background, chips and page dots.
  final Color accent;
  final Color accentLight;

  final List<OnboardingFeature> features;

  const OnboardingSlide({
    required this.roleName,
    required this.headline,
    required this.description,
    required this.imageAsset,
    required this.icon,
    required this.decorations,
    required this.accent,
    required this.accentLight,
    required this.features,
  });
}

const String kOnboardingTagline =
    'Share Food. Reduce Waste. Feed Communities.';

const List<OnboardingSlide> kOnboardingSlides = [
  OnboardingSlide(
    roleName: 'Food Donor',
    headline: 'Share More. Waste Less.',
    description: 'Offer your extra food to people nearby.',
    imageAsset: 'assets/onboarding/donor.png',
    icon: Icons.volunteer_activism_rounded,
    decorations: [
      Icons.bakery_dining_outlined,
      Icons.eco_outlined,
      Icons.rice_bowl_outlined,
    ],
    accent: AppTheme.primaryGreenDark,
    accentLight: AppTheme.lightGreen,
    features: [
      OnboardingFeature(Icons.add_a_photo_outlined, 'Post food'),
      OnboardingFeature(Icons.schedule_outlined, 'Set pickup'),
      OnboardingFeature(Icons.fact_check_outlined, 'Track status'),
    ],
  ),
  OnboardingSlide(
    roleName: 'Recipient',
    headline: 'Find Food. Get Support.',
    description: 'Browse and request food shared near you.',
    imageAsset: 'assets/onboarding/recipient.png',
    icon: Icons.restaurant_rounded,
    decorations: [
      Icons.search_rounded,
      Icons.favorite_border_rounded,
      Icons.lunch_dining_outlined,
    ],
    accent: Color(0xFF0B7F73),
    accentLight: Color(0xFFE0F4F1),
    features: [
      OnboardingFeature(Icons.storefront_outlined, 'Browse food'),
      OnboardingFeature(Icons.playlist_add_outlined, 'Request'),
      OnboardingFeature(Icons.track_changes_outlined, 'Track requests'),
    ],
  ),
  OnboardingSlide(
    roleName: 'Volunteer',
    headline: 'Deliver Kindness.',
    description: 'Pick up food and bring it to those in need.',
    imageAsset: 'assets/onboarding/volunteer.png',
    icon: Icons.delivery_dining_rounded,
    decorations: [
      Icons.route_outlined,
      Icons.location_on_outlined,
      Icons.inventory_2_outlined,
    ],
    accent: Color(0xFF1F63C6),
    accentLight: Color(0xFFE3EEFC),
    features: [
      OnboardingFeature(Icons.assignment_turned_in_outlined, 'Accept tasks'),
      OnboardingFeature(Icons.map_outlined, 'Follow route'),
      OnboardingFeature(Icons.local_shipping_outlined, 'Update status'),
    ],
  ),
  OnboardingSlide(
    roleName: 'NGO',
    headline: 'Coordinate Food. Support Communities.',
    description: 'Review, match and track food sharing.',
    imageAsset: 'assets/onboarding/ngo.png',
    icon: Icons.diversity_3_rounded,
    decorations: [
      Icons.verified_outlined,
      Icons.insights_outlined,
      Icons.handshake_outlined,
    ],
    accent: Color(0xFF6B4BC8),
    accentLight: Color(0xFFEEE9FB),
    features: [
      OnboardingFeature(Icons.rule_rounded, 'Approve'),
      OnboardingFeature(Icons.join_inner_rounded, 'Match'),
      OnboardingFeature(Icons.bar_chart_rounded, 'Impact reports'),
    ],
  ),
];
