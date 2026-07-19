import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';

class BrokerListPage extends StatefulWidget {
  const BrokerListPage({Key? key}) : super(key: key);

  @override
  State<BrokerListPage> createState() => _BrokerListPageState();
}

class _BrokerListPageState extends State<BrokerListPage> {
  late TextEditingController _searchController;
  List<BrokerProfile> _filteredBrokers = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadBrokers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBrokers() {
    setState(() {
      _filteredBrokers = LocalDb.activeBrokerProfiles();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredBrokers = LocalDb.searchBrokerProfiles(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ပွဲစားများအချက်အလက်'),
        backgroundColor: AppTheme.primaryAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'အမည် သို့မဟုတ် ဖုန်းနံပါတ်ဖြင့် ရှာရန်',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Broker List
          Expanded(
            child: _filteredBrokers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredBrokers.length,
                    itemBuilder: (context, index) {
                      final broker = _filteredBrokers[index];
                      return _buildBrokerCard(broker);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/brokers/add');
          if (result == true) {
            _loadBrokers();
          }
        },
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ပွဲစားအချက်အလက် မရှိသေးပါ။',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ ခလုတ်ကိုနှိပ်၍ ပွဲစားအသစ် ထည့်သွင်းနိုင်ပါသည်။',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerCard(BrokerProfile broker) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: broker.profileImagePath != null && broker.profileImagePath!.isNotEmpty
            ? CircleAvatar(
                backgroundImage: FileImage(
                  File(broker.profileImagePath!),
                ),
              )
            : CircleAvatar(
                backgroundColor: AppTheme.primaryAccent,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
        title: Text(broker.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(broker.phone),
            if (broker.address != null && broker.address!.isNotEmpty)
              Text(
                broker.address!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onTap: () {
          context.push('/brokers/${broker.id}');
        },
      ),
    );
  }
}
