import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// Selection Status Screen (responsive + slightly taller AppBar)
class SelectionStatusScreen extends StatelessWidget {
  const SelectionStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final basePadding = isTablet ? 30.0 : 20.0;
    final titleSize = isTablet ? 28.0 : 24.0;
    final appBarHeight = isTablet ? 100.0 : 82.0; // increased height

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                toolbarHeight: appBarHeight,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  padding: EdgeInsets.all(basePadding),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.orange, size: isTablet ? 40 : 30),
                      SizedBox(width: isTablet ? 18 : 15),
                      Text(
                        'Selection Status',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: _buildStatusCard(context)),
              SliverToBoxAdapter(child: _buildRequirements(context)),
              SliverToBoxAdapter(child: _buildUpcomingTests(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final margin = isTablet ? 30.0 : 20.0;
    final padding = isTablet ? 28.0 : 20.0;
    final iconSize = isTablet ? 72.0 : 60.0;
    final titleSize = isTablet ? 26.0 : 24.0;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.pending_actions, color: Colors.white, size: iconSize),
          SizedBox(height: isTablet ? 18 : 15),
          Text(
            'Under Review',
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 5),
          Text(
            'Your assessment is being evaluated by SAI officials',
            style: TextStyle(color: Colors.white70, fontSize: isTablet ? 16 : 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20, vertical: isTablet ? 14 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Expected Result: 7-14 days',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isTablet ? 16 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirements(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final margin = isTablet ? 30.0 : 20.0;
    final padding = isTablet ? 24.0 : 20.0;
    final titleSize = isTablet ? 20.0 : 18.0;
    final textSize = isTablet ? 16.0 : 14.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selection Criteria',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isTablet ? 18 : 15),
          _buildRequirementItem('Minimum 4 exercises completed', true, Icons.check_circle, textSize),
          _buildRequirementItem('Average score above 70%', true, Icons.check_circle, textSize),
          _buildRequirementItem('Age between 14-25 years', true, Icons.check_circle, textSize),
          _buildRequirementItem('Valid Aadhar verification', true, Icons.check_circle, textSize),
          _buildRequirementItem('Photo verification completed', true, Icons.check_circle, textSize),
          _buildRequirementItem('Medical clearance pending', false, Icons.pending, textSize),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool completed, IconData icon, double textSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: completed ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: textSize,
                color: completed ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTests(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final margin = isTablet ? 30.0 : 20.0;
    final spacing = isTablet ? 18.0 : 15.0;
    final titleSize = isTablet ? 22.0 : 20.0;

    return Container(
      margin: EdgeInsets.all(margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Tests',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacing),
          _buildUpcomingTestCard(
            context,
            'Regional Selection Camp',
            'Mumbai, Maharashtra',
            'March 15-17, 2024',
            'Conditional selection based on current scores',
            isTablet,
          ),
          SizedBox(height: isTablet ? 12 : 10),
          _buildUpcomingTestCard(
            context,
            'National Talent Hunt',
            'New Delhi',
            'April 20-25, 2024',
            'Top 100 candidates from regional camps',
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTestCard(BuildContext context, String title, String location, String date, String description, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.event, color: Colors.orange, size: isTablet ? 26 : 20),
              ),
              SizedBox(width: isTablet ? 14 : 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Row(
            children: [
              Icon(Icons.location_on, size: isTablet ? 18 : 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(location, style: TextStyle(color: Colors.grey, fontSize: isTablet ? 14 : 12)),
            ],
          ),
          SizedBox(height: isTablet ? 6 : 5),
          Row(
            children: [
              Icon(Icons.calendar_today, size: isTablet ? 18 : 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(date, style: TextStyle(color: Colors.grey, fontSize: isTablet ? 14 : 12)),
            ],
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            description,
            style: TextStyle(fontSize: isTablet ? 14 : 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
