import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../auth/Login_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with TickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic>? stats;
  String? error;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // تدرجات ألوان جذابة وعصرية
  final List<List<Color>> gradients = [
    [const Color(0xFFFF416C), const Color(0xFFFF4B2B)], // تدرج أحمر جميل
    [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)], // تدرج متعدد الألوان
    [const Color(0xFF1A2980), const Color(0xFF26D0CE)], // تدرج أزرق فيروزي
    [const Color(0xFF6A11CB), const Color(0xFF2575FC)], // تدرج بنفسجي
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    fetchStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('https://backend-q811.onrender.com/videos/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          stats = data['stats'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'فشل في تحميل البيانات: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
backgroundColor: Colors.black, // بدلاً من Color(0xFF0F1221)
      appBar: AppBar(
        title: const Text(
          'إحصائيات النظام', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 22,
            letterSpacing: 0.5,
          )
        ),
backgroundColor: Colors.black, // بدلاً من Color(0xFF0F1221)
        centerTitle: true,
        elevation: 0,
leading: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFFF416C)),
      onPressed: () {}, // Add functionality here if needed
    ),
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFirstLaunch', true); // إعادة التعيين إلى true
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      },
    ),
  ],
),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60, 
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF416C)),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'جاري تحميل الإحصائيات...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          error!, 
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              error = null;
                            });
                            fetchStats();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF416C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: FadeTransition(
                      opacity: _animation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(),
                          const SizedBox(height: 30),
                          _buildVideosSection(),
                          const SizedBox(height: 30),
                          _buildCategoriesSection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderSection() {
    final totalVideos = stats?['videos']?['total'] ?? 0;
    final totalViews = stats?['views']?['total'] ?? 0;
    final totalCategories = stats?['categories']?['total'] ?? 0;
    final totalSeries = stats?['series']?['total'] ?? 0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients[0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradients[0][0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'الإحصائيات العامة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: 'الفيديوهات',
                  value: totalVideos.toString(),
                  icon: Icons.video_library_rounded,
                  gradient: [const Color(0xFFFFB347), const Color(0xFFFFCC33)],
                ),
                _buildStatCard(
                  title: 'المشاهدات',
                  value: totalViews.toString(),
                  icon: Icons.visibility_rounded,
                  gradient: [const Color(0xFF0BA360), const Color(0xFF3CBA92)],
                ),
                _buildStatCard(
                  title: 'الأقسام',
                  value: totalCategories.toString(),
                  icon: Icons.category_rounded,
                  gradient: [const Color(0xFF396afc), const Color(0xFF2948ff)],
                ),
                _buildStatCard(
                  title: 'المسلسلات',
                  value: totalSeries.toString(),
                  icon: Icons.movie_rounded,
                  gradient: [const Color(0xFF834d9b), const Color(0xFFd04ed6)],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_upward_rounded,
                  color: gradient[0],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '10%',
                  style: TextStyle(
                    color: gradient[0],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection() {
    final byCategory = stats?['videos']?['byCategory'] as List? ?? [];
    final mostViewed = stats?['videos']?['mostViewed'] as List? ?? [];
    final recentlyAdded = stats?['videos']?['recentlyAdded'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A30),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('إحصائيات الفيديوهات', Icons.play_circle_filled_rounded, gradients[0]),
            const SizedBox(height: 30),
            
            // Category Distribution Chart
            if (byCategory.isNotEmpty) ...[
              const Text(
                'توزيع الفيديوهات حسب القسم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2335), Color(0xFF131629)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: List.generate(byCategory.length, (index) {
                      final item = byCategory[index];
                      final count = item['count'] ?? 0;
                      final categoryName = item['category']?['name'] ?? 'غير معروف';
                      
                      final colors = [
                        const Color(0xFFFF6B6B),
                        const Color(0xFF4ECDC4),
                        const Color(0xFFFFD166),
                        const Color(0xFF118AB2),
                        const Color(0xFF06D6A0),
                        const Color(0xFFEF476F),
                        const Color(0xFF073B4C),
                      ];
                      
                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: count.toDouble(),
                        title: '$count',
                        radius: 120,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: _Badge(
                          categoryName,
                          colors[index % colors.length],
                          count,
                        ),
                        badgePositionPercentageOffset: 1.05,
                      );
                    }),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
            
            // Most Viewed Videos
            if (mostViewed.isNotEmpty) ...[
              const Text(
                'الفيديوهات الأكثر مشاهدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: mostViewed.length,
                  itemBuilder: (context, index) {
                    final video = mostViewed[index];
                    final views = video['views'] ?? 0;
                    
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 15),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F2335), Color(0xFF131629)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradients[index % gradients.length],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // تأثير تموجات عصرية
                                CustomPaint(
                                  size: const Size(200, 120),
                                  painter: WavePainter(
                                    color: Colors.white.withOpacity(0.1),
                                    wavesCount: 3,
                                  ),
                                ),
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$views',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video['title'] ?? 'بدون عنوان',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'القسم: ${video['categoryName'] ?? 'غير مصنف'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: math.min(1.0, views / 1000),
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(gradients[index % gradients.length][0]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
            
            // Recently Added Videos
            if (recentlyAdded.isNotEmpty) ...[
              const Text(
                'الفيديوهات المضافة حديثاً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.0,
                ),
                itemCount: math.min(6, recentlyAdded.length),
                itemBuilder: (context, index) {
                  final video = recentlyAdded[index];
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2335),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradients[index % gradients.length],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(
                              color: Colors.white.withOpacity(0.05),
                              gridSize: 10,
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 50,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.9),
                                  Colors.black.withOpacity(0),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            child: Text(
                              video['title'] ?? 'بدون عنوان',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'جديد',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoriesSection() {
    final mostPopular = stats?['categories']?['mostPopular'] as List? ?? [];
    final recentlyUpdated = stats?['categories']?['recentlyUpdated'] as List? ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A30),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('إحصائيات الأقسام', Icons.category_rounded, gradients[1]),
            const SizedBox(height: 30),
            
            // Most Popular Categories
            if (mostPopular.isNotEmpty) ...[
              const Text(
                'الأقسام الأكثر استخداماً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2335), Color(0xFF131629)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: mostPopular.isNotEmpty 
                        ? (mostPopular.map((e) => e['count'] ?? 0).reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
                        : 10,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.white.withOpacity(0.8),
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (groupIndex >= mostPopular.length) return null;
                          final category = mostPopular[groupIndex];
                          final categoryName = category['category']?['name'] ?? 'غير معروف';
                          final count = category['count'] ?? 0;
                          return BarTooltipItem(
                            '$categoryName: $count',
                            const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= mostPopular.length) return const Text('');
                            final category = mostPopular[value.toInt()];
                            final name = category['category']?['name'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      mostPopular.length,
                      (index) {
                        final category = mostPopular[index];
                        final count = category['count'] ?? 0;
                        
                        final colors = [
                          const Color(0xFFFF6B6B),
                          const Color(0xFF4ECDC4),
                          const Color(0xFFFFD166),
                          const Color(0xFF118AB2),
                          const Color(0xFF06D6A0),
                          const Color(0xFFEF476F),
                        ];
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              gradient: LinearGradient(
                                colors: [
                                  colors[index % colors.length],
                                  colors[index % colors.length].withOpacity(0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 18,
                              borderRadius: BorderRadius.circular(5),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: mostPopular.isNotEmpty 
                                    ? (mostPopular.map((e) => e['count'] ?? 0).reduce((a, b) => a > b ? a : b) * 1.2).toDouble()
                                    : 10,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
            
            // Recently Updated Categories
            if (recentlyUpdated.isNotEmpty) ...[
              const Text(
                'الأقسام المحدثة مؤخراً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F2335), Color(0xFF131629)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(5, recentlyUpdated.length),
                  itemBuilder: (context, index) {
                    final category = recentlyUpdated[index];
                    final colors = [
                      const Color(0xFFFF6B6B),
                      const Color(0xFF4ECDC4),
                      const Color(0xFFFFD166),
                      const Color(0xFF118AB2),
                      const Color(0xFF06D6A0),
                    ];
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: index == recentlyUpdated.length - 1 ? 0 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length].withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors[index % colors.length].withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: colors[index % colors.length],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          category['name'] ?? 'غير معروف',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'آخر تحديث: ${DateTime.now().toString().substring(0, 10)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.update_rounded,
                            color: colors[index % colors.length],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, List<Color> gradient) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ليبل دائري للمخطط الدائري
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final int count;

  const _Badge(this.text, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// مرسام تموجات للخلفية
class WavePainter extends CustomPainter {
  final Color color;
  final int wavesCount;

  WavePainter({required this.color, this.wavesCount = 5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final height = size.height;
    final width = size.width;
    
    for (int i = 0; i < wavesCount; i++) {
      final path = Path();
      final waveHeight = height / 15;
      final offset = i * (height / wavesCount);
      
      path.moveTo(0, offset);
      
      for (int x = 0; x < width; x += 30) {
        path.quadraticBezierTo(
          x + 15, offset + waveHeight, 
          x + 30, offset
        );
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// مرسام الشبكة للخلفية
class GridPainter extends CustomPainter {
  final Color color;
  final double gridSize;

  GridPainter({required this.color, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}