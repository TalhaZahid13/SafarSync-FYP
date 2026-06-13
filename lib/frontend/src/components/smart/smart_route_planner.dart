import 'package:flutter/material.dart';

class SmartRoutePlanner extends StatelessWidget {
  final VoidCallback onPlanRoute;
  final TextEditingController? fromController;
  final TextEditingController? toController;
  final bool isLoading;

  const SmartRoutePlanner({
    super.key,
    required this.onPlanRoute,
    this.fromController,
    this.toController,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasControllers =
        fromController != null && toController != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A4C),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.navigation,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Route Planner',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Optimized for weather & traffic',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: isLoading ? null : onPlanRoute,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDB913), Color(0xFF1B5A6E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Plan Route',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // From / To card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFFFF7ED)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // From
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: hasControllers
                          ? TextField(
                              controller: fromController,
                              decoration: const InputDecoration(
                                hintText: 'From — city or address',
                                hintStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            )
                          : const Text(
                              'Starting point',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                    ),
                  ],
                ),

                // Divider
                Container(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                // To
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: hasControllers
                          ? TextField(
                              controller: toController,
                              decoration: const InputDecoration(
                                hintText: 'To — city or address',
                                hintStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            )
                          : const Text(
                              'Destination',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // When used as CTA on home screen (no controllers)
          if (!hasControllers) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPlanRoute,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_road, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tap to plan your route',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
