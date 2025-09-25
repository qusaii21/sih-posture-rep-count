import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final double basePadding = isTablet ? 30 : 20;
    final double titleSize = isTablet ? 30 : 24;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E8), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                toolbarHeight: isTablet ? 90 : 75, // Increased app bar height
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  padding: EdgeInsets.all(basePadding),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up,
                          color: Colors.green, size: isTablet ? 40 : 30),
                      SizedBox(width: 15),
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildOverallProgress(context)),
              SliverToBoxAdapter(child: _buildWeeklyChart(context)),
              SliverToBoxAdapter(child: _buildAchievements(context)),
              SliverToBoxAdapter(child: _buildRecentTests(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      margin: EdgeInsets.all(isTablet ? 30 : 20),
      padding: EdgeInsets.all(isTablet ? 30 : 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            'Overall Fitness Score',
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 30 : 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: isTablet ? 150 : 120,
                height: isTablet ? 150 : 120,
                child: CircularProgressIndicator(
                  value: 0.78,
                  strokeWidth: isTablet ? 12 : 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              Column(
                children: [
                  Text(
                    '78%',
                    style: TextStyle(
                      fontSize: isTablet ? 34 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text('Excellent', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          SizedBox(height: isTablet ? 30 : 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat('Tests', '12', Colors.blue, isTablet),
              _buildProgressStat('Improvement', '+15%', Colors.green, isTablet),
              _buildProgressStat('Streak', '7 days', Colors.orange, isTablet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(
      String label, String value, Color color, bool isTablet) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 30 : 20),
      padding: EdgeInsets.all(isTablet ? 30 : 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Performance',
            style: TextStyle(
                fontSize: isTablet ? 22 : 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isTablet ? 30 : 20),
          Container(
            height: isTablet ? 200 : 150,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child:
                  Text('Chart Placeholder', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      margin: EdgeInsets.all(isTablet ? 30 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Row(
            children: [
              Expanded(child: _buildAchievementBadge('First Test', Icons.star, Colors.yellow, true, isTablet)),
              Expanded(child: _buildAchievementBadge('Perfect Form', Icons.check_circle, Colors.green, true, isTablet)),
              Expanded(child: _buildAchievementBadge('Week Streak', Icons.local_fire_department, Colors.red, false, isTablet)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(
      String title, IconData icon, Color color, bool unlocked, bool isTablet) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: EdgeInsets.all(isTablet ? 20 : 15),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isTablet ? 40 : 30,
            color: unlocked ? color : Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: unlocked ? Colors.black : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTests(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 30 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Tests',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 15),
          _buildTestItem('Push-Ups', '85%', 'Yesterday', Colors.red, isTablet),
          _buildTestItem('Squats', '92%', '2 days ago', Colors.green, isTablet),
          _buildTestItem('Sit-Ups', '78%', '3 days ago', Colors.orange, isTablet),
        ],
      ),
    );
  }

  Widget _buildTestItem(
      String exercise, String score, String date, Color color, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isTablet ? 20 : 15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: isTablet ? 50 : 40,
            height: isTablet ? 50 : 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fitness_center, color: color, size: isTablet ? 28 : 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 18 : 16)),
                Text(date, style: TextStyle(color: Colors.grey, fontSize: isTablet ? 14 : 12)),
              ],
            ),
          ),
          Text(
            score,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
