import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/home/constant.dart';
import 'package:my_app/home/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade300,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Inventory'),
                  Tab(text: 'Account'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _tabController,
                  children: [
                    InventoryTab(items: defaultShopList),
                    const AccountTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(
            AppRoutes.createShopItem,
            extra: (ShopItem item) {
              defaultShopList.add(item);
              setState(() {}); // Trigger rebuild to reflect new item
            },
          );
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }
}

// InventoryTab widget to preserve state
class InventoryTab extends StatefulWidget {
  const InventoryTab({required this.items, super.key});
  final List<ShopItem> items;

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  late List<ShopItem> _filteredItems;
  String _categoryFilter = 'All';
  String _buyerFilter = 'All';

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredItems = widget.items.where((item) {
        final matchesSearch = item.name.toLowerCase().contains(query) || item.note.toLowerCase().contains(query);
        final matchesCategory = _categoryFilter == 'All' || item.category == _categoryFilter;
        final matchesBuyer = _buyerFilter == 'All' ||
            (_buyerFilter == 'Customer Only' &&
                (item.customerPrice != item.defaultPrice || item.customerBatchPrice != item.defaultPrice * item.batchSize)) ||
            (_buyerFilter == 'Seller Only' && (item.sellerPrice != item.defaultPrice || item.sellerBatchPrice != item.defaultPrice * item.batchSize));
        return matchesSearch && matchesCategory && matchesBuyer;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet<ShopItem>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterSheet(
        initialCategoryFilter: _categoryFilter,
        initialBuyerFilter: _buyerFilter,
        onApply: (category, buyer) {
          setState(() {
            _categoryFilter = category;
            _buyerFilter = buyer;
            _filterItems();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: IconButton(
                  onPressed: _showFilterSheet,
                  icon: Icon(Icons.filter_list, color: colorScheme.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredItems.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => ShopItemCard(item: _filteredItems[index]),
          ),
        ),
      ],
    );
  }
}

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return const Center(
      child: Text(
        'Account Page\n(Add your account details here)',
        textAlign: TextAlign.center,
      ),
    );
  }
}
