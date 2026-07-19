import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';
import 'package:gemstone_management/features/broker_profile/presentation/pages/add_broker_page.dart';

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

  Future<void> _editBroker(BrokerProfile broker) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBrokerPage(existingBroker: broker),
      ),
    );
    if (result == true) {
      _loadBrokers();
    }
  }

  Future<void> _deleteBroker(BrokerProfile broker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ပွဲစားဖျက်ရန်'),
        content: Text(
          '"${broker.name}" ကို ဖျက်မည်မှာ သေချာပါသလား?\n\nဖျက်ပြီးနောက် ပြန်မရနိုင်ပါ။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('မဖျက်ပါ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDb.softDeleteBrokerProfile(broker.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${broker.name}" ကို ဖျက်ပြီးပါပြီ။'),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadBrokers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ပွဲစားများအချက်အလက်'),
        backgroundColor: AppTheme.primaryAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
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
                child: const Icon(
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
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _editBroker(broker);
            } else if (value == 'delete') {
              _deleteBroker(broker);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('ပြုပြင်ရန်'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('ဖျက်ရန်', style: TextStyle(color: Colors.red)),
                ],
              ),
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
