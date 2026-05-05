import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Apnar UI er moto Blue theke Green gradient
            colors: [Color(0xFF3285E1), Color(0xFF4CB050)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Header Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Notification",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance korar jonno
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- Notification List ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    // Trip Booked Notification
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.flight_takeoff, color: Colors.blue, size: 32),
                      ),
                      title: "Trip Booked Successfully",
                      subtitle: "Your trip to Paris has been confirmed! Check your booking details and prepare for departure.",
                      date: "Today",
                      isVerified: true,
                    ),

                    const SizedBox(height: 15),

                    // Budget Alert
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 32),
                      ),
                      title: "Budget Alert",
                      subtitle: "You have spent 75% of your allocated budget. Be mindful of your remaining balance.",
                      date: "Yesterday",
                      isVerified: false,
                    ),

                    const SizedBox(height: 15),

                    // Booking Confirmation
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      ),
                      title: "Hotel Booking Confirmed",
                      subtitle: "Your reservation at The Grand Hotel has been confirmed for Apr 20-25, 2026.",
                      date: "2 days ago",
                      isVerified: true,
                    ),

                    const SizedBox(height: 15),

                    // Tour Package Recommendation
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.tour, color: Colors.purple, size: 32),
                      ),
                      title: "Exclusive Tour Package",
                      subtitle: "Check out our 5-day Japan tour with 40% discount! Limited time offer available only for you.",
                      date: "3 days ago",
                      isVerified: false,
                    ),

                    const SizedBox(height: 15),

                    // Price Drop Alert
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.trending_down, color: Colors.red, size: 32),
                      ),
                      title: "Price Drop Alert",
                      subtitle: "Flight prices to Barcelona dropped by 25%! Book now before prices go up again.",
                      date: "4 days ago",
                      isVerified: true,
                    ),

                    const SizedBox(height: 15),

                    // New Destination Recommendation
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.teal, size: 32),
                      ),
                      title: "New Destination Added",
                      subtitle: "Explore the stunning Swiss Alps! We've added hiking tours and accommodation packages.",
                      date: "5 days ago",
                      isVerified: false,
                    ),

                    const SizedBox(height: 15),

                    // Payment Reminder
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.payment, color: Colors.amber, size: 32),
                      ),
                      title: "Payment Due",
                      subtitle: "Complete payment for your Dubai trip by Apr 18. Balance: \$450 remaining.",
                      date: "5 days ago",
                      isVerified: false,
                    ),

                    const SizedBox(height: 15),

                    // Special Offer Card
                    _buildNotificationCard(
                      iconOrImage: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.local_offer, color: Colors.pink, size: 32),
                      ),
                      title: "Special Weekend Offer",
                      subtitle: "Get 30% off on all luxury resort packages this weekend only! Offer expires soon.",
                      date: "6 days ago",
                      isVerified: true,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable Notification Card Builder ---
  Widget _buildNotificationCard({
    required Widget iconOrImage,
    required String title,
    required String subtitle,
    required String date,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Glassmorphism effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconOrImage,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isVerified)
                          const Icon(Icons.verified, color: Colors.orange, size: 16),
                        if (isVerified) const SizedBox(width: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}